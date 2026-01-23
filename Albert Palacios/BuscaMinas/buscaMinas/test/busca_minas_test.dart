import 'package:buscaMinas/buscaMinas.dart';
import 'package:test/test.dart';

void main() {
  group('Buscamines Game Logic', () {
    late Buscamines game;

    setUp(() {
      game = Buscamines();
      game.initializeGame();
    });

    test('should place at least 8 mines on the board', () {
      expect(game.mineCount, greaterThanOrEqualTo(8));
    });

    test('should have at least 2 mines in each quadrant', () {
      int topLeftMines = game.countMinesInQuadrant(0, 4, 0, 4);
      int topRightMines = game.countMinesInQuadrant(5, 9, 0, 4);
      int bottomLeftMines = game.countMinesInQuadrant(0, 4, 5, 9);
      int bottomRightMines = game.countMinesInQuadrant(5, 9, 5, 9);

      expect(topLeftMines, greaterThanOrEqualTo(2));
      expect(topRightMines, greaterThanOrEqualTo(2));
      expect(bottomLeftMines, greaterThanOrEqualTo(2));
      expect(bottomRightMines, greaterThanOrEqualTo(2));
    });

    test('should reveal adjacent cells recursively when a cell with 0 adjacent mines is revealed', () {
      game.revealCell(0, 0); // Assuming (0, 0) is a cell with 0 adjacent mines
      expect(game.isCellRevealed(0, 1), isTrue);
      expect(game.isCellRevealed(1, 0), isTrue);
      expect(game.isCellRevealed(1, 1), isTrue);
    });

    test('should not reveal cells with flags', () {
      game.placeFlag(1, 1);
      game.revealCell(1, 1);
      expect(game.isCellRevealed(1, 1), isFalse);
    });

    test('should end the game if a mine is revealed', () {
      game.placeMine(2, 2); // Assuming (2, 2) is a mine
      expect(game.revealCell(2, 2), isTrue); // Should return true indicating explosion
      expect(game.isGameOver, isTrue);
    });
  });
}