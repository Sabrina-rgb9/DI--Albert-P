import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'figuras.dart';
import 'herramientas_ia.dart';
import 'servicio_ollama.dart';

class MensajeChat {
  final String texto;
  final bool esUsuario;
  final DateTime fecha;

  MensajeChat({required this.texto, required this.esUsuario, required this.fecha});
}

/// Estado principal de la app.
/// Extiende ChangeNotifier para que las pantallas se actualicen automáticamente
/// cuando cambia la lista de figuras, el chat o la selección.
class EstadoApp extends ChangeNotifier {
  final List<FiguraCanvas> figuras = [];
  final List<MensajeChat> mensajes = [];

  bool cargando = false;
  int? indiceSeleccionado;
  double anchoCanvas = 0;
  double altoCanvas = 0;

  FiguraCanvas? get figuraSeleccionada {
    if (indiceSeleccionado == null) return null;
    if (indiceSeleccionado! < 0 || indiceSeleccionado! >= figuras.length) return null;
    return figuras[indiceSeleccionado!];
  }

  void _setCargando(bool valor) {
    cargando = valor;
    notifyListeners();
  }

  void agregarFigura(FiguraCanvas figura) {
    figuras.add(figura);
    notifyListeners();
  }

  void borrarSeleccionada() {
    if (indiceSeleccionado == null) return;
    figuras.removeAt(indiceSeleccionado!);
    indiceSeleccionado = null;
    notifyListeners();
  }

  void seleccionarFigura(int indice) {
    indiceSeleccionado = indice;
    notifyListeners();
  }

  void quitarSeleccion() {
    indiceSeleccionado = null;
    notifyListeners();
  }

  /// Detecta si el usuario hizo clic sobre alguna figura.
  /// Recorremos al revés para seleccionar primero la que esté encima.
  void seleccionarEnPosicion(Offset punto) {
    for (var i = figuras.length - 1; i >= 0; i--) {
      if (_puntoDentroDeFigura(punto, figuras[i])) {
        seleccionarFigura(i);
        return;
      }
    }
    quitarSeleccion();
  }

  bool _puntoDentroDeFigura(Offset punto, FiguraCanvas figura) {
    if (figura is CirculoFigura) {
      return (punto - figura.centro).distance <= figura.radio;
    }
    if (figura is RectanguloFigura) {
      return Rect.fromPoints(figura.esquinaInicial, figura.esquinaFinal).contains(punto);
    }
    if (figura is LineaFigura) {
      return _distanciaPuntoLinea(punto, figura.inicio, figura.fin) <= 10;
    }
    if (figura is TextoFigura) {
      return Rect.fromLTWH(figura.posicion.dx, figura.posicion.dy, 120, 40).contains(punto);
    }
    return false;
  }

  double _distanciaPuntoLinea(Offset punto, Offset inicio, Offset fin) {
    final dx = fin.dx - inicio.dx;
    final dy = fin.dy - inicio.dy;
    if (dx == 0 && dy == 0) return (punto - inicio).distance;

    final t = ((punto.dx - inicio.dx) * dx + (punto.dy - inicio.dy) * dy) / (dx * dx + dy * dy);
    final limitado = t.clamp(0.0, 1.0);
    final cercano = Offset(inicio.dx + limitado * dx, inicio.dy + limitado * dy);
    return (punto - cercano).distance;
  }

