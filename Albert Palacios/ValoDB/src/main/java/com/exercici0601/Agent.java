// src/main/java/com/exercici0601/Agent.java
package com.exercici0601;

public class Agent {
    private int number;
    private String name;
    private String type;
    private String ability;
    private String height;
    private String weight;
    private String category;
    private String image;

    // Getters
    public int getNumber() { 
        return number; 
    }
    public String getName() { 
        return name; 
    }
    public String getType() { 
        return type; 
    }
    public String getAbility() { 
        return ability; 
    }
    public String getHeight() { 
        return height; 
    }
    public String getWeight() { 
        return weight; 
    }
    public String getCategory() { 
        return category; 
    }
    public String getImage() { 
        return image; 
    }

    // Setters
    public void setNumber(int number) { 
        this.number = number; 
    }

    public void setName(String name) { 
        this.name = name; 
    }

    public void setType(String type) { 
        this.type = type; 
    }

    public void setAbility(String ability) { 
        this.ability = ability; 
    }

    public void setHeight(String height) { 
        this.height = height; 
    }
    public void setWeight(String weight) { 
        this.weight = weight; 
    }
    public void setCategory(String category) { 
        this.category = category; 
    }
    public void setImage(String image) { 
        this.image = image; 
    }

    // Mètode auxiliar per color
    public String getCategoryColor() {
        return switch (category.toLowerCase()) {
            case "wind" -> "-fx-fill: #00aaff;";
            case "fire" -> "-fx-fill: #ff6600;";
            case "poison" -> "-fx-fill: #00cc66;";
            case "archer" -> "-fx-fill: #6633cc;";
            case "healer" -> "-fx-fill: #ff3399;";
            case "tactician" -> "-fx-fill: #996633;";
            case "shadow" -> "-fx-fill: #444444;";
            case "explosives" -> "-fx-fill: #ff3300;";
            case "spy" -> "-fx-fill: #0066cc;";
            case "shock" -> "-fx-fill: #cc6600;";
            case "soul" -> "-fx-fill: #cc0066;";
            case "tech" -> "-fx-fill: #ffff00;";
            case "nature" -> "-fx-fill: #33cc33;";
            case "dimension" -> "-fx-fill: #9900ff;";
            case "cosmos" -> "-fx-fill: #6600cc;";
            case "speed" -> "-fx-fill: #00ffff;";
            default -> "-fx-fill: #aaaaaa;";
        };
    }
}