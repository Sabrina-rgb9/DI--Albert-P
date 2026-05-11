import 'dart:math' as math;
import 'dart:ui' as ui;

import 'app_data.dart';
import 'libgdx_compat/game_framework.dart';
import 'libgdx_compat/math_types.dart';

class PlayerListStyle {
  final double maxTextScale;
  final double minTextScale;
  final double maxRowHeight;
  final double minRowHeight;
  final int maxCharsAtLowCount;
  final int maxCharsAtHighCount;

  const PlayerListStyle({
    required this.maxTextScale,
    required this.minTextScale,
    required this.maxRowHeight,
    required this.minRowHeight,
    required this.maxCharsAtLowCount,
    required this.maxCharsAtHighCount,
  });
}

class PlayerListRenderer {
  static const PlayerListStyle waitingRoomStyle = PlayerListStyle(
    maxTextScale: 1.0,
    minTextScale: 0.72,
    maxRowHeight: 29,
    minRowHeight: 18,
    maxCharsAtLowCount: 20,
    maxCharsAtHighCount: 15,
  );

  static const PlayerListStyle gameplayStyle = PlayerListStyle(
    maxTextScale: 0.86,
    minTextScale: 0.64,
    maxRowHeight: 46,
    minRowHeight: 34,
    maxCharsAtLowCount: 13,
    maxCharsAtHighCount: 9,
  );

  static final ui.Color cardFill = colorValueOf('10151FCC');
  static final ui.Color cardBorder = colorValueOf('FFFFFF22');
  static final ui.Color healthBack = colorValueOf('FFFFFF24');
  static final ui.Color healthGood = colorValueOf('42F58D');
  static final ui.Color healthMid = colorValueOf('FFD166');
  static final ui.Color healthBad = colorValueOf('FF4D6D');
  static final ui.Color deadColor = colorValueOf('777777');

  static void render({
    required SpriteBatch batch,
    required BitmapFont font,
    required GlyphLayout layout,
    required List<MultiplayerPlayer> players,
    required String? localPlayerId,
    required double left,
    required double right,
    required double startY,
    required ui.Color textColor,
    required ui.Color localPlayerColor,
    required void Function(
      SpriteBatch batch,
      BitmapFont font,
      String text,
      double x,
      double y,
      double scale,
      ui.Color color,
    )
    drawLeftAlignedText,
    required void Function(
      SpriteBatch batch,
      BitmapFont font,
      String text,
      double right,
      double y,
      double scale,
      ui.Color color,
    )
    drawRightAlignedText,
    required PlayerListStyle style,
  }) {
    final _PlayerListMetrics metrics = _metrics(players.length, style);
    final ShapeRenderer shapes = ShapeRenderer();

    double rowY = startY;

    for (final MultiplayerPlayer player in players) {
      final bool isLocalPlayer = player.id == localPlayerId;
      final bool isDead = player.stocks <= 0;

      final double cardX = left;
      final double cardY = rowY - 18;
      final double cardW = right - left;
      final double cardH = metrics.rowHeight - 7;

      shapes.begin(ShapeType.filled);
      shapes.setColor(cardFill);
      shapes.rect(cardX, cardY, cardW, cardH);
      shapes.end();

      shapes.begin(ShapeType.line);
      shapes.setColor(isLocalPlayer ? localPlayerColor : cardBorder);
      shapes.rect(cardX, cardY, cardW, cardH);
      shapes.end();

      final ui.Color nameColor = isDead
          ? deadColor
          : isLocalPlayer
              ? localPlayerColor
              : textColor;

      drawLeftAlignedText(
        batch,
        font,
        _truncatePlayerName(player.name, metrics.maxChars),
        cardX + 10,
        rowY,
        metrics.textScale,
        nameColor,
      );

      final double barX = cardX + 10;
      final double barY = rowY + 8;
      final double barW = cardW - 20;
      const double barH = 7;

      final double healthValue = player.stocks <= 0
          ? 0
          : clampDouble(1 - (player.damage / 160), 0, 1);

      final ui.Color healthColor = healthValue > 0.55
          ? healthGood
          : healthValue > 0.25
              ? healthMid
              : healthBad;

      shapes.begin(ShapeType.filled);
      shapes.setColor(healthBack);
      shapes.rect(barX, barY, barW, barH);
      shapes.setColor(healthColor);
      shapes.rect(barX, barY, barW * healthValue, barH);
      shapes.end();

      final double stockDotStartX = cardX + cardW - 14;
      final double stockY = cardY + 9;

      shapes.begin(ShapeType.filled);
      for (int i = 0; i < math.min(player.stocks, 3); i++) {
        shapes.setColor(isLocalPlayer ? localPlayerColor : textColor);
        shapes.rect(stockDotStartX - (i * 11), stockY, 6, 6);
      }
      shapes.end();

      rowY += metrics.rowHeight;
    }
  }

  static _PlayerListMetrics _metrics(int playerCount, PlayerListStyle style) {
    final double t = clampDouble((playerCount - 10) / 15, 0, 1);
    return _PlayerListMetrics(
      textScale:
          ui.lerpDouble(style.maxTextScale, style.minTextScale, t) ??
          style.minTextScale,
      rowHeight:
          ui.lerpDouble(style.maxRowHeight, style.minRowHeight, t) ??
          style.minRowHeight,
      maxChars:
          (ui.lerpDouble(
                    style.maxCharsAtLowCount.toDouble(),
                    style.maxCharsAtHighCount.toDouble(),
                    t,
                  ) ??
                  style.maxCharsAtHighCount.toDouble())
              .round(),
    );
  }

  static String _truncatePlayerName(String text, int maxChars) {
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, math.max(0, maxChars - 3))}...';
  }
}

class _PlayerListMetrics {
  final double textScale;
  final double rowHeight;
  final int maxChars;

  const _PlayerListMetrics({
    required this.textScale,
    required this.rowHeight,
    required this.maxChars,
  });
}