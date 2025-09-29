package com.project;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.text.Text;
import javafx.event.ActionEvent;

public class Controller {

    @FXML
    private Text display;
    
    private double num1 = 0;
    private String operator = "";
    private boolean nuevoNum = true;

    @FXML
    private void actionNumber(ActionEvent event) {
        String value = ((Button) event.getSource()).getText();

        if (nuevoNum || display.getText().equals("0")) {
            display.setText(value);
            nuevoNum = false;
        } else {
            display.setText(display.getText() + value);
        }
    }

    @FXML
    private void actionDot() {
        if (nuevoNum) {
            display.setText("0.");
            nuevoNum = false;
        } else if (!display.getText().contains(".")) {
            display.setText(display.getText() + ".");
        }
    }

    @FXML
    private void actionClear() {
        display.setText("0");
        num1 = 0;
        operator = "";
        nuevoNum = true;
    }

    @FXML
    private void actionAdd() {
        setOperator("+");
    }

    @FXML
    private void actionSubtract() {
        setOperator("-");
    }

    @FXML
    private void actionMultiply() {
        setOperator("*");
    }

    @FXML
    private void actionDivide() {
        setOperator("/");
    }

    private void setOperator(String op) {
        double current = Double.parseDouble(display.getText());

        if (!operator.isEmpty()) {
            double result = switch (operator) {
                case "+" -> num1 + current;
                case "-" -> num1 - current;
                case "*" -> num1 * current;
                case "/" -> (current == 0) ? 0 : num1 / current;
                default -> current;
            };
            num1 = result;
            display.setText((result % 1 == 0) ? String.valueOf((int) result) : String.valueOf(result));
        } else {
            num1 = current;
        }

        operator = op;
        nuevoNum = true;
    }

    @FXML
    private void actionEquals() {
        if (operator.isEmpty()) return;

        double num2 = Double.parseDouble(display.getText());
        double result = switch (operator) {
            case "+" -> num1 + num2;
            case "-" -> num1 - num2;
            case "*" -> num1 * num2;
            case "/" -> (num2 == 0) ? 0 : num1 / num2;
            default -> num2;
        };

        display.setText((result % 1 == 0) ? String.valueOf((int) result) : String.valueOf(result));
        nuevoNum = true;
        operator = "";
        num1 = result;
    }
}
