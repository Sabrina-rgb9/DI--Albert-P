package com.project.service;

import java.io.File;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;

/**
 * Interfaz para la comunicación con Ollama.
 * Permite streaming de texto y generación de respuesta completa para imágenes.
 */
public interface OllamaClient {


    CompletableFuture<Void> streamText(
            String prompt,
            Consumer<String> onToken,
            Runnable onComplete,
            Consumer<Throwable> onError,
            AtomicBoolean cancelFlag
    );

    CompletableFuture<String> generateImageComplete(
            File image,
            String prompt,
            AtomicBoolean cancelFlag
    );

    void shutdown();
}
