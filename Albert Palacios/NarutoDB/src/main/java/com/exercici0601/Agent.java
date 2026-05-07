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

    // Método auxiliar para asignar un color según la categoría ninja
    public String getCategoryColor() {
        return switch (category.toLowerCase()) {
            case "chakra" -> "-fx-fill: #ff8a1f;";
            case "rayo" -> "-fx-fill: #4d73ff;";
            case "medicina" -> "-fx-fill: #ef5a91;";
            case "sharingan" -> "-fx-fill: #c01822;";
            case "byakugan" -> "-fx-fill: #d2e5ff;";
            case "arena" -> "-fx-fill: #d19a4e;";
            case "genjutsu" -> "-fx-fill: #7837aa;";
            case "sabio" -> "-fx-fill: #50a55a;";
            case "taijutsu" -> "-fx-fill: #46b478;";
            case "sombra" -> "-fx-fill: #2d2d41;";
            default -> "-fx-fill: #aaaaaa;";
        };
    }
}