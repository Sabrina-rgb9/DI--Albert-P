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

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.http.*;
import java.nio.file.Files;
import java.time.Duration;
import java.util.Base64;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

public class ChatController {

    @FXML private TextField textInput;
    @FXML private VBox chatBox;
    @FXML private ScrollPane chatScroll;
    @FXML private Button btnTextRequest;
    @FXML private Button btnPickImage;
    @FXML private Button btnSendImage;
    @FXML private Button btnStop;
    @FXML private Label lblImageName;
    @FXML private Label status;
    @FXML private ProgressIndicator progress;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    private CompletableFuture<?> currentRequestFuture;
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);

    private File selectedImage;
    private final String OLLAMA_URL = "http://localhost:11434/api/generate";

    @FXML
    public void initialize() {
        status.setText("Idle");
        btnStop.setDisable(true);
        progress.setVisible(false);
    }

    // ------------------ Envío de texto ------------------
    @FXML
    private void onSendText() {
        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) return;

        appendToChat(prompt, true);
        textInput.clear();

        startTextRequest(prompt);
    }

    private void startTextRequest(String prompt) {
        JSONObject payload = new JSONObject();
        payload.put("model", "gemma3:1b");
        payload.put("prompt", prompt);
        payload.put("stream", false); // texto completo

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(OLLAMA_URL))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        cancelCurrentRequest();
        isCancelled.set(false);
        setUiBusy("Procesando texto...");

        currentRequestFuture = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenApply(HttpResponse::body)
                .thenAccept(body -> {
                    if (!isCancelled.get()) {
                        try {
                            JSONObject obj = new JSONObject(body);
                            String responseText = obj.optString("response", body);
                            appendToChat(responseText, false);
                        } catch (Exception e) {
                            appendToChat("[Error al procesar respuesta de texto]", false);
                        }
                    }
                    cleanupAfterRequest();
                })
                .exceptionally(e -> {
                    if (!isCancelled.get()) {
                        appendToChat("[Error durante la petición de texto]", false);
                    }
                    cleanupAfterRequest();
                    return null;
                });
    }

    // ------------------ Selección de imagen ------------------
    @FXML
    private void onPickImage() {
        FileChooser chooser = new FileChooser();
        chooser.setTitle("Elegir imagen");
        chooser.getExtensionFilters().add(
                new FileChooser.ExtensionFilter("Imágenes", "*.png","*.jpg","*.jpeg","*.bmp","*.gif")
        );
        File file = chooser.showOpenDialog(chatScroll.getScene().getWindow());
        if (file != null) {
            selectedImage = file;
            lblImageName.setText(file.getName());
        }
    }

    @FXML
    private void onSendImage() {
        if (selectedImage == null) {
            appendToChat("[No hay imagen seleccionada]", false);
            return;
        }

        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) prompt = "Describe esta imagen";

        appendToChat(prompt + " (imagen: " + selectedImage.getName() + ")", true);
        textInput.clear();

        startImageRequest(selectedImage, prompt);
    }

    private void startImageRequest(File imageFile, String prompt) {
        try {
            byte[] bytes = Files.readAllBytes(imageFile.toPath());
            String base64 = Base64.getEncoder().encodeToString(bytes);
            String mime = Files.probeContentType(imageFile.toPath());
            if (mime == null) mime = "image/png";
            String dataUri = "data:" + mime + ";base64," + base64;

            JSONObject payload = new JSONObject();
            payload.put("model", "gemma3:1b");
            payload.put("stream", false); // respuesta completa
            payload.put("prompt", prompt + "\n\n[IMAGE]\n" + dataUri);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(OLLAMA_URL))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                    .build();

            cancelCurrentRequest();
            isCancelled.set(false);
            setUiBusy("Procesando imagen...");

            currentRequestFuture = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(HttpResponse::body)
                    .thenAccept(body -> {
                        if (!isCancelled.get()) {
                            try {
                                JSONObject obj = new JSONObject(body);
                                String responseText = obj.optString("response", body);
                                appendToChat(responseText, false);
                            } catch (Exception e) {
                                appendToChat("[Error al procesar respuesta de imagen]", false);
                            }
                        }
                        cleanupAfterRequest();
                    })
                    .exceptionally(e -> {
                        if (!isCancelled.get()) {
                            appendToChat("[Error durante petición de imagen]", false);
                        }
                        cleanupAfterRequest();
                        return null;
                    });

        } catch (IOException e) {
            appendToChat("[No se pudo leer la imagen]", false);
        }
    }

    // ------------------ Cancelación ------------------
    @FXML
    private void onStop() {
        cancelCurrentRequest();
        appendToChat("[Usuario canceló la petición]", false);
    }

    private void cancelCurrentRequest() {
        isCancelled.set(true);
        if (currentRequestFuture != null && !currentRequestFuture.isDone()) {
            currentRequestFuture.cancel(true);
        }
        cleanupAfterRequest();
    }

    // ------------------ UI Helpers ------------------
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

    // ------------------ Chat Bubbles ------------------
    private void appendToChat(String text, boolean isUser) {
        Platform.runLater(() -> {
            Label label = new Label(text);
            label.setWrapText(true);
            label.setPadding(new Insets(5,10,5,10));

            if(isUser) {
                label.setStyle("-fx-background-color: #DCF8C6; -fx-background-radius: 10; -fx-text-fill: black;");
            } else {
                label.setStyle("-fx-background-color: #FFFFFF; -fx-background-radius: 10; -fx-text-fill: black;");
            }

            HBox hbox = new HBox();
            if(isUser) {
                hbox.setAlignment(Pos.CENTER_RIGHT);
                hbox.getChildren().add(label);
            } else {
                hbox.setAlignment(Pos.CENTER_LEFT);
                hbox.getChildren().add(label);
            }

            chatBox.getChildren().add(hbox);

            // Auto-scroll
            chatScroll.layout();
            chatScroll.setVvalue(1.0);
        });
    }
}
