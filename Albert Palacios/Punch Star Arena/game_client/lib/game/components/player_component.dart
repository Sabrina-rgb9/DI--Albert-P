import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:flame/sprite.dart';
import '../../models/player_state.dart';

/// Representa visualmente a un jugador.
/// Los datos reales vienen del servidor; este componente solo pinta y anima.
class PlayerComponent extends SpriteAnimationGroupComponent<String>
    with HasGameRef {
  PlayerComponent({
    required this.playerId,
    required this.isLocal,
  }) : super(size: Vector2(64, 64), anchor: Anchor.center);

  final String playerId;
  final bool isLocal;

  PlayerState? state;
  late TextComponent _nameText;
  late RectangleComponent _hpBack;
  late RectangleComponent _hpFront;

  @override
  Future<void> onLoad() async {
    _nameText = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(32, -18),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );

    _hpBack = RectangleComponent(
      size: Vector2(54, 6),
      position: Vector2(5, -6),
      paint: Paint()..color = Colors.black54,
    );

    _hpFront = RectangleComponent(
      size: Vector2(54, 6),
      position: Vector2(5, -6),
      paint: Paint()..color = isLocal ? Colors.cyanAccent : Colors.redAccent,
    );

    add(_hpBack);
    add(_hpFront);
    add(_nameText);
  }

  Future<void> loadAnimations(String colorName) async {
    final image = await game.images.load('sprites/astronaut_$colorName.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(48, 48));

    animations = {
      'idle': sheet.createAnimation(row: 0, stepTime: .18, to: 4),
      'run': sheet.createAnimation(row: 1, stepTime: .12, to: 4),
      'jump': sheet.createAnimation(row: 2, stepTime: .18, to: 4),
      'punch': sheet.createAnimation(row: 3, stepTime: .08, to: 4),
      'hurt': sheet.createAnimation(row: 4, stepTime: .12, to: 4),
    };
    current = 'idle';
  }

  void applyState(PlayerState next) {
    state = next;
    position = Vector2(next.x, next.y);
    scale.x = next.facing < 0 ? -1 : 1;

    _nameText.text = next.name;
    _hpFront.size.x = 54 * (next.hp.clamp(0, 100) / 100);

    if (!next.isAlive) {
      opacity = .35;
      current = 'hurt';
      return;
    }

    opacity = 1;
    if (next.isAttacking) {
      current = 'punch';
    } else if (next.vy.abs() > 10) {
      current = 'jump';
    } else if (next.vx.abs() > 10) {
      current = 'run';
    } else {
      current = 'idle';
    }
  }
}
