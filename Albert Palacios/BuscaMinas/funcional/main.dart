import 'dart:io';
import 'board.dart';
import 'cell.dart';

void main() {

  while (true) {
    Board myBoard = Board(rows: 6, columns: 10, mineCount: 8);
    bool cheatMode = false;
    int tirades = 0;
    bool playing = true; // Controla el bucle de la partida actual

    print("Partida nova creada! El tauler és de 6x10 amb 8 mines. Sort!");

    // Bucle de la PARTIDA (Juego activo)
    while (playing) {
      print("\nBUSCAMINES (Tirades: $tirades)");
      myBoard.printBoard(revealMines: cheatMode);

      print(
        "Opcions: \n- Per destapar: A0, B3, etc.\n- Per posar/quitar bandera: A0 flag o A0 bandera\n- Per activar/desactivar trampa: cheat o trampes\n- Per sortir: exit",
      );
      stdout.write('> ');
      String? input = stdin.readLineSync();

      // Salida total de la aplicación
      if (input == null || input.toLowerCase() == 'exit') {
        print('Sortint del joc...');
        return; // Sale del main() completo
      }

      // Trucos
      if (input.trim().toLowerCase() == 'cheat' ||
          input.trim().toLowerCase() == 'trampes') {
        cheatMode = !cheatMode;
        print(cheatMode ? "Metode trampa activat" : "Metode trampa desactivat");
        continue;
      }

      // Normalización del input
      input = input.toUpperCase().trim();
      bool isFlagAction = false;

      if (input.endsWith('FLAG')) {
        isFlagAction = true;
        input = input.substring(0, input.length - 4).trim();
      } else if (input.endsWith('BANDERA')) {
        isFlagAction = true;
        input = input.substring(0, input.length - 7).trim();
      }

      if (input.length < 2) continue;

      // Convertir coordenadas para acceder a la matriz (A0 -> r=0, c=0)
      int r = input.codeUnitAt(0) - 'A'.codeUnitAt(0);

      // Extraer la parte numérica para la columna
      int c = int.tryParse(input.substring(1)) ?? -1;

      // Validar coordenadas
      if (r >= 0 && r < myBoard.rows && c >= 0 && c < myBoard.columns) {
        Cell target = myBoard.grid[r][c];

        if (isFlagAction) {
          // ACCIÓN DE BANDERA
          bool success = myBoard.toggleFlag(r, c);
          if (success) {
            print(
              target.isFlagged
                  ? "Bandera posada."
                  : "Bandera treta. Casella llesta per descobrir.",
            );

            // Verificar si el jugador ha ganado
            if (myBoard.checkWin()) {
              print("\nENHORABONA! Has guanyat la partida.");
              myBoard.printBoard(revealMines: true);
              print("Has col·locat totes les banderes correctament.");
              print("Total de tirades realitzades: $tirades");
              playing = false; // Terminar la partida
            }
          } else {
            print("No pots posar bandera en una casella destapada.");
          }
        } else {
          // acción de destapar
          if (target.isFlagged) {
            print("Hi ha una bandera! Treu-la primer ('$input flag').");
          } else if (target.isRevealed) {
            print("Ja està destapada.");
          } else {
            tirades++; // Solo cuenta si destapa y es válido

            if (target.isMine) {
              // --- GAME OVER ---
              print("\nCompte! Has destapat una mina. GAME OVER.");
              myBoard.printBoard(revealMines: true);
              print("Partida finalitzada. Has perdut.");
              print("Total de tirades realitzades: $tirades");

              playing = false; // Rompemos el bucle interno
            } else {
              myBoard.revealCell(r, c);
              print("Casella segura.");
            }
          }
        }
      } else {
        print("Coordenades invàlides.");
      }
    } 

    stdout.write("\nVols tornar a jugar? (S/N): ");
    String? retry = stdin.readLineSync();
    if (retry == null || retry.toUpperCase() != 'S') {
      print("Gràcies per jugar. Adéu!");
      break; 
    }
    // Si el jugador quiere jugar de nuevo, el bucle while(true) se repetirá y se creará una nueva partida.
  }
}
