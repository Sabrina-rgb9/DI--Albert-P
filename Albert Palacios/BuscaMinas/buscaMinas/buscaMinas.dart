import 'dart:io';

import 'package:buscaMinas/buscaMinas.dart';

void main() {
  final game = Buscamines();
  game.initializeGame();
  _startCli(game);
}

void _startCli(Buscamines game) {
  int moves = 0;

  String _hiddenSymbol = '·'; // U+00B7
  String _flagSymbol = '#';

  void printBoard({bool showMines = false}) {
    final rows = game.board.length;
    final cols = game.board[0].length;

    // Header
    stdout.write('   ');
    for (int c = 0; c < cols; c++) {
      stdout.write('$c');
    }
    stdout.writeln();

    for (int r = 0; r < rows; r++) {
      stdout.write(String.fromCharCode('A'.codeUnitAt(0) + r) + ' ');
      for (int c = 0; c < cols; c++) {
        final cell = game.board[r][c];
        String out;
        if (cell.isRevealed || (showMines && cell.isMine)) {
          if (cell.isMine) {
            out = '*';
          } else if (cell.adjacentMines == 0) {
            out = ' ';
          } else {
            out = '${cell.adjacentMines}';
          }
        } else if (cell.hasFlag) {
          out = _flagSymbol;
        } else {
          out = _hiddenSymbol;
        }
        stdout.write(out);
      }
      stdout.writeln();
    }
  }

  void printBoardsCheat() {
    // Print two boards side-by-side: current and with mines revealed
    final rows = game.board.length;
    final cols = game.board[0].length;

    // Headers
    stdout.write('   ');
    for (int c = 0; c < cols; c++) stdout.write('$c');
    stdout.write('     ');
    stdout.write('   ');
    for (int c = 0; c < cols; c++) stdout.write('$c');
    stdout.writeln();

    for (int r = 0; r < rows; r++) {
      stdout.write(String.fromCharCode('A'.codeUnitAt(0) + r) + ' ');
      for (int c = 0; c < cols; c++) {
        final cell = game.board[r][c];
        String out;
        if (cell.isRevealed) {
          if (cell.isMine) out = '*';
          else if (cell.adjacentMines == 0) out = ' ';
          else out = '${cell.adjacentMines}';
        } else if (cell.hasFlag) out = _flagSymbol;
        else out = _hiddenSymbol;
        stdout.write(out);
      }

      stdout.write('     ');

      // Mines shown board
      stdout.write(String.fromCharCode('A'.codeUnitAt(0) + r) + ' ');
      for (int c = 0; c < cols; c++) {
        final cell = game.board[r][c];
        String out = cell.isMine ? '*' : (cell.adjacentMines == 0 ? ' ' : '${cell.adjacentMines}');
        stdout.write(out);
      }
      stdout.writeln();
    }
  }

  printBoard();
  while (!game.isGameOver) {
    stdout.write('\nEscriu una comanda (p.ex. B2 | B2 flag | B2 bandera | trampes | cheat | ajuda | help | exit): ');
    String? input = stdin.readLineSync();
    if (input == null) continue;
    input = input.trim();
    if (input.isEmpty) continue;

    final lower = input.toLowerCase();
    if (lower == 'exit') {
      stdout.writeln('Sortint...');
      break;
    }
    if (lower == 'cheat' || lower == 'trampes') {
      printBoardsCheat();
      continue;
    }
    if (lower == 'help' || lower == 'ajuda') {
      stdout.writeln('Comandes:');
      stdout.writeln(' - Escollir casella: B2, D5, ...');
      stdout.writeln(' - Posar/treure bandera: B2 flag OR B2 bandera');
      stdout.writeln(' - Mostrar trampes: cheat OR trampes');
      stdout.writeln(' - Ajuda: help OR ajuda');
      stdout.writeln(' - Sortir: exit');
      continue;
    }

    // Parse coordinate formats
    final parts = input.split(RegExp(r'\s+'));
    final coord = parts[0];
    if (!RegExp(r'^[A-Za-z]\d+$').hasMatch(coord)) {
      stdout.writeln('Coordenada invàlida. Format: B2');
      continue;
    }

    final rowLetter = coord[0].toUpperCase();
    final rowIndex = rowLetter.codeUnitAt(0) - 'A'.codeUnitAt(0);
    final colStr = coord.substring(1);
    int? colIndex = int.tryParse(colStr);
    if (colIndex == null || rowIndex < 0 || rowIndex >= game.board.length || colIndex < 0 || colIndex >= game.board[0].length) {
      stdout.writeln('Coordenades fora de rang.');
      continue;
    }

    // flag command
    if (parts.length >= 2 && (parts[1].toLowerCase() == 'flag' || parts[1].toLowerCase() == 'bandera')) {
      game.placeFlag(rowIndex, colIndex);
      // flags do NOT count as tirades
      printBoard();
      continue;
    }

    // otherwise it's a selection
    moves++;
    final exploded = game.revealCell(rowIndex, colIndex);
    if (exploded) {
      game.revealAllMines();
      printBoard();
      stdout.writeln('Has perdut! Has explodat una mina.');
      stdout.writeln('Número de tirades: $moves');
      break;
    }
    printBoard();
  }
}
