import 'package:flutter/material.dart';

/// Clase base de todas las figuras que se pueden pintar en el canvas.
/// Cada figura sabe dibujarse a sí misma usando el objeto [Canvas].
abstract class FiguraCanvas {
  void dibujar(Canvas canvas);

  /// Dibuja una marca visual cuando la figura está seleccionada.
  /// Las subclases pueden sobrescribirlo si necesitan otra forma de selección.
  void dibujarSeleccion(Canvas canvas) {}
}

class LineaFigura extends FiguraCanvas {
  final Offset inicio;
  final Offset fin;
  final Color color;
  final double grosor;

  LineaFigura({
    required this.inicio,
    required this.fin,
    this.color = Colors.black,
    this.grosor = 2,
  });

  @override
  void dibujar(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(inicio, fin, paint);
  }

  @override
  void dibujarSeleccion(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = grosor + 3;
    canvas.drawLine(inicio, fin, paint);
  }
}

class CirculoFigura extends FiguraCanvas {
  final Offset centro;
  final double radio;
  final Color color;
  final double grosor;
  final List<Color>? degradado;

  CirculoFigura({
    required this.centro,
    required this.radio,
    this.color = Colors.black,
    this.grosor = 2,
    this.degradado,
  });

  @override
  void dibujar(Canvas canvas) {
    final paint = Paint();
    final rect = Rect.fromCircle(center: centro, radius: radio);

    // Si hay degradado, se rellena con varios colores.
    // Si no, se rellena con un color normal.
    if (degradado != null && degradado!.isNotEmpty) {
      paint.shader = LinearGradient(colors: degradado!).createShader(rect);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = color;
      paint.style = PaintingStyle.fill;
    }

    canvas.drawCircle(centro, radio, paint);
  }

  @override
  void dibujarSeleccion(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(centro, radio + 5, paint);
  }
}

class RectanguloFigura extends FiguraCanvas {
  final Offset esquinaInicial;
  final Offset esquinaFinal;
  final Color color;
  final double grosor;
  final List<Color>? degradado;

  RectanguloFigura({
    required this.esquinaInicial,
    required this.esquinaFinal,
    this.color = Colors.black,
    this.grosor = 2,
    this.degradado,
  });

  @override
  void dibujar(Canvas canvas) {
    final rect = Rect.fromPoints(esquinaInicial, esquinaFinal);
    final paint = Paint();

    if (degradado != null && degradado!.isNotEmpty) {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: degradado!,
      ).createShader(rect);
      paint.style = PaintingStyle.fill;
    } else {
      paint.color = color;
      paint.strokeWidth = grosor;
      paint.style = PaintingStyle.stroke;
    }

    canvas.drawRect(rect, paint);
  }

  @override
  void dibujarSeleccion(Canvas canvas) {
    final rect = Rect.fromPoints(esquinaInicial, esquinaFinal);
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect.inflate(4), paint);
  }
}

class TextoFigura extends FiguraCanvas {
  final String texto;
  final Offset posicion;
  final Color color;
  final double tamano;
  final FontWeight peso;
  final FontStyle estilo;

  TextoFigura({
    required this.texto,
    required this.posicion,
    this.color = Colors.black,
    this.tamano = 18,
    this.peso = FontWeight.normal,
    this.estilo = FontStyle.normal,
  });

  @override
  void dibujar(Canvas canvas) {
    final span = TextSpan(
      text: texto,
      style: TextStyle(
        color: color,
        fontSize: tamano,
        fontWeight: peso,
        fontStyle: estilo,
      ),
    );

    final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, posicion);
  }

  @override
  void dibujarSeleccion(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(posicion.dx - 3, posicion.dy - 3, 90, 30), paint);
  }
}
