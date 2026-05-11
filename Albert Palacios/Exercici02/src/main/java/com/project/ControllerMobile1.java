package com.project;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.json.JSONArray;
import org.json.JSONObject;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.VBox;

public class ControllerMobile1 {

    // Root pane for the mobile list and selection screen.
    @FXML
    private AnchorPane rootPaneMobile1;

    // Container used to display the dynamic list of items.
    @FXML
    private VBox yPane;

    // JSON arrays loaded from resources to represent characters, consoles and games.
    private JSONArray jsonInfoCharacters, jsonInfoConsoles, jsonInfoGames;

    // Template resource used to create each list item node.
    private URL resource = this.getClass().getResource("/assets/listItem.fxml");

    // Called after FXML loading to initialize data and event listeners.
    public void initialize() {
        try {
            // Obtener lista Characters
            URL jsonCharactersFileURL = getClass().getResource("/assets/characters.json");
            Path path = Paths.get(jsonCharactersFileURL.toURI());
            String content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            jsonInfoCharacters = new JSONArray(content);

            // Obtener lista Consoles
            URL jsonConsolesFileURL = getClass().getResource("/assets/consoles.json");
            path = Paths.get(jsonConsolesFileURL.toURI());
            content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            jsonInfoConsoles = new JSONArray(content);

            // Obtener lista Games
            URL jsonGamesFileURL = getClass().getResource("/assets/games.json");
            path = Paths.get(jsonGamesFileURL.toURI());
            content = new String(Files.readAllBytes(path), StandardCharsets.UTF_8);
            jsonInfoGames = new JSONArray(content);

            // When the mobile view becomes wide enough, switch to the desktop layout.
            rootPaneMobile1.widthProperty().addListener((obs, oldVal, newVal) -> {
                if ((double) newVal > 800) {
                    UtilsViews.setView("viewDesktop");
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Build the character list view and add click listeners to each item.
    @FXML
    public void setCharacters() throws Exception {
        // Clear previous items from the list container.
        yPane.getChildren().clear();

        // Generar la nueva lista a partir de 'jsonInfoCharacters'
        for (int i = 0; i < jsonInfoCharacters.length(); i++) {
            // Obtenir el objeto JSON individual (character)
            JSONObject character = jsonInfoCharacters.getJSONObject(i);

            // Extraer información necesaria del JSON
            String name = character.getString("name");

            // Carregar el template de 'listItem.fxml'
            FXMLLoader loader = new FXMLLoader(resource);
            Parent itemTemplate = loader.load();
            ControllerListItem itemController = loader.getController();

            // Asignar los valores a los controles del template
            itemController.setLableName(name);
            if (name.equals("Samus Aran")) {
                name = "samus";
            } else if (name.equals("Donkey Kong")) {
                name = "dk";
            }

            String urlImage = "/assets/images/character_" + name.toLowerCase() + ".png";
            itemController.setImatge(urlImage);

            // Añadir el nuevo elemento a 'yPane'
            yPane.getChildren().add(itemTemplate);

            // When the item is clicked, show the detail screen for the selected character.
            itemTemplate.setOnMouseClicked(e -> {
                ControllerMobile2 controllerMobile2 = (ControllerMobile2) UtilsViews.getController("viewMobile2");
                controllerMobile2.updateMainScreen(character, urlImage);
                UtilsViews.setView("viewMobile2");
            });
        }
    }

    // Build the console list view and handle console image selection logic.
    @FXML
    public void setConsoles() throws Exception {
        // Clear previous items from the list container.
        yPane.getChildren().clear();

        // Generar la nueva lista a partir de 'jsonInfoCharacters'
        for (int i = 0; i < jsonInfoConsoles.length(); i++) {
            // Obtenir el objeto JSON individual (character)
            JSONObject console = jsonInfoConsoles.getJSONObject(i);

            // Extraer información necesaria del JSON
            String name = console.getString("name");

            // Carregar el template de 'listItem.fxml'
            FXMLLoader loader = new FXMLLoader(resource);
            Parent itemTemplate = loader.load();
            ControllerListItem itemController = loader.getController();

            // Asignar los valores a los controles del template
            itemController.setLableName(name);
            if (name.equals("Nintendo Switch")) {
                name = "switch";
            } else if (name.equals("Wii U")) {
                name = "wiiu";
            } else if (name.equals("Nintendo 64")) {
                name = "64";
            } else if (name.equals("Super Nintendo")) {
                name = "sn";
            }

            String urlImage = "/assets/images/nintendo_" + name.toLowerCase() + ".png";
            itemController.setImatge("/assets/images/nintendo_" + name.toLowerCase() + ".png");

            // Añadir el nuevo elemento a 'yPane'
            yPane.getChildren().add(itemTemplate);

            // Añadir listener para que al hacer click se actualice la pantalla central
            itemTemplate.setOnMouseClicked(e -> {
                // Preparar siguiente vista
                ControllerMobile2 controllerMobile2 = (ControllerMobile2) UtilsViews.getController("viewMobile2");
                controllerMobile2.updateMainScreen(console, urlImage);

                // Cambiar a la siguiente vista
                UtilsViews.setView("viewMobile2");
            });
        }
    }

    // Build the games list view and handle the image file extension mapping.
    @FXML
    public void setGames() throws Exception {
        // Clear previous items from the list container.
        yPane.getChildren().clear();

        // Generar la nueva lista a partir de 'jsonInfoCharacters'
        for (int i = 0; i < jsonInfoGames.length(); i++) {
            // Obtenir el objeto JSON individual (character)
            JSONObject game = jsonInfoGames.getJSONObject(i);

            // Extraer información necesaria del JSON
            String name = game.getString("name");

            // Carregar el template de 'listItem.fxml'
            FXMLLoader loader = new FXMLLoader(resource);
            Parent itemTemplate = loader.load();
            ControllerListItem itemController = loader.getController();

            // Asignar los valores a los controles del template
            itemController.setLableName(name);
            if (name.equals("The Legend of Zelda")) {
                name = "zelda";
            } else if (name.equals("Pokémon Red i Blue")) {
                name = "pred";
            } else if (name.equals("Mario Kart 64")) {
                name = "smk";
            } else if (name.equals("Donkey Kong")) {
                name = "dk";
            } else if (name.equals("Super Mario Bros")) {
                name = "smb";
            }

            String extension = ".png";
            if (name.equals("Metroid") || name.equals("pred") || name.equals("smk")) {
                extension = ".jpeg";
            }

            String urlImage = "/assets/images/game_" + name.toLowerCase() + extension;
            itemController.setImatge("/assets/images/game_" + name.toLowerCase() + extension);

            // Añadir el nuevo elemento a 'yPane'
            yPane.getChildren().add(itemTemplate);

            // Añadir listener para que al hacer click se actualice la pantalla central
            itemTemplate.setOnMouseClicked(e -> {
                // Preparar siguiente vista
                ControllerMobile2 controllerMobile2 = (ControllerMobile2) UtilsViews.getController("viewMobile2");
                controllerMobile2.updateMainScreen(game, urlImage);

                // Cambiar a la siguiente vista
                UtilsViews.setView("viewMobile2");
            });
        }
    }

    // Navigate back to the first mobile selection view.
    @FXML
    private void toViewMobile0() {
        UtilsViews.setView("viewMobile0");
    }
}
