import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player_state.dart';
import '../services/network_client.dart';
import 'components/arena_platform_component.dart';
import 'components/player_component.dart';

/// Juego principal de Punch Star Arena.
///
/// El cliente NO decide la vida ni las posiciones finales: solo manda inputs.
/// El servidor calcula física, golpes y estado de la partida para que todos los
/// jugadores vean lo mismo.
class PunchStarGame extends FlameGame with KeyboardEvents {
  PunchStarGame({
    required this.network,
    required this.localPlayerId,
  });

  final NetworkClient network;
  final String localPlayerId;

  static final Vector2 worldSize = Vector2(960, 540);
  static final Vector2 platformPosition = Vector2(210, 392);
  static final Vector2 platformSize = Vector2(540, 92);

  final Map<String, PlayerComponent> _players = {};
  StreamSubscription? _sub;

  bool left = false;
  bool right = false;
  bool jump = false;
  bool attack = false;

  late SpriteComponent _background;
  late ArenaPlatformComponent _platform;

  @override
  Color backgroundColor() => const Color(0xFF050617);

  @override
  Future<void> onLoad() async {
    await images.loadAll([
      'backgrounds/space.png',
      'effects/hit.png',
    ]);

    // El mundo se mantiene a 960x540. Flame escala la cámara al tamaño real de
    // la ventana, así todos los clientes ven la arena igual.
    camera.viewfinder.visibleGameSize = worldSize;
    camera.viewfinder.position = worldSize / 2;
    camera.viewfinder.anchor = Anchor.center;

    _background = SpriteComponent(
      sprite: await loadSprite('backgrounds/space.png'),
      size: worldSize,
      position: Vector2.zero(),
      priority: -10,
    );
    world.add(_background);

    _platform = ArenaPlatformComponent(
      position: platformPosition,
      size: platformSize,
    )..priority = -1;
    world.add(_platform);

    _sub = network.messages.listen(_handleMessage);
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
        )..priority = 10;
        _players[player.id] = component;
        world.add(component);
        component.loadAnimations(player.color).then((_) => component.applyState(player));
      } else {
        existing.applyState(player);
      }
    }

    // Elimina jugadores desconectados.
    final toRemove = _players.keys.where((id) => !seen.contains(id)).toList();
    for (final id in toRemove) {
      _players[id]?.removeFromParent();
      _players.remove(id);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Se mandan inputs, no coordenadas. Así evitamos trampas simples y el
    // servidor mantiene una simulación autoritativa.
    network.sendInput(left: left, right: right, jump: jump, attack: attack);

    // El golpe es una pulsación puntual. Mantener J pulsado no debe pegar cada
    // frame; el servidor además aplica cooldown.
    attack = false;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    left = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    right = keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight);
    jump = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp);

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyJ || event.logicalKey == LogicalKeyboardKey.enter)) {
      attack = true;
    }

    return KeyEventResult.handled;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final local = _players[localPlayerId]?.state;
    final hp = local?.hp ?? 100;
    final alive = local?.isAlive ?? true;

    final label = alive
        ? 'HP: $hp   Jugadores: ${_players.length}   A/D mover · W/Espacio saltar · J/Enter puñetazo'
        : 'ELIMINADO   Jugadores: ${_players.length}';

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 40);
    painter.paint(canvas, const Offset(18, 16));
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }
}
