package com.project.model;

import javafx.beans.property.BooleanProperty;
import javafx.beans.property.SimpleBooleanProperty;
import javafx.beans.property.SimpleStringProperty;
import javafx.beans.property.StringProperty;

/**
 * Modelo simple para mensajes del chat.
 * Usamos propiedades de JavaFX para que la UI pueda reaccionar a cambios.
 */
public class ChatMessage {
    private final StringProperty text = new SimpleStringProperty("");
    private final BooleanProperty user = new SimpleBooleanProperty(false);

    public ChatMessage(String text, boolean isUser) {
        this.text.set(text);
        this.user.set(isUser);
    }

    public String getText() {
        return text.get();
    }

    public void setText(String value) {
        this.text.set(value);
    }

    public StringProperty textProperty() {
        return text;
    }

    public boolean isUser() {
        return user.get();
    }

    public BooleanProperty userProperty() {
        return user;
    }
}
