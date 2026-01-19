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


  // Inicia el joc

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

  // Gestiona la entrada de l'usuari 

  void handleInput(String input) {
    // Handle user input for revealing cells, placing flags, showing cheats, etc.
    // Implementation will depend on the input format and game logic.

    if (input.startsWith('reveal ')) { // Reveal a cell
      var parts = input.split(' ');
      int x = int.parse(parts[1]);
      int y = int.parse(parts[2]);
      revealCell(x, y);
    } else if (input.startsWith('flag ')) { // Place a flag
      var parts = input.split(' ');
      int x = int.parse(parts[1]);
      int y = int.parse(parts[2]);
      placeFlag(x, y);
    } else if (input == 'cheat') { // Show mines temporarily
      // Show mines temporarily
      revealMines();
      printBoard();
      // Hide mines again
      for (var row in board) {
        for (var cell in row) {
          if (cell.isMine) {
            cell.isRevealed = false;
          }
        }
      }
    }
    totalMoves++;
  }

  // Revela una de las celdas mediante el comando del usuario 

  void revealCell(int x, int y) {
    if (x >= 0 && x < board.length && y >= 0 && y < board[0].length) {
      board[x][y].isRevealed = true;
      if (board[x][y].isMine) {
        gameOver = true;
      }
    }
  }

  // coloca una bandera en una celda mediante el comando del usuario

  void placeFlag(int x, int y) {
    if (x >= 0 && x < board.length && y >= 0 && y < board[0].length) {
      board[x][y].hasFlag = !board[x][y].hasFlag;
    }
  }

  // Imprime el estado actual del tablero
  void printBoard() {
    // Print the current state of the board
    for (var row in board) {
      for (var cell in row) {
        if (cell.isRevealed) {
          if (cell.isMine) {
            stdout.write('* ');
          } else {
            stdout.write('${cell.adjacentMines} ');
          }
        } else if (cell.hasFlag) {
          stdout.write('F ');
        } else {
          stdout.write('. ');
        }
      }
      stdout.writeln();
    }
  }

  // sirve para revelar todas las minas una vez el juego finaliza 
  void revealMines() {
    // Reveal all mines on the board
    for (var row in board) {
      for (var cell in row) {
        if (cell.isMine) {
          cell.isRevealed = true;
        }
      }
    }
  }

  // se crea el tablero del juego con las minas 
  List<List<Cell>> generateBoard() {
    // Generate the game board with mines and numbers
    List<List<Cell>> board = [];
    for (int i = 0; i < 10; i++) {
      List<Cell> row = [];
      for (int j = 0; j < 10; j++) {
        row.add(Cell());
      }
      board.add(row);
    }
    return board;
  }
}

// Clase que representa una celda del tablero
class Cell {
  bool isMine;
  bool isRevealed;
  bool hasFlag;
  int adjacentMines;

  Cell({this.isMine = false, this.isRevealed = false, this.hasFlag = false, this.adjacentMines = 0});
}