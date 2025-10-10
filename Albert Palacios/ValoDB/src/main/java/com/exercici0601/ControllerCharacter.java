// src/main/java/com/exercici0601/ControllerCharacter.java
package com.exercici0601;

import com.utils.UtilsViews;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

import java.net.URL;
import java.util.ResourceBundle;

public class ControllerCharacter implements Initializable {

    @FXML private Label nom;
    @FXML private Label game;
    @FXML private Circle circle;
    @FXML private ImageView image;
    @FXML private ImageView imgArrowBack;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        try {
            URL imageURL = getClass().getResource("/assets/images0601/arrow-back.png");
            if (imageURL != null) {
                imgArrowBack.setImage(new Image(imageURL.toExternalForm()));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void setNom(String nom) {
        this.nom.setText(nom);
    }

    public void setGame(String game) {
        this.game.setText(game);
    }

    public void setImage(Image image) {
        this.image.setImage(image);
    }

    public void setCircle(String colorStyle) {
        this.circle.setStyle(colorStyle);
    }

    @FXML
    private void toViewMain(MouseEvent event) {
        UtilsViews.setViewAnimating("ViewCharacters");
    }
}