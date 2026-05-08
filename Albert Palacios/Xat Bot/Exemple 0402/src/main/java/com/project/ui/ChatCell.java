package com.project.ui;

import com.project.model.ChatMessage;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.control.ListCell;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;

/**
 * CellFactory para mostrar mensajes en el ListView.
 */
public class ChatCell extends ListCell<ChatMessage> {
    @Override
    protected void updateItem(ChatMessage item, boolean empty) {
        super.updateItem(item, empty); // update item para manejar el estado vacío
        
        // Si la celda está vacía, no mostrar nada
        if (empty || item == null) {
            setGraphic(null);
            setText(null);
        } else { // en caso contrario, mostrar el mensaje
            Label label = new Label();
            label.textProperty().bind(item.textProperty()); // Bind al texto del mensaje
            label.setWrapText(true);
            label.setMaxWidth(Double.MAX_VALUE);
            label.setPadding(new Insets(8,12,8,12));
            HBox.setHgrow(label, Priority.ALWAYS);

            // Estilizar según si es mensaje del usuario o de la IA
            HBox hbox = new HBox(label);
            hbox.maxWidthProperty().bind(getListView().widthProperty().subtract(40));
            if (item.isUser()) {
                hbox.setAlignment(Pos.CENTER_RIGHT);
                label.setStyle("-fx-background-color: #DCF8C6; -fx-background-radius: 10; -fx-text-fill: black;");
            } else {
                hbox.setAlignment(Pos.CENTER_LEFT);
                label.setStyle("-fx-background-color: #FFFFFF; -fx-background-radius: 10; -fx-text-fill: black;");
            }

            setGraphic(hbox);
        }
    }
}
