import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../models/player_state.dart';
import '../services/network_client.dart';
import 'components/player_component.dart';

class PunchStarGame extends FlameGame with KeyboardEvents {
  PunchStarGame({
    required this.network,
    required this.localPlayerId,
  });

  final NetworkClient network;
  final String localPlayerId;

  final Map<String, PlayerComponent> _players = {};
  StreamSubscription? _sub;

  bool left = false;
  bool right = false;
  bool jump = false;
  bool attack = false;

  late SpriteComponent _background;
  late SpriteComponent _platform;

  @override
  Color backgroundColor() => const Color(0xFF050617);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'backgrounds/space.png',
      'tilesets/space_platform.png',
      'effects/hit.png',
    ]);

    // Fondo espacial.
    _background = SpriteComponent(
      sprite: await loadSprite('backgrounds/space.png'),
      size: size,
      position: Vector2.zero(),
    );
    add(_background);

    // Plataforma central. Es visual; la colisión real la calcula el servidor.
    _platform = SpriteComponent(
      sprite: await loadSprite(
        'tilesets/space_platform.png',
        srcPosition: Vector2(0, 40),
        srcSize: Vector2(128, 24),
      ),
      size: Vector2(720, 135),
      position: Vector2(size.x / 2 - 360, size.y - 165),
    );
    add(_platform);

    _sub = network.messages.listen(_handleMessage);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _background.size = size;
      _platform.position = Vector2(size.x / 2 - 360, size.y - 165);
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (message['type'] != 'state') return;

    final playersJson = message['players'] as List<dynamic>? ?? [];
    final seen = <String>{};

    for (final raw in playersJson) {
      final player = PlayerState.fromJson(raw as Map<String, dynamic>);
      seen.add(player.id);

      final existing = _players[player.id];
      if (existing == null) {
        final component = PlayerComponent(
          playerId: player.id,
          isLocal: player.id == localPlayerId,
        );
        _players[player.id] = component;
        add(component);
        component.loadAnimations(player.color).then((_) {
          component.applyState(player);
        });
      } else {
        existing.applyState(player);
      }
    }

    // Limpia jugadores desconectados.
    final toRemove = _players.keys.where((id) => !seen.contains(id)).toList();
    for (final id in toRemove) {
      _players[id]?.removeFromParent();
      _players.remove(id);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Enviamos input muchas veces por segundo.
    // El servidor decide la posición real para evitar trampas simples.
    network.sendInput(
      left: left,
      right: right,
      jump: jump,
      attack: attack,
    );

    // El ataque solo dura un frame de input para que no golpee infinitamente.
    attack = false;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    left = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    right = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    jump = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp);

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyJ ||
            event.logicalKey == LogicalKeyboardKey.enter)) {
      attack = true;
    }

    return KeyEventResult.handled;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final local = _players[localPlayerId]?.state;
    if (local != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'HP: ${local.hp}   Jugadores: ${_players.length}   J/Enter = Puñetazo',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, const Offset(20, 20));
    }
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }
}
