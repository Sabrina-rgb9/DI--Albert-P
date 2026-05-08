import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../config.dart';
import '../game/punch_star_game.dart';
import '../services/network_client.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Astronauta');
  final _roomController = TextEditingController(text: 'STAR');
  final _serverController = TextEditingController(text: defaultServerUrl);
  final _network = NetworkClient();

  StreamSubscription? _subscription;
  String _status = 'Sin conectar';

  @override
  void dispose() {
    _subscription?.cancel();
    _network.dispose();
    _nameController.dispose();
    _roomController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _joinGame() async {
    setState(() => _status = 'Conectando...');
    await _network.connect(_serverController.text.trim());

    _subscription = _network.messages.listen((message) {
      if (message['type'] == 'welcome') {
        setState(() => _status = 'Conectado. Entrando a la arena...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameWidget(
              game: PunchStarGame(
                network: _network,
                localPlayerId: message['id'] as String,
              ),
            ),
          ),
        );
      } else if (message['type'] == 'error') {
        setState(() => _status = message['message'] as String? ?? 'Error');
      }
    });

    _network.join(
      playerName: _nameController.text.trim().isEmpty
          ? 'Astronauta'
          : _nameController.text.trim(),
      roomCode: _roomController.text.trim().isEmpty
          ? 'STAR'
          : _roomController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06081E), Color(0xFF111A3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Punch Star Arena',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Battle royale espacial 2D · 2 a 8 jugadores'),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre jugador'),
                    ),
                    TextField(
                      controller: _roomController,
                      decoration: const InputDecoration(labelText: 'Código sala'),
                    ),
                    TextField(
                      controller: _serverController,
                      decoration: const InputDecoration(labelText: 'Servidor WebSocket'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _joinGame,
                      icon: const Icon(Icons.sports_martial_arts),
                      label: const Text('Entrar en la arena'),
                    ),
                    const SizedBox(height: 12),
                    Text(_status),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
