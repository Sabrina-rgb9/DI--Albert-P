package com.project;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.scene.control.Alert;
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

    public boolean setNameAge() {
        String nameText = nombreV.getText();
        String ageText = edadV.getText();

        if (!nameText.matches("[a-zA-ZáéíóúÁÉÍÓÚñÑ\\s]+")) {
            showError("El campo 'Nombre' solo acepta letras.");
            return false;
        }

        if (!ageText.matches("\\d+")) {
            showError("El campo 'Edad' solo acepta números.");
            return false;
        }

        Main.name = nameText;
        Main.age = Integer.parseInt(ageText);
        return true;
    }

    @FXML
    private void animateToView1(ActionEvent event) {
        if (!setNameAge()) {
            return; 
        }

        Controller2 ctrl = (Controller2) UtilsViews.getController("View2");
        ctrl.setMessage();

        UtilsViews.setViewAnimating("View2");
    }

    private void showError(String mensaje) {
        Alert alert = new Alert(Alert.AlertType.ERROR);
        alert.setTitle("Error de validación");
        alert.setHeaderText(null);
        alert.setContentText(mensaje);
        alert.showAndWait();
    }
}
