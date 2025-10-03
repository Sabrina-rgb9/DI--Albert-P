package com.exercici0601;

import com.utils.*;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.stage.FileChooser;
import javafx.stage.Stage;

public class ControllerMain {

    @FXML
    private ImageView image;




    @FXML
    public void initialize() {
        Image img = new Image(getClass().getResourceAsStream("/icons/vi_portada.gif"));
        image.setImage(img);
        
    }

    @FXML
    private void toViewCharacters(MouseEvent event) {
        System.out.println("To View Characters");
        ControllerCharacters ctrlCharacters = (ControllerCharacters) UtilsViews.getController("ViewCharacters");
        ctrlCharacters.loadList();
        UtilsViews.setViewAnimating("ViewCharacters");
    }

    @FXML
    private void toViewGames(MouseEvent event) {
        System.out.println("To View Games");
        ControllerGames ctrlGames = (ControllerGames) UtilsViews.getController("ViewGames");
        ctrlGames.loadList();
        UtilsViews.setViewAnimating("ViewGames");
    }

    @FXML
    private void toViewConsoles(MouseEvent event) {
        System.out.println("To View Consoles");
        ControllerConsoles ctrlConsoles = (ControllerConsoles) UtilsViews.getController("ViewConsoles");
        ctrlConsoles.loadList();
        UtilsViews.setViewAnimating("ViewConsoles");
    }
}