  /// Actualiza propiedades desde el panel lateral.
  /// En vez de modificar objetos, se reemplaza la figura por una nueva.
  void actualizarPropiedad(int indice, String propiedad, String valor) {
    if (indice < 0 || indice >= figuras.length) return;
    final figura = figuras[indice];

    if (figura is CirculoFigura) {
      figuras[indice] = CirculoFigura(
        centro: Offset(
          propiedad == 'x' ? _double(valor) : figura.centro.dx,
          propiedad == 'y' ? _double(valor) : figura.centro.dy,
        ),
        radio: propiedad == 'radio' ? _double(valor) : figura.radio,
        color: propiedad == 'color' ? _color(valor) : figura.color,
        grosor: propiedad == 'grosor' ? _double(valor) : figura.grosor,
        degradado: figura.degradado,
      );
    } else if (figura is RectanguloFigura) {
      figuras[indice] = RectanguloFigura(
        esquinaInicial: Offset(
          propiedad == 'x1' ? _double(valor) : figura.esquinaInicial.dx,
          propiedad == 'y1' ? _double(valor) : figura.esquinaInicial.dy,
        ),
        esquinaFinal: Offset(
          propiedad == 'x2' ? _double(valor) : figura.esquinaFinal.dx,
          propiedad == 'y2' ? _double(valor) : figura.esquinaFinal.dy,
        ),
        color: propiedad == 'color' ? _color(valor) : figura.color,
        grosor: propiedad == 'grosor' ? _double(valor) : figura.grosor,
        degradado: figura.degradado,
      );
    } else if (figura is LineaFigura) {
      figuras[indice] = LineaFigura(
        inicio: Offset(
          propiedad == 'inicioX' ? _double(valor) : figura.inicio.dx,
          propiedad == 'inicioY' ? _double(valor) : figura.inicio.dy,
        ),
        fin: Offset(
          propiedad == 'finX' ? _double(valor) : figura.fin.dx,
          propiedad == 'finY' ? _double(valor) : figura.fin.dy,
        ),
        color: propiedad == 'color' ? _color(valor) : figura.color,
        grosor: propiedad == 'grosor' ? _double(valor) : figura.grosor,
      );
    } else if (figura is TextoFigura) {
      figuras[indice] = TextoFigura(
        texto: propiedad == 'texto' ? valor : figura.texto,
        posicion: Offset(
          propiedad == 'x' ? _double(valor) : figura.posicion.dx,
          propiedad == 'y' ? _double(valor) : figura.posicion.dy,
        ),
        color: propiedad == 'color' ? _color(valor) : figura.color,
        tamano: propiedad == 'tamano' ? _double(valor) : figura.tamano,
        peso: figura.peso,
        estilo: figura.estilo,
      );
    }

    notifyListeners();
  }

  /// Envía el texto del usuario a Ollama.
  /// Si el modelo devuelve tool_calls, se ejecutan y se dibujan figuras.
  Future<void> enviarPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    mensajes.add(MensajeChat(texto: prompt, esUsuario: true, fecha: DateTime.now()));
    _setCargando(true);

    final sistema = '''
Eres un asistente que dibuja en un canvas de Flutter.
Debes usar las herramientas disponibles siempre que el usuario pida dibujar algo.
El canvas mide ${anchoCanvas.toStringAsFixed(0)} x ${altoCanvas.toStringAsFixed(0)} píxeles.
Colores válidos: red, blue, green, yellow, black, white, orange, purple, pink, brown, grey.
''';

