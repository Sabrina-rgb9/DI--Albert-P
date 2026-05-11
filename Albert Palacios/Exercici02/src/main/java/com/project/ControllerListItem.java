package com.project;

import java.util.Objects;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;

public class ControllerListItem {

    // Label that displays the item name inside the list template.
    @FXML
    private Label labelName;

    // ImageView that displays the item image icon.
    @FXML
    private ImageView img;

    // Set the displayed name for the list item.
    public void setLableName(String name) {
        this.labelName.setText(name);
    }

    // Load an image resource and apply it to the item icon view.
    public void setImatge(String imagePath) {
        try {
            Image image = new Image(Objects.requireNonNull(getClass().getResourceAsStream(imagePath)));
            this.img.setImage(image);
        } catch (NullPointerException e) {
            System.err.println("Error loading image asset: " + imagePath);
            e.printStackTrace();
        }
    }
}
