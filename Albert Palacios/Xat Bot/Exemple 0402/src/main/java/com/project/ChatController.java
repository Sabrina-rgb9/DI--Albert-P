package com.project;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.stage.FileChooser;
import org.json.JSONObject;
import org.json.JSONArray;

import java.io.*;
import java.net.URI;
import java.net.http.*;
import java.nio.file.Files;
import java.time.Duration;
import java.util.Base64;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Controlador principal de la aplicación de chat.
 * Gestiona la interacción del usuario, las peticiones a Ollama (texto e imagen),
 * y actualiza la interfaz de forma segura usando Platform.runLater().
 * 
 * Cumple con los requisitos del enunciado:
 * - Texto: streaming en tiempo real con gemma3:1b
 * - Imagen: respuesta completa con llava-phi3 (muestra "Thinking...")
 * - Cancelación en cualquier momento
 * - No bloquea el hilo de JavaFX
 */
public class ChatController {

    // --- Referencias a elementos de la interfaz (inyectadas por FXML) ---
    @FXML private TextField textInput;
    @FXML private VBox chatBox;          // Contenedor de mensajes
    @FXML private ScrollPane chatScroll; // Permite desplazarse si hay muchos mensajes
    @FXML private Button btnTextRequest;
    @FXML private Button btnPickImage;
    @FXML private Button btnSendImage;
    @FXML private Button btnStop;
    @FXML private Label lblImageName;    // Muestra nombre de imagen seleccionada
    @FXML private Label status;          // Estado actual (Idle, Thinking..., etc.)
    @FXML private ProgressIndicator progress; // Indicador de carga

