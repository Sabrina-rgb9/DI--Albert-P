import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../../models/player_state.dart';

/// Representa visualmente a un jugador.
///
/// La posición, vida, dirección y ataque vienen del servidor. Aquí solo hacemos
/// suavizado visual, animaciones y HUD encima del personaje.
class PlayerComponent extends SpriteAnimationGroupComponent<String> with HasGameRef {
  PlayerComponent({
    required this.playerId,
    required this.isLocal,
  }) : super(size: Vector2(82, 82), anchor: Anchor.center);

  final String playerId;
  final bool isLocal;

  PlayerState? state;
  Vector2? _targetPosition;

  late TextComponent _nameText;
  late TextComponent _hpText;
  late RectangleComponent _hpBack;
  late RectangleComponent _hpFront;

  @override
  Future<void> onLoad() async {
    _nameText = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(41, -28),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 13,
          color: isLocal ? Colors.cyanAccent : Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
    );

    _hpBack = RectangleComponent(
      size: Vector2(62, 8),
      position: Vector2(10, -14),
      paint: Paint()..color = const Color(0xCC111111),
    );

    _hpFront = RectangleComponent(
      size: Vector2(62, 8),
      position: Vector2(10, -14),
      paint: Paint()..color = isLocal ? Colors.cyanAccent : Colors.lightGreenAccent,
    );

    _hpText = TextComponent(
      text: '100',
      anchor: Anchor.center,
      position: Vector2(41, -2),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
    );

    add(_hpBack);
    add(_hpFront);
    add(_nameText);
    add(_hpText);
  }

  Future<void> loadAnimations(String colorName) async {
    final image = await game.images.load('sprites/astronaut_$colorName.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2(48, 48));

    animations = {
      'idle': sheet.createAnimation(row: 0, stepTime: .18, to: 4),
      'run': sheet.createAnimation(row: 1, stepTime: .10, to: 4),
      'jump': sheet.createAnimation(row: 2, stepTime: .18, to: 4),
      'punch': sheet.createAnimation(row: 3, stepTime: .07, to: 4),
      'hurt': sheet.createAnimation(row: 4, stepTime: .10, to: 4),
    };
    current = 'idle';
  }

  @override
  void update(double dt) {
    super.update(dt);

    final target = _targetPosition;
    if (target != null) {
      // Interpolación simple para que el movimiento online no vaya a saltos.
      position = position + (target - position) * (dt * 14).clamp(0, 1);
    }
  }

  void applyState(PlayerState next) {
    state = next;
    _targetPosition = Vector2(next.x, next.y);

    // Primera actualización: colocar sin interpolar para evitar aparecer fuera.
    if (position == Vector2.zero()) {
      position = _targetPosition!;
    }

    scale.x = next.facing < 0 ? -1 : 1;

    _nameText.text = next.name;
    _hpText.text = '${next.hp}';
    _hpFront.size.x = 62 * (next.hp.clamp(0, 100) / 100);

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
