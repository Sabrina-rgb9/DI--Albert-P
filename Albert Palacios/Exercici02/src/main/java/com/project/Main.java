package com.project;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

public class Main extends Application {

    // Minimum window width used when the application starts.
    final int WINDOW_WIDTH = 500;

    // Minimum window height used when the application starts.
    final int WINDOW_HEIGHT = 300;

    @Override
    public void start(Stage stage) throws Exception {

        // Set the base font for the main parent container.
        UtilsViews.parentContainer.setStyle("-fx-font: 14 arial;");

        // Register the different UI views from FXML files.
        UtilsViews.addView(getClass(), "viewDesktop", "/assets/viewDesktop.fxml");
        UtilsViews.addView(getClass(), "viewMobile0", "/assets/viewMobile0.fxml");
        UtilsViews.addView(getClass(), "viewMobile1", "/assets/viewMobile1.fxml");
        UtilsViews.addView(getClass(), "viewMobile2", "/assets/viewMobile2.fxml");

        // Create the JavaFX scene with the shared parent container.
        Scene scene = new Scene(UtilsViews.parentContainer);

        stage.setScene(scene);
        stage.setTitle("Nintendo DB");
        stage.setMinWidth(WINDOW_WIDTH);
        stage.setMinHeight(WINDOW_HEIGHT);
        
        stage.show();

        // Add application icon on non-Mac platforms.
        if (!System.getProperty("os.name").contains("Mac")) {
            Image icon = new Image("file:/icons/icon.png");
            stage.getIcons().add(icon);
        }
    }

    // Program entry point. Launches the JavaFX application.
    public static void main(String[] args) {
        launch(args);
    }
}
