package com.project;

import com.project.model.ChatMessage;
import com.project.service.OllamaClient;
import com.project.service.OllamaHttpClient;
import com.project.ui.ChatCell;
import javafx.application.Platform;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.geometry.Insets;
import javafx.scene.control.*;
import javafx.stage.FileChooser;

import java.io.File;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Controlador principal de la aplicación de chat (refactorizado).
 * Ahora delega la comunicación con Ollama a un servicio externo y usa ListView
 * con celdas personalizadas para mostrar mensajes.
 */
public class ChatController {

    // --- Referencias a elementos de la interfaz (inyectadas por FXML) ---
    @FXML private TextField textInput;
    @FXML private ListView<ChatMessage> chatList; // Ahora usamos ListView
    @FXML private Button btnTextRequest;
    @FXML private Button btnPickImage;
    @FXML private Button btnSendImage;
    @FXML private Button btnStop;
    @FXML private Label lblImageName;    // Muestra nombre de imagen seleccionada
    @FXML private Label status;          // Estado actual (Idle, Thinking..., etc.)
    @FXML private ProgressIndicator progress; // Indicador de carga

    // --- Servicio de comunicación con Ollama ---
    private final OllamaClient ollamaClient = new OllamaHttpClient();

    // --- Estado y concurrencia ---
    private final ObservableList<ChatMessage> messages = FXCollections.observableArrayList();
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);
    private CompletableFuture<?> currentRequest;

    private File selectedImage; // Imagen seleccionada por el usuario

    @FXML
    public void initialize() {
        status.setText("Idle");
        btnStop.setDisable(true);
        progress.setVisible(false);

        chatList.setItems(messages);
        chatList.setCellFactory(lv -> new ChatCell());
    }


    // ================== ENVÍO DE TEXTO (CON STREAMING) ==================

    @FXML
    private void onSendText() {
        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) return;

        // Mensaje de usuario
        appendToChat(prompt, true);
        textInput.clear();

        // Prepara la respuesta del bot (vacía, se irá completando)
        ChatMessage botMsg = new ChatMessage("", false);
        messages.add(botMsg);

        isCancelled.set(false);
        setUiBusy("Generant resposta...");

        currentRequest = ollamaClient.streamText(
                prompt,
                token -> Platform.runLater(() -> botMsg.setText(botMsg.getText() + token)),
                () -> Platform.runLater(this::cleanupAfterRequest),
                err -> Platform.runLater(() -> appendToChat("[Error en petició de text]", false)),
                isCancelled
        );
    }

    // ================== GESTIÓN DE IMÁGENES ==================

    @FXML
    private void onPickImage() {
        FileChooser chooser = new FileChooser();
        chooser.setTitle("Elegir imagen");
        chooser.getExtensionFilters().add(
                new FileChooser.ExtensionFilter("Imágenes", "*.png", "*.jpg", "*.jpeg", "*.bmp", "*.gif")
        );
        File file = chooser.showOpenDialog(textInput.getScene().getWindow());
        if (file != null) {
            selectedImage = file;
            lblImageName.setText(file.getName());
        }
    }

    @FXML
    private void onSendImage() {
        if (selectedImage == null) {
            appendToChat("[No hi ha imatge seleccionada]", false);
            return;
        }

        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) prompt = "Describe esta imagen";

        appendToChat(prompt + " (imatge: " + selectedImage.getName() + ")", true);
        textInput.clear();

        isCancelled.set(false);
        setUiBusy("Thinking...");

        currentRequest = ollamaClient.generateImageComplete(selectedImage, prompt, isCancelled)
                .thenAccept(responseText -> Platform.runLater(() -> {
                    appendToChat(responseText, false);
                    cleanupAfterRequest();
                }))
                .exceptionally(e -> {
                    Platform.runLater(() -> appendToChat("[Error durant petició d'imatge: " + e.getMessage() + "]", false));
                    cleanupAfterRequest();
                    return null;
                });
    }

    // ================== CANCELACIÓN ==================

    @FXML
    private void onStop() {
        isCancelled.set(true);
        appendToChat("[Petició cancel·lada per l'usuari]", false);
        cleanupAfterRequest();
    }

    // ================== GESTIÓN DE LA INTERFAZ ==================

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

    private void appendToChat(String text, boolean isUser) {
        Platform.runLater(() -> {
            messages.add(new com.project.model.ChatMessage(text, isUser));
            chatList.scrollTo(messages.size() - 1);
        });
    }

    // ================== LIMPIEZA AL CERRAR ==================

    public void shutdown() {
        ollamaClient.shutdown();
    }
}
