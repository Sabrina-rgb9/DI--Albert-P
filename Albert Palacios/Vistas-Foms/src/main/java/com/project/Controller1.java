package com.project;


import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.layout.AnchorPane;
import javafx.scene.control.TextField;

public class Controller1 {

    @FXML
    private Button sendB;
    @FXML
    private AnchorPane container;
    @FXML
    private TextField nombreV, edadV;

    public void setNameAge(){
        Main.name = nombreV.getText();
        Main.age = Integer.parseInt(edadV.getText());
    }

    @FXML
    private void animateToView1(ActionEvent event) {
        setNameAge();

        Controller2 ctrl = (Controller2) UtilsViews.getController("View2");
        ctrl.setMessage();

        UtilsViews.setViewAnimating("View2");
    }

}