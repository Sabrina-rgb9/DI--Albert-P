import 'package:flutter/rendering.dart';
import 'figuras.dart';

/// CustomPainter encargado de pintar todas las figuras.
/// Flutter llama a paint cada vez que hay que redibujar el canvas.
class PintorCanvas extends CustomPainter {
  final List<FiguraCanvas> figuras;
  final int? indiceSeleccionado;

  PintorCanvas({required this.figuras, required this.indiceSeleccionado});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < figuras.length; i++) {
      figuras[i].dibujar(canvas);

      // Si esta figura está seleccionada, se pinta una marca azul encima.
      if (indiceSeleccionado == i) {
        figuras[i].dibujarSeleccion(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
