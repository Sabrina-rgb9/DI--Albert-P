import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Clase encargada de hablar con el servidor.
/// El resto de la app no necesita saber cómo funciona WebSocket internamente.
class NetworkClient {
  WebSocketChannel? _channel;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messages.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (raw) {
        try {
          final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
          _messages.add(decoded);
        } catch (_) {
          // Ignoramos mensajes mal formados para que el cliente no crashee.
        }
      },
      onDone: () {
        _channel = null;
      },
      onError: (_) {
        _channel = null;
      },
    );
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(message));
  }

  void join({required String playerName, required String roomCode}) {
    send({
      'type': 'join',
      'name': playerName,
      'roomCode': roomCode,
    });
  }

  void sendInput({
    required bool left,
    required bool right,
    required bool jump,
    required bool attack,
  }) {
    send({
      'type': 'input',
      'left': left,
      'right': right,
      'jump': jump,
      'attack': attack,
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messages.close();
  }
}
