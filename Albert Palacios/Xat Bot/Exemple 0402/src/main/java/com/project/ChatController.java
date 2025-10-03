package com.project;

import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.stage.FileChooser;
import org.json.JSONObject;

import java.io.*;
import java.net.URI;
import java.net.http.*;
import java.nio.file.Files;
import java.time.Duration;
import java.util.Base64;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

public class ChatController {

    @FXML private TextField textInput;
    @FXML private TextArea textArea;
    @FXML private Button btnTextRequest;
    @FXML private Button btnPickImage;
    @FXML private Button btnSendImage;
    @FXML private Button btnStop;
    @FXML private Label status;
    @FXML private Label lblImageName;
    @FXML private ChoiceBox<String> choiceImageQuestion;
    @FXML private ProgressIndicator progress;

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    private CompletableFuture<?> currentRequestFuture;
    private InputStream currentInputStream;
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    private File selectedImage;

    private final String OLLAMA_URL = "http://localhost:11434/api/generate";

    @FXML
    public void initialize() {
        status.setText("Idle");
        btnStop.setDisable(true);
        progress.setVisible(false);
    }

    @FXML
    private void onSendText() {
        String prompt = textInput.getText();
        if (prompt == null || prompt.isBlank()) return;

        appendToChat("> " + prompt + "\n");
        textInput.clear();

        startStreamingTextRequest(prompt);
    }

    private void startStreamingTextRequest(String prompt) {
        JSONObject payload = new JSONObject();
        payload.put("model", "gemma3:1b");
        payload.put("prompt", prompt);
        payload.put("stream", true);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(OLLAMA_URL))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                .build();

        cancelCurrentRequest();

        isCancelled.set(false);
        setUiBusy("Streaming...");

        currentRequestFuture = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
                .thenAcceptAsync(response -> {
                    currentInputStream = response.body();
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(currentInputStream))) {
                        String line;
                        while ((line = reader.readLine()) != null && !isCancelled.get()) {
                            line = line.trim();
                            if (line.isEmpty()) continue;
                            try {
                                JSONObject obj = new JSONObject(line);
                                String responseText = obj.optString("response", "");
                                if (!responseText.isEmpty()) {
                                    Platform.runLater(() -> appendToChat(responseText));
                                }
                            } catch (Exception e) {
                                Platform.runLater(() -> appendToChat(line));
                            }
                        }
                    } catch (IOException e) {
                        if (!isCancelled.get()) e.printStackTrace();
                    } finally {
                        cleanupAfterRequest();
                    }
                }, executor)
                .exceptionally(e -> {
                    if (!isCancelled.get()) {
                        e.printStackTrace();
                        Platform.runLater(() -> appendToChat("\n[Error during streaming]\n"));
                    }
                    cleanupAfterRequest();
                    return null;
                });
    }

    @FXML
    private void onPickImage() {
        FileChooser chooser = new FileChooser();
        chooser.setTitle("Choose an image");
        chooser.getExtensionFilters().add(
                new FileChooser.ExtensionFilter("Images", "*.png","*.jpg","*.jpeg","*.bmp","*.gif")
        );
        File file = chooser.showOpenDialog(textArea.getScene().getWindow());
        if (file != null) {
            selectedImage = file;
            lblImageName.setText(file.getName());
        }
    }

    @FXML
    private void onSendImage() {
        if (selectedImage == null) {
            appendToChat("[No image selected]\n");
            return;
        }
        String question = choiceImageQuestion.getValue();
        if (question == null || question.isBlank()) question = "Describe this image";

        appendToChat("> " + question + " (image: " + selectedImage.getName() + ")\n");
        startImageRequest(selectedImage, question);
    }

    private void startImageRequest(File imageFile, String question) {
        try {
            byte[] bytes = Files.readAllBytes(imageFile.toPath());
            String base64 = Base64.getEncoder().encodeToString(bytes);
            String mime = Files.probeContentType(imageFile.toPath());
            if (mime == null) mime = "image/png";
            String dataUri = "data:" + mime + ";base64," + base64;

            JSONObject payload = new JSONObject();
            payload.put("model", "gemma3:1b");
            payload.put("stream", false);
            payload.put("prompt", question + "\n\n[IMAGE]\n" + dataUri);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(OLLAMA_URL))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                    .build();

            cancelCurrentRequest();
            isCancelled.set(false);
            setUiBusy("Thinking (image)...");

            currentRequestFuture = httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(HttpResponse::body)
                    .thenAccept(body -> {
                        if (!isCancelled.get()) {
                            try {
                                JSONObject obj = new JSONObject(body);
                                String responseText = obj.optString("response", body);
                                Platform.runLater(() -> appendToChat("\n" + responseText + "\n"));
                            } catch (Exception e) {
                                Platform.runLater(() -> appendToChat("\n[Error parsing image response]\n"));
                            }
                        }
                        cleanupAfterRequest();
                    })
                    .exceptionally(e -> {
                        if (!isCancelled.get()) {
                            Platform.runLater(() -> appendToChat("\n[Error during image request]\n"));
                        }
                        cleanupAfterRequest();
                        return null;
                    });

        } catch (IOException e) {
            appendToChat("[Failed to read image]\n");
        }
    }

    @FXML
    private void onStop() {
        cancelCurrentRequest();
        appendToChat("\n[User cancelled]\n");
    }

    private void cancelCurrentRequest() {
        isCancelled.set(true);
        if (currentRequestFuture != null && !currentRequestFuture.isDone()) {
            currentRequestFuture.cancel(true);
        }
        if (currentInputStream != null) {
            try { currentInputStream.close(); } catch (IOException ignored) {}
            currentInputStream = null;
        }
        cleanupAfterRequest();
    }

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

    private void appendToChat(String text) {
        textArea.appendText(text);
    }
}
