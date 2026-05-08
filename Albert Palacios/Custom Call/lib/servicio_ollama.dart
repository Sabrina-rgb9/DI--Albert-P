import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio aislado para comunicarse con Ollama.
/// Así, si mañana cambia la URL o el modelo, solo se toca este archivo.
class ServicioOllama {
  static const String baseUrl = 'http://localhost:11434';

  /// Cambia este modelo si tú tienes otro instalado en Ollama.
  /// Ejemplos: granite3.2:2b, granite3.3:2b, llama3.2, mistral.
  static const String modeloChat = 'granite3.2:2b';

  static Future<Map<String, dynamic>> chatConHerramientas({
    required String prompt,
    required List<Map<String, dynamic>> mensajes,
    required List<dynamic> herramientas,
  }) async {
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': modeloChat,
            'stream': false,
            'messages': mensajes,
            'tools': herramientas,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (respuesta.statusCode != 200) {
      throw Exception('Ollama respondió con error ${respuesta.statusCode}: ${respuesta.body}');
    }

    return jsonDecode(respuesta.body) as Map<String, dynamic>;
  }

  /// Comprueba si Ollama está abierto en localhost:11434.
  static Future<bool> comprobarConexion() async {
    try {
      final respuesta = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
