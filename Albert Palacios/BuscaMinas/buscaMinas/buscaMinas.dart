import 'dart:io';


void main() {
  var game = Buscamines();
  game.startGame();
}

class Buscamines {
  late List<List<Cell>> board;
  late int totalMoves;
  bool gameOver = false;

  Buscamines() {
    totalMoves = 0;
    board = generateBoard();
  }

  void startGame() {
    printBoard();
    while (!gameOver) {
      print('Escriu una comanda:');
      String? input = stdin.readLineSync();
      if (input != null) {
        handleInput(input);
      }
    }
    revealMines();
    printBoard();
    print('Has perdut!');
    print('Número de tirades: $totalMoves');
  }

  void handleInput(String input) {
    // Handle user input for revealing cells, placing flags, showing cheats, etc.
    // Implementation will depend on the input format and game logic.
    totalMoves++;
  }

  void printBoard() {
    // Print the current state of the board
  }

  void revealMines() {
    // Reveal all mines on the board
  }

  List<List<Cell>> generateBoard() {
    // Generate the game board with mines and numbers
    return [];
  }
}

class Cell {
  bool isMine;
  bool isRevealed;
  bool hasFlag;
  int adjacentMines;

  Cell({this.isMine = false, this.isRevealed = false, this.hasFlag = false, this.adjacentMines = 0});
}