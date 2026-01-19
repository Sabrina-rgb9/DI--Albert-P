package com.project.service;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.time.Duration;
import java.util.Base64;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

/**
 * Implementación simple de OllamaClient usando java.net.http.HttpClient.
 * Se encarga de streaming y de la petición de imagen.
 */
public class OllamaHttpClient implements OllamaClient {
    private static final String OLLAMA_URL = "http://localhost:11434/api/generate";
    private final HttpClient httpClient;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    public OllamaHttpClient() {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    @Override
    public CompletableFuture<Void> streamText(String prompt, Consumer<String> onToken, Runnable onComplete, Consumer<Throwable> onError, AtomicBoolean cancelFlag) {
        try {
            JSONObject payload = new JSONObject();
            payload.put("model", "gemma3:1b");
            payload.put("prompt", prompt);
            payload.put("stream", true);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(OLLAMA_URL))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                    .build();

            return httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofInputStream())
                    .thenCompose(response -> CompletableFuture.runAsync(() -> {
                        try (BufferedReader reader = new BufferedReader(new InputStreamReader(response.body()))) {
                            String line;
                            while ((line = reader.readLine()) != null && !cancelFlag.get()) {
                                if (line.trim().isEmpty()) continue;
                                JSONObject chunk = new JSONObject(line);
                                String token = chunk.optString("response", "");
                                boolean done = chunk.optBoolean("done", false);
                                if (!token.isEmpty()) {
                                    onToken.accept(token);
                                }
                                if (done) break;
                            }
                            onComplete.run();
                        } catch (Exception e) {
                            if (!cancelFlag.get()) onError.accept(e);
                        }
                    }, executor));

        } catch (Exception e) {
            CompletableFuture<Void> failed = new CompletableFuture<>();
            failed.completeExceptionally(e);
            return failed;
        }
    }

    @Override
    public CompletableFuture<String> generateImageComplete(File image, String prompt, AtomicBoolean cancelFlag) {
        try {
            byte[] bytes = Files.readAllBytes(image.toPath());
            String base64 = Base64.getEncoder().encodeToString(bytes);

            JSONObject payload = new JSONObject();
            payload.put("model", "llava-phi3:latest");
            payload.put("prompt", prompt);
            payload.put("stream", false);
            JSONArray imagesArray = new JSONArray();
            imagesArray.put(base64);
            payload.put("images", imagesArray);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(OLLAMA_URL))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(payload.toString()))
                    .build();

            return httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                    .thenApply(HttpResponse::body)
                    .thenApply(body -> {
                        if (cancelFlag.get()) return "[Cancelled]";
                        JSONObject obj = new JSONObject(body);
                        if (obj.has("error")) {
                            return "[Error del modelo: " + obj.getString("error") + "]";
                        }
                        return obj.optString("response", "");
                    });

        } catch (IOException e) {
            CompletableFuture<String> failed = new CompletableFuture<>();
            failed.completeExceptionally(e);
            return failed;
        }
    }

    @Override
    public void shutdown() {
        executor.shutdownNow();
    }
}
