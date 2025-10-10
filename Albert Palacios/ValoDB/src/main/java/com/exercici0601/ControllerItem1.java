// src/main/java/com/exercici0601/ControllerItem1.java
package com.exercici0601;

import com.utils.UtilsViews;
import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseEvent;
import javafx.scene.shape.Circle;

public class ControllerItem1 {

    @FXML private Label title;
    @FXML private Label subtitle;
    @FXML private ImageView image;
    @FXML private Circle circle;

    private Agent agent;

    public void setTitle(String name) {
        title.setText(name);
    }

    public void setSubtitle(String type) {
        subtitle.setText(type);
    }

    public void setImage(String imagePath) {
        image.setImage(new Image(getClass().getResourceAsStream(imagePath)));
    }

    public void setCircleColor(String colorStyle) {
        circle.setStyle(colorStyle);
    }

    public void setAgent(Agent agent) {
        this.agent = agent;
    }

    @FXML
    private void toViewCharacter(MouseEvent event) {
        UtilsViews.setViewAnimating("ViewCharacter");
        ControllerCharacter controller = (ControllerCharacter) UtilsViews.getController("ViewCharacter");
        if (controller != null && agent != null) {
            controller.setNom(agent.getName());
            controller.setGame("Rol: " + agent.getType());
            controller.setImage(new Image(getClass().getResourceAsStream("/assets/" + agent.getImage())));
            controller.setCircle(agent.getCategoryColor());
        }
    }
}