    try {
      final respuesta = await ServicioOllama.chatConHerramientas(
        prompt: prompt,
        herramientas: herramientasIa,
        mensajes: [
          {'role': 'system', 'content': sistema},
          {'role': 'user', 'content': prompt},
        ],
      );

      final message = respuesta['message'];
      final llamadas = message is Map ? message['tool_calls'] : null;

      if (llamadas is List && llamadas.isNotEmpty) {
        final nombres = <String>[];
        for (final llamada in llamadas) {
          if (llamada is Map && llamada['function'] is Map) {
            final funcion = _limpiarMapa(llamada['function'] as Map);
            nombres.add(funcion['name'].toString());
            await _ejecutarFuncion(funcion);
          }
        }
        mensajes.add(MensajeChat(
          texto: 'Funciones ejecutadas: ${nombres.join(', ')}',
          esUsuario: false,
          fecha: DateTime.now(),
        ));
      } else {
        final contenido = message is Map ? message['content']?.toString() : null;
        mensajes.add(MensajeChat(
          texto: contenido?.isNotEmpty == true ? contenido! : 'No se recibió ninguna función.',
          esUsuario: false,
          fecha: DateTime.now(),
        ));
      }
    } catch (e) {
      mensajes.add(MensajeChat(
        texto: 'Error conectando con Ollama: $e',
        esUsuario: false,
        fecha: DateTime.now(),
      ));
    } finally {
      _setCargando(false);
    }
  }

  Future<void> _ejecutarFuncion(Map<String, dynamic> funcion) async {
    final nombre = funcion['name'].toString();
    final argsRaw = funcion['arguments'];
    final args = await _normalizarArgumentos(argsRaw);

    switch (nombre) {
      case 'dibujar_circulo':
        agregarFigura(CirculoFigura(
          centro: Offset(_double(args['x'], 100), _double(args['y'], 100)),
          radio: max(1, _double(args['radio'], 30)),
          color: _color(args['color']),
          grosor: _double(args['grosor'], 2),
          degradado: _listaColores(args['degradado']),
        ));
        break;
      case 'dibujar_linea':
        agregarFigura(LineaFigura(
          inicio: Offset(_double(args['inicioX'], 20), _double(args['inicioY'], 20)),
          fin: Offset(_double(args['finX'], 180), _double(args['finY'], 180)),
          color: _color(args['color']),
          grosor: _double(args['grosor'], 2),
        ));
        break;
      case 'dibujar_rectangulo':
        agregarFigura(RectanguloFigura(
          esquinaInicial: Offset(_double(args['x1'], 50), _double(args['y1'], 50)),
          esquinaFinal: Offset(_double(args['x2'], 200), _double(args['y2'], 150)),
          color: _color(args['color']),
          grosor: _double(args['grosor'], 2),
          degradado: _listaColores(args['degradado']),
        ));
        break;
      case 'dibujar_texto':
        agregarFigura(TextoFigura(
          texto: args['texto']?.toString() ?? 'Texto',
          posicion: Offset(_double(args['x'], 100), _double(args['y'], 100)),
          color: _color(args['color']),
          tamano: _double(args['tamano'], 20),
          peso: _peso(args['peso']),
          estilo: _estilo(args['estilo']),
        ));
        break;
    }
  }

  /// Algunos modelos devuelven arguments como String JSON y otros como Map.
  /// Esta función acepta ambos formatos.
  Future<Map<String, dynamic>> _normalizarArgumentos(dynamic raw) async {
    if (raw is Map) return _limpiarMapa(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return _limpiarMapa(decoded);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> _limpiarMapa(Map mapa) {
    return mapa.map((key, value) => MapEntry(key.toString().trim(), value));
  }

  double _double(dynamic value, [double defecto = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? defecto;
    return defecto;
  }

  Color _color(dynamic value) {
    final texto = value?.toString().toLowerCase().trim();
    switch (texto) {
      case 'rojo':
      case 'red':
        return Colors.red;
      case 'azul':
      case 'blue':
        return Colors.blue;
      case 'verde':
      case 'green':
        return Colors.green;
      case 'amarillo':
      case 'yellow':
        return Colors.yellow;
      case 'blanco':
      case 'white':
        return Colors.white;
      case 'naranja':
      case 'orange':
        return Colors.orange;
      case 'morado':
      case 'purple':
        return Colors.purple;
      case 'rosa':
      case 'pink':
        return Colors.pink;
      case 'marron':
      case 'brown':
        return Colors.brown;
      case 'gris':
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'negro':
      case 'black':
      default:
        return Colors.black;
    }
  }

  List<Color>? _listaColores(dynamic value) {
    if (value is! List) return null;
    return value.map(_color).toList();
  }

  FontWeight _peso(dynamic value) {
    final texto = value?.toString().toLowerCase();
    if (texto == 'bold' || texto == 'negrita') return FontWeight.bold;
    if (texto == 'light') return FontWeight.w300;
    return FontWeight.normal;
  }

  FontStyle _estilo(dynamic value) {
    final texto = value?.toString().toLowerCase();
    return texto == 'italic' || texto == 'cursiva' ? FontStyle.italic : FontStyle.normal;
  }
}
