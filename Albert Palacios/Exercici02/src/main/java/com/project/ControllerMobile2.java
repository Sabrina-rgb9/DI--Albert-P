package com.project;

import java.util.Objects;

import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;
import javafx.scene.shape.Circle;
import javafx.scene.text.TextAlignment;

public class ControllerMobile2 {

    // Root pane of the mobile detail screen.
    @FXML
    private AnchorPane rootPaneMobile2;

    // Circle used to display the color value for character/console details.
    @FXML
    private Circle circle;

    // Container where the detail content is inserted dynamically.
    @FXML
    private VBox mainScreen;

    // Called automatically after the FXML is loaded.
    // Sets up a listener to switch to desktop view on wide windows.
    public void initialize() {
        try {
            rootPaneMobile2.widthProperty().addListener((obs, oldVal, newVal) -> {
                //System.out.println("rootPaneMobile2.widthProperty=" + newVal);
                if ((double) newVal > 800) {
                    //System.out.println("SE ACTIVA LISTENER EN VISTA viewMobile2");
                    UtilsViews.setView("viewDesktop");
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Update the detail screen with data from the selected JSON object.
    // The urlImage parameter points to the image asset to show for the selection.
    @FXML
    public void updateMainScreen(JSONObject jsonObject, String urlImage) {
        // Clear previous detail content.
        mainScreen.getChildren().clear();

        // Preparar imagen
        try {
            Image image = new Image(Objects.requireNonNull(getClass().getResourceAsStream(urlImage)));
            ImageView imageView = new ImageView(image);
            imageView.setFitWidth(200);
            imageView.setPreserveRatio(true);

            mainScreen.getChildren().add(imageView);
        } catch (NullPointerException e) {
            e.printStackTrace();
        }

        // Identify what type of object is being shown:
        // character entries have a "game" field,
        // consoles have a "procesador" field,
        // games have a "plot" field.
        boolean isCharacter = jsonObject.has("game");
        boolean isConsole = jsonObject.has("procesador");
        boolean isGame = jsonObject.has("plot");

        // Nombre
        Label name = new Label(jsonObject.getString("name"));
        name.setStyle("-fx-font-size: 30px; -fx-fill: black; -fx-font-weight: bold;");
        mainScreen.getChildren().add(name);

        // Game
        if (isCharacter) {
            Label game = new Label(jsonObject.getString("game"));
            game.setStyle("-fx-font-size: 20px;");
            mainScreen.getChildren().add(game);
        }

        // Date
        if (isConsole) {
            Label date = new Label(jsonObject.getString("date"));
            date.setStyle("-fx-font-size: 20px;");
            mainScreen.getChildren().add(date);
        }

        // Procesador
        if (isConsole) {
            Label procesador = new Label(jsonObject.getString("procesador"));
            procesador.setStyle("-fx-font-size: 20px;");
            mainScreen.getChildren().add(procesador);
        }

        // Units sold
        if (isConsole) {
            Label unitsSold = new Label(String.valueOf(jsonObject.getInt("units_sold")));
            unitsSold.setStyle("-fx-font-size: 20px;");
            mainScreen.getChildren().add(unitsSold);
        }

        // Year
        if (isGame) {
            Label year = new Label(String.valueOf(jsonObject.getInt("year")));
            year.setStyle("-fx-font-size: 20px;");
            mainScreen.getChildren().add(year);
        }

        // Type
        if (isGame) {
            Label type = new Label(jsonObject.getString("type"));
            type.setStyle("-fx-font-size: 20px;");
            mainScreen.getChildren().add(type);
        }

        // Plot
        if (isGame) {
            Label plot = new Label(jsonObject.getString("plot"));
            plot.setStyle("-fx-font-size: 15px;");
            plot.setWrapText(true);
            plot.setAlignment(Pos.CENTER);
            plot.setTextAlignment(TextAlignment.CENTER);
            mainScreen.getChildren().add(plot);
        }

        // Color
        if (isCharacter || isConsole) {
            circle = new Circle(20);
            circle.setStyle("-fx-fill: " + jsonObject.getString("color"));
            mainScreen.getChildren().add(circle);
        }
    }

    // Navigate back to the mobile list screen.
    @FXML
    private void toViewMobile1() {
        UtilsViews.setView("viewMobile1");
    }
}