    // --- Cliente HTTP para comunicarse con Ollama (localhost:11434) ---
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10)) // Tiempo máximo para conectar
            .build();

    // --- Gestión de concurrencia y cancelación ---
    private CompletableFuture<?> currentRequest; // Guarda la petición en curso (para posible cancelación lógica)
    private final AtomicBoolean isCancelled = new AtomicBoolean(false); // Bandera segura para hilos: indica si el usuario canceló

    // --- Estado de la aplicación ---
    private File selectedImage; // Imagen seleccionada por el usuario
    private final String OLLAMA_URL = "http://localhost:11434/api/generate"; // Endpoint de Ollama para generar respuestas

    // --- Executor para tareas de streaming (evita bloquear el hilo de JavaFX) ---
    // Usa un único hilo dedicado para leer el stream de Ollama
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();

    /**
     * Método llamado automáticamente al cargar la interfaz (después de @FXML).
     * Inicializa el estado inicial de la UI.
     */
    @FXML
    public void initialize() {
        status.setText("Idle");
        btnStop.setDisable(true);   // No se puede cancelar si no hay petición activa
        progress.setVisible(false); // Ocultamos el indicador de progreso
    }

    // ================== ENVÍO DE TEXTO (CON STREAMING) ==================

    /**
     * Maneja el evento de enviar un mensaje de texto.
     * Valida la entrada, muestra el mensaje del usuario y lanza la petición al modelo de texto.
     */
    @FXML
    private void onSendText() {
        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) return; // Evita enviar mensajes vacíos

        appendToChat(prompt, true); // true = mensaje del usuario (derecha)
        textInput.clear();          // Limpia el campo de entrada

        startTextStreamRequest(prompt); // Inicia la petición con streaming
    }

    /**
     * Envía una petición de texto a Ollama usando el modelo 'gemma3:1b' con streaming activado.
     * 
     * IMPORTANTE: 
     * - Usa streaming (stream: true) para cumplir el requisito de mostrar la respuesta "a medida que se recibe".
     * - La respuesta de Ollama llega como un flujo de JSON por líneas (Server-Sent Events).
     * - Se procesa en un hilo secundario (executorService) para no bloquear JavaFX.
     * - Cada fragmento ("token") se añade inmediatamente a la interfaz.
     */
    private void startTextStreamRequest(String prompt) {
        // Construye el cuerpo de la petición en JSON
        JSONObject payload = new JSONObject();
        payload.put("model", "gemma3:1b");
        payload.put("prompt", prompt);
        payload.put("stream", true); // ¡Clave para activar el streaming!

        // Crea la petición HTTP POST
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(OLLAMA_URL))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        // Reinicia el estado de cancelación y actualiza la UI
        isCancelled.set(false);
        setUiBusy("Generant resposta...");

        // Prepara una burbuja vacía para el bot (se irá llenando con cada token)
        Platform.runLater(() -> {
            Label label = new Label("");
            label.setWrapText(true);
            label.setPadding(new Insets(5,10,5,10));
            label.setStyle("-fx-background-color: #FFFFFF; -fx-background-radius: 10; -fx-text-fill: black;");
            HBox hbox = new HBox(label);
            hbox.setAlignment(Pos.CENTER_LEFT); // Mensajes del bot a la izquierda
            chatBox.getChildren().add(hbox);
        });

        // Envía la petición de forma asíncrona y procesa el stream
        currentRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
                .thenApply(response -> {
                    // Envía la tarea de lectura del stream a un hilo dedicado
                    executorService.submit(() -> {
                        try (BufferedReader reader = new BufferedReader(new InputStreamReader(response.body()))) {
                            String line;
                            // Lee línea por línea mientras no se cancele
                            while ((line = reader.readLine()) != null && !isCancelled.get()) {
                                if (line.trim().isEmpty()) continue; // Salta líneas vacías

                                try {
                                    // Cada línea es un JSON con un fragmento de respuesta
                                    JSONObject chunk = new JSONObject(line);
                                    String token = chunk.optString("response", ""); // Texto parcial
                                    boolean done = chunk.optBoolean("done", false); // Indica fin de respuesta

                                    // ACTUALIZACIÓN DE UI: debe ir en Platform.runLater()
                                    Platform.runLater(() -> {
                                        if (!chatBox.getChildren().isEmpty()) {
                                            // Obtiene la última burbuja (la del bot)
                                            HBox lastHBox = (HBox) chatBox.getChildren().get(chatBox.getChildren().size() - 1);
                                            if (!lastHBox.getChildren().isEmpty()) {
                                                Label lastLabel = (Label) lastHBox.getChildren().get(0);
                                                String currentText = lastLabel.getText();
                                                lastLabel.setText(currentText + token); // Añade el nuevo token
                                            }
                                        }
                                        chatScroll.setVvalue(1.0); // Auto-scroll al final
                                    });

                                    if (done) break; // Termina si Ollama dice que ya no hay más
                                } catch (Exception e) {
                                    // Error al parsear un fragmento
                                    Platform.runLater(() -> appendToChat("[Error en streaming: " + e.getMessage() + "]", false));
                                    break;
                                }
                            }
                        } catch (IOException e) {
                            // Error de red (solo si no fue cancelado por el usuario)
                            if (!isCancelled.get()) {
                                Platform.runLater(() -> appendToChat("[Error de connexió]", false));
                            }
                        } finally {
                            // Siempre restauramos la UI al finalizar (éxito, error o cancelación)
                            cleanupAfterRequest();
                        }
                    });
                    return response;
                })
                .exceptionally(e -> {
                    // Error grave en la petición HTTP (ej: Ollama no responde)
                    if (!isCancelled.get()) {
                        Platform.runLater(() -> appendToChat("[Error en petició de text]", false));
                    }
                    cleanupAfterRequest();
                    return null;
                });
    }

    // ================== GESTIÓN DE IMÁGENES ==================

    /**
     * Abre un selector de archivos para que el usuario elija una imagen.
     * Solo permite formatos de imagen comunes.
     */
    @FXML
    private void onPickImage() {
        FileChooser chooser = new FileChooser();
        chooser.setTitle("Elegir imagen");
        chooser.getExtensionFilters().add(
                new FileChooser.ExtensionFilter("Imágenes", "*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif")
        );
        File file = chooser.showOpenDialog(chatScroll.getScene().getWindow());
        if (file != null) {
            selectedImage = file;
            lblImageName.setText(file.getName()); // Muestra el nombre en la UI
        }
    }

    /**
     * Envía la imagen seleccionada junto con un prompt al modelo multimodal.
     * Si no hay prompt, usa uno por defecto ("Describe this image").
     */
    @FXML
    private void onSendImage() {
        if (selectedImage == null) {
            appendToChat("[No hi ha imatge seleccionada]", false);
            return;
        }

        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) prompt = "Describe this image";

        // Muestra el mensaje del usuario con info de la imagen
        appendToChat(prompt + " (imatge: " + selectedImage.getName() + ")", true);
        textInput.clear();

        startImageCompleteRequest(selectedImage, prompt);
    }

    /**
     * Envía una petición con imagen a Ollama usando el modelo 'llava-phi3'.
     * 
     * IMPORTANTE:
     * - NO usa streaming (stream: false), como exige el enunciado.
     * - La imagen se convierte a Base64 PURO (sin prefijo "data:image/...").
     * - Se envía dentro del campo "images" como un array JSON.
     * - Muestra "Thinking..." mientras espera.
     */
    private void startImageCompleteRequest(File imageFile, String prompt) {
        try {
            // Lee la imagen y la convierte a Base64
            byte[] bytes = Files.readAllBytes(imageFile.toPath());
            String base64 = Base64.getEncoder().encodeToString(bytes);

            // Construye el payload para Ollama
            JSONObject payload = new JSONObject();
            payload.put("model", "llava-phi3:latest");
            payload.put("prompt", prompt);
            payload.put("stream", false); // Respuesta completa, no streaming

            // Añade la imagen en el campo "images"
            JSONArray imagesArray = new JSONArray();
            imagesArray.put(base64);
            payload.put("images", imagesArray);

            // Crea y envía la petición
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(OLLAMA_URL))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                    .build();

            isCancelled.set(false);
            setUiBusy("Thinking..."); // Mensaje requerido por el enunciado

            currentRequest = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(HttpResponse::body)
                    .thenAccept(body -> {
                        if (!isCancelled.get()) {
                            try {
                                JSONObject obj = new JSONObject(body);
                                // Verifica si hay un error en la respuesta
                                if (obj.has("error")) {
                                    String errorMsg = obj.getString("error");
                                    appendToChat("[Error del modelo: " + errorMsg + "]", false);
                                } else {
                                    String responseText = obj.optString("response", "");
                                    appendToChat(responseText, false);
                                }
                            } catch (Exception e) {
                                appendToChat("[Error al processar resposta d'imatge: " + e.getMessage() + "]", false);
                            }
                        }
                        cleanupAfterRequest();
                    })
                    .exceptionally(e -> {
                        if (!isCancelled.get()) {
                            appendToChat("[Error durant petició d'imatge: " + e.getMessage() + "]", false);
                        }
                        cleanupAfterRequest();
                        return null;
                    });

        } catch (IOException e) {
            appendToChat("[No s'ha pogut llegir la imatge: " + e.getMessage() + "]", false);
            cleanupAfterRequest();
        }
    }

    // ================== CANCELACIÓN ==================

    /**
     * Cancela la petición actual.
     * Solo establece la bandera 'isCancelled'; el código de streaming/petición
     * la comprueba periódicamente y se detiene.
     * 
     * NOTA: No se cancela el CompletableFuture porque el HttpClient de Java
     * no permite cancelar fácilmente una conexión en curso. La bandera es suficiente.
     */
    @FXML
    private void onStop() {
        isCancelled.set(true);
        appendToChat("[Petició cancel·lada per l'usuari]", false);
        cleanupAfterRequest();
    }

    // ================== GESTIÓN DE LA INTERFAZ ==================

    /**
     * Desactiva botones y muestra estado de "ocupado" durante una petición.
     * ¡Debe ejecutarse en el hilo de JavaFX! (por eso usa Platform.runLater)
     */
    private void setUiBusy(String msg) {
        Platform.runLater(() -> {
            btnStop.setDisable(false);
            btnTextRequest.setDisable(true);
            btnPickImage.setDisable(true);
            btnSendImage.setDisable(true);
            progress.setVisible(true);
            status.setText(msg);
        });
    }

    /**
     * Restaura la interfaz al estado normal tras finalizar una petición.
     */
    private void cleanupAfterRequest() {
        Platform.runLater(() -> {
            btnStop.setDisable(true);
            btnTextRequest.setDisable(false);
            btnPickImage.setDisable(false);
            btnSendImage.setDisable(false);
            status.setText("Idle");
            progress.setVisible(false);
        });
    }

    /**
     * Añade un mensaje al chat con estilo (usuario vs bot).
     * 
     * REGLA DE ORO DE JAVAFX:
     * Cualquier modificación de la UI debe hacerse en el JavaFX Application Thread.
     * Por eso TODO va dentro de Platform.runLater().
     */
    private void appendToChat(String text, boolean isUser) {
        Platform.runLater(() -> {
            Label label = new Label(text);
            label.setWrapText(true);
            label.setPadding(new Insets(5,10,5,10));

            if (isUser) {
                label.setStyle("-fx-background-color: #DCF8C6; -fx-background-radius: 10; -fx-text-fill: black;");
            } else {
                label.setStyle("-fx-background-color: #FFFFFF; -fx-background-radius: 10; -fx-text-fill: black;");
            }

            HBox hbox = new HBox();
            if (isUser) {
                hbox.setAlignment(Pos.CENTER_RIGHT);
                hbox.getChildren().add(label);
            } else {
                hbox.setAlignment(Pos.CENTER_LEFT);
                hbox.getChildren().add(label);
            }

            chatBox.getChildren().add(hbox);
            chatScroll.setVvalue(1.0); // Desplaza al final automáticamente
        });
    }

    // ================== LIMPIEZA AL CERRAR ==================

    /**
     * Cierra el ExecutorService al terminar la aplicación.
     * Evita fugas de hilos.
     * 
     * NOTA: Deberías llamar a este método desde el Main cuando se cierre la ventana.
     */
    public void shutdown() {
        executorService.shutdownNow();
    }
}