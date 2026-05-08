import 'cell.dart';
import 'dart:math';

class Board {
  final int rows;
  final int columns;
  final int mineCount;

  // Aquí guardaremos las instancias (los objetos reales)
  // Es una lista de listas de objetos Cell
  List<List<Cell>> grid = [];

  Board({required this.rows, required this.columns, required this.mineCount}) {
    _initializeBoard();
    _placeMines();
    _nearMines();
  }

  // metode per inicialitzar el tauler, creant les instàncies de les cel·les i posant-les a la graella
  void _initializeBoard() {
    for (int r = 0; r < rows; r++) {
      List<Cell> rowList = [];
      for (int c = 0; c < columns; c++) {
        // Calculate position string (e.g., "A0", "B3")
        String letter = String.fromCharCode('A'.codeUnitAt(0) + r);
        String pos = "$letter$c";

        // crea la instància de la cel·la amb la posició i els valors per defecte
        Cell newCell = Cell(position: pos);

        // s'afegeix la cel·la a la fila
        rowList.add(newCell);
      }
      // s'afegeix la fila a la graella
      grid.add(rowList);
    }
  }

  /**
   * @param fMin Row min (inclusive)
   * @param fMax Row max (inclusive)
   * @param cMin Column min (inclusive)
   * @param cMax Column max (inclusive)
   * @param quantity Number of mines to place in the zone
   */
  void _placeMinesInZone(int fMin, int fMax, int cMin, int cMax, int quantity) {
    var rng = Random();
    int mines = 0;

    // 1. Generar coordenadas aleatorias dentro de la zona
    while (mines < quantity) {
      
      // 2. Validar que no haya una mina ya en esa posición
      int r = fMin + rng.nextInt(fMax - fMin + 1);
      int c = cMin + rng.nextInt(cMax - cMin + 1);

      if (grid[r][c].isMine == false) {
        // 3. Poner la mina
        grid[r][c].isMine = true;

        mines++;
      }
    }
  }

  //  Función para colocar las minas en el tablero, llamando a la función de cada zona
  void _placeMines() {
    // Colocamos 2 minas en cada zona (4 zonas) para un total de 8 minas
    _placeMinesInZone(0, 2, 0, 4, 2);
    _placeMinesInZone(0, 2, 5, 9, 2);
    _placeMinesInZone(3, 5, 0, 4, 2);
    _placeMinesInZone(3, 5, 5, 9, 2);
  }

  // Función para calcular el número de minas adyacentes a cada celda
  void _nearMines() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        if (grid[r][c].isMine) {
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              int newRow = r + dr;
              int newCol = c + dc;

              // Validar límites y evitar contar la mina actual
              if (newRow >= 0 &&
                  newRow < rows &&
                  newCol >= 0 &&
                  newCol < columns &&
                  !(dr == 0 && dc == 0)) {
                grid[newRow][newCol].adjacentMines++;
              }
            }
          }
        }
      }
    }
  }

  // Función para imprimir el tablero en la consola
  void printBoard({bool revealMines = false}) {
    print("   " + List.generate(columns, (i) => i.toString()).join(" "));
    print("  " + "-" * (columns * 2));

    for (int r = 0; r < rows; r++) {
      String letter = String.fromCharCode('A'.codeUnitAt(0) + r);
      String rowStr = "$letter |";

      for (int c = 0; c < columns; c++) {
        Cell cell = grid[r][c];
        String char = ".";

        // 1. Si el modo trampa está activado, mostrar minas y números aunque no estén destapados
        if (revealMines) {
          if (cell.isMine)
            char = "*";
          else if (cell.adjacentMines > 0)
            char = cell.adjacentMines.toString();
          else
            char = " ";
        }
        // 2. Si la celda tiene bandera, mostrar el símbolo de bandera
        else if (cell.isFlagged) {
          char = "#"; // Símbol de bandera
        }
        // 3. Si la celda está destapada, mostrar el número de minas adyacentes o un espacio si es 0
        else if (cell.isRevealed) {
          if (cell.adjacentMines > 0)
            char = cell.adjacentMines.toString();
          else
            char = " "; // Casella buida (0)
        }
        // 4. Si la celda no está destapada ni tiene bandera, mostrar el símbolo de casilla cerrada (punto)

        rowStr += "$char ";
      }
      print(rowStr);
    }
  }

  // Función para destapar una celda y, si es un espacio vacío (0 minas adyacentes), destapar recursivamente las celdas adyacentes
  void revealCell(int r, int c) {
    // Límits del tauler
    if (r < 0 || r >= rows || c < 0 || c >= columns) return;

    Cell cell = grid[r][c];

    if (cell.isRevealed || cell.isFlagged) return;

    cell.isRevealed = true;

    if (cell.adjacentMines == 0 && !cell.isMine) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr != 0 || dc != 0) {
            revealCell(r + dr, c + dc);
          }
        }
      }
    }
  }

  // Función para colocar o quitar una bandera en una celda (solo si no está destapada)
  bool toggleFlag(int r, int c) {
    if (r >= 0 && r < rows && c >= 0 && c < columns) {
      Cell cell = grid[r][c];
      if (!cell.isRevealed) {
        cell.isFlagged = !cell.isFlagged;
        return true;
      }
    }
    return false;
  }

  // Función para verificar si el jugador ha ganado (todas las minas están marcadas con bandera y no hay banderas extra)
  bool checkWin() {
    int correctFlags = 0;
    int totalFlags = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        Cell cell = grid[r][c];
        if (cell.isFlagged) {
          totalFlags++;
          if (cell.isMine) {
            correctFlags++;
          }
        }
      }
    }

    // El jugador gana si ha colocado exactamente el número de banderas igual al número de minas, y todas las banderas están en las minas correctas
    return correctFlags == mineCount && totalFlags == mineCount;
  }
}
