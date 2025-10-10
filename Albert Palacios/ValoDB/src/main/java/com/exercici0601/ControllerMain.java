// src/main/java/com/exercici0601/ControllerMain.java
package com.exercici0601;

import com.utils.UtilsViews;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.VBox;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.HBox;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.Label;
import javafx.scene.Cursor;
import javafx.geometry.Insets;
import java.net.URL;
import java.util.ResourceBundle;

public class ControllerMain implements Initializable {

    @FXML private BorderPane mainBorderPane;
    @FXML private ImageView image;

    private ScrollPane scrollList;
    private VBox list;

    @Override
    public void initialize(URL url, ResourceBundle rb) {
        // Carregar imatge de benvinguda
        image.setImage(new Image(getClass().getResourceAsStream("/assets/images0601/valorant-logo.png")));

        // Crear la llista d'opcions (només "Personatges")
        createOptionsMenu();

        // Aplicar layout inicial un cop la vista està en escena
        mainBorderPane.sceneProperty().addListener((obs, oldScene, newScene) -> {
            if (newScene != null) {
                newScene.widthProperty().addListener((wObs, wOld, wNew) -> {
                    updateLayout(wNew.doubleValue());
                });
                updateLayout(newScene.getWidth());
            }
        });
    }

    private void createOptionsMenu() {
        list = new VBox();
        list.setAlignment(javafx.geometry.Pos.TOP_CENTER);

        AnchorPane item = new AnchorPane();
        item.setMaxHeight(50);
        item.setStyle("-fx-border-style: solid; -fx-border-width: 0 0 1 0; -fx-border-color: grey;");
        item.setCursor(Cursor.HAND);

        HBox hBox = new HBox();
        hBox.setAlignment(javafx.geometry.Pos.CENTER_LEFT);
        hBox.setSpacing(20);
        AnchorPane.setTopAnchor(hBox, 0.0);
        AnchorPane.setBottomAnchor(hBox, 0.0);
        AnchorPane.setLeftAnchor(hBox, 0.0);
        AnchorPane.setRightAnchor(hBox, 0.0);

        Label label = new Label("Personatges");
        label.setMaxHeight(50);
        label.setStyle("-fx-font-size: 18px; -fx-font-weight: bold;");
        HBox.setMargin(label, new Insets(0, 0, 0, 15));

        ImageView img = new ImageView(new Image(getClass().getResourceAsStream("/assets/images0601/jett-icon.png")));
        img.setFitHeight(40);
        img.setFitWidth(40);
        img.setPreserveRatio(true);
        HBox.setMargin(img, new Insets(0, 0, 0, 20));

        hBox.getChildren().addAll(label, img);
        item.getChildren().add(hBox);
        item.setOnMouseClicked(e -> toViewCharacters());

        list.getChildren().add(item);

        scrollList = new ScrollPane(list);
        scrollList.setFitToWidth(true);
        scrollList.setFitToHeight(true);
    }

    private void updateLayout(double width) {
        if (width >= 600) {
            mainBorderPane.setLeft(scrollList);
            mainBorderPane.setTop(null);
        } else {
            BorderPane topContainer = new BorderPane();
            topContainer.setTop(mainBorderPane.getTop());
            topContainer.setCenter(scrollList);
            mainBorderPane.setTop(topContainer);
            mainBorderPane.setLeft(null);
        }
    }

    @FXML
    private void toViewCharacters() {
        UtilsViews.setView("ViewCharacters");
    }
}