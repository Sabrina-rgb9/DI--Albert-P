import 'dart:io';

import 'package:buscaMinas/buscaMinas.dart';

void main() {
  final game = Buscamines();
  game.initializeGame();
  _startCli(game);
}

void _startCli(Buscamines game) {
  int moves = 0;

  void printBoard() {
    final rows = game.board.length;
    final cols = game.board[0].length;

    // Header
    stdout.write('   ');
    for (int c = 0; c < cols; c++) {
      stdout.write('$c ');
    }
    stdout.writeln();

    for (int r = 0; r < rows; r++) {
      stdout.write(r.toString().padLeft(2) + ' ');
      for (int c = 0; c < cols; c++) {
        final cell = game.board[r][c];
        if (cell.isRevealed) {
          if (cell.isMine) {
            stdout.write('* ');
          } else if (cell.adjacentMines == 0) {
            stdout.write('  ');
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

  void revealMinesTemporary() {
    final revealed = <List<int>>[];
    for (int r = 0; r < game.board.length; r++) {
      for (int c = 0; c < game.board[0].length; c++) {
        if (game.board[r][c].isMine && !game.board[r][c].isRevealed) {
          game.board[r][c].isRevealed = true;
          revealed.add([r, c]);
        }
      }
    }
    printBoard();
    // hide again
    for (var p in revealed) {
      game.board[p[0]][p[1]].isRevealed = false;
    }
  }

  printBoard();
  while (!game.isGameOver) {
    stdout.write('\nEscriu una comanda (reveal x y | flag x y | cheat | exit): ');
    String? input = stdin.readLineSync();
    if (input == null) continue;
    input = input.trim();
    if (input == 'exit') {
      stdout.writeln('Sortint...');
      break;
    }
    if (input == 'cheat') {
      revealMinesTemporary();
      continue;
    }

    final parts = input.split(RegExp(r'\s+'));
    if (parts.isEmpty) continue;

    try {
      if (parts[0] == 'reveal' && parts.length >= 3) {
        final x = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        // Validate
        if (x < 0 || x >= game.board.length || y < 0 || y >= game.board[0].length) {
          stdout.writeln('Coordenades fora de rang.');
          continue;
        }
        final cell = game.board[x][y];
        if (cell.hasFlag) {
          stdout.writeln('Aquesta casella té una bandera. Treu-la abans de revelar.');
          continue;
        }
        final exploded = game.revealCell(x, y);
        moves++;
        if (exploded) {
          // Reveal all mines
          for (var row in game.board) {
            for (var c in row) {
              if (c.isMine) c.isRevealed = true;
            }
          }
          printBoard();
          stdout.writeln('Has perdut! Has explodat una mina.');
          stdout.writeln('Número de tirades: $moves');
          break;
        }
        printBoard();
      } else if (parts[0] == 'flag' && parts.length >= 3) {
        final x = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        if (x < 0 || x >= game.board.length || y < 0 || y >= game.board[0].length) {
          stdout.writeln('Coordenades fora de rang.');
          continue;
        }
        game.placeFlag(x, y);
        moves++;
        printBoard();
      } else {
        stdout.writeln('Comanda desconeguda. Usa: reveal x y | flag x y | cheat | exit');
      }
    } catch (e) {
      stdout.writeln('Error en el parseig de la comanda. Assegura\'t d\'usar nombres enters.');
    }
  }
}
