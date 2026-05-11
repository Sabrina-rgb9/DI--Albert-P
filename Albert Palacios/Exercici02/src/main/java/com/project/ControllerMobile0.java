package com.project;

import javafx.fxml.FXML;
import javafx.scene.layout.AnchorPane;

public class ControllerMobile0 {

    // Root pane for the first mobile selection screen.
    @FXML
    private AnchorPane rootPaneMobile0;

    // Called after FXML loading. Sets up a listener to switch to desktop view on wide windows.
    public void initialize() {
            try {
            rootPaneMobile0.widthProperty().addListener((obs, oldVal, newVal) -> {
                if ((double) newVal > 800) {
                    UtilsViews.setView("viewDesktop");
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Navigate to the mobile list screen and show characters.
    @FXML
    private void setCharacters() throws Exception {
        ControllerMobile1 controllerMobile1 = (ControllerMobile1) UtilsViews.getController("viewMobile1");
        controllerMobile1.setCharacters();
        UtilsViews.setView("viewMobile1");
    }

    // Navigate to the mobile list screen and show consoles.
    @FXML
    private void setConsoles() throws Exception {
        ControllerMobile1 controllerMobile1 = (ControllerMobile1) UtilsViews.getController("viewMobile1");
        controllerMobile1.setConsoles();
        UtilsViews.setView("viewMobile1");
    }

    // Navigate to the mobile list screen and show games.
    @FXML
    private void setGames() throws Exception {
        ControllerMobile1 controllerMobile1 = (ControllerMobile1) UtilsViews.getController("viewMobile1");
        controllerMobile1.setGames();
        UtilsViews.setView("viewMobile1");
    }
}
