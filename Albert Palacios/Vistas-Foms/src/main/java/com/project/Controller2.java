package com.project;


import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextField;
import javafx.scene.layout.AnchorPane;

public class Controller2 {

    @FXML
    private Button backB;

    @FXML
    private AnchorPane container;
    
    @FXML
    private TextField msgText;

    public void setMessage() {
        msgText.setText("Hola "+ Main.name + ", tienes " + Main.age + " años.");
    }

    @FXML
    private void animateToView1(ActionEvent event) {
        UtilsViews.setViewAnimating("View1");
    }
}