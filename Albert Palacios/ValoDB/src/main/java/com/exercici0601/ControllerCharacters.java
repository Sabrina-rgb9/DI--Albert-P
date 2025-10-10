// src/main/java/com/exercici0601/ControllerCharacters.java
package com.exercici0601;

import com.utils.UtilsViews;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.VBox;

import org.json.JSONArray;
import org.json.JSONObject;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ResourceBundle;

public class ControllerCharacters implements Initializable {

    @FXML private ImageView imgArrowBack;
    @FXML private VBox list;

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

        loadList();
    }

    public void loadList() {
        try {
            URL jsonFileURL = getClass().getResource("/assets/data/valorant.json");
            Path path = Paths.get(jsonFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            JSONArray jsonInfo = new JSONArray(content);
            String pathImages = "/assets/";

            list.getChildren().clear();

            for (int i = 0; i < jsonInfo.length(); i++) {
                JSONObject obj = jsonInfo.getJSONObject(i);
                Agent agent = new Agent();
                agent.setNumber(obj.getInt("number"));
                agent.setName(obj.getString("name"));
                agent.setType(obj.getString("type"));
                agent.setAbility(obj.getString("ability"));
                agent.setHeight(obj.getString("height"));
                agent.setWeight(obj.getString("weight"));
                agent.setCategory(obj.getString("category"));
                agent.setImage(obj.getString("image"));

                FXMLLoader loader = new FXMLLoader(getClass().getResource("/assets/subviewCharacters.fxml"));
                Parent itemPane = loader.load();
                ControllerItem1 itemController = loader.getController();

                itemController.setTitle(agent.getName());
                itemController.setSubtitle(agent.getType());
                itemController.setImage(pathImages + agent.getImage());
                itemController.setCircleColor(agent.getCategoryColor());
                itemController.setAgent(agent);

                list.getChildren().add(itemPane);
            }
        } catch (Exception e) {
            System.err.println("Error al carregar la llista de personatges");
            e.printStackTrace();
        }
    }

    @FXML
    private void toViewMain(MouseEvent event) {
        UtilsViews.setViewAnimating("ViewMain");
    }
}