import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Plataforma principal de la arena.
///
/// En la v1 era un sprite muy simple. En esta v2 se dibuja con Canvas para que
/// siempre quede centrada, con bordes claros y un aspecto más parecido a una
/// plataforma espacial tipo Smash Bros.
class ArenaPlatformComponent extends PositionComponent {
  ArenaPlatformComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final top = Rect.fromLTWH(0, 0, size.x, size.y * .72);
    final bottom = Rect.fromLTWH(20, size.y * .58, size.x - 40, size.y * .42);

    final bodyPaint = Paint()..color = const Color(0xFF26304A);
    final sidePaint = Paint()..color = const Color(0xFF111827);
    final borderPaint = Paint()
      ..color = const Color(0xFF8BD7FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final lightPaint = Paint()..color = const Color(0xFF66E7FF);
    final shadowPaint = Paint()..color = const Color(0x55000000);

    // Sombra flotante bajo la plataforma.
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottom.translate(0, 10), const Radius.circular(14)),
      shadowPaint,
    );

    // Cuerpo superior y parte inferior.
    canvas.drawRRect(
      RRect.fromRectAndRadius(top, const Radius.circular(10)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottom, const Radius.circular(16)),
      sidePaint,
    );

    // Placas metálicas para que parezca tileset.
    final tileW = size.x / 8;
    for (var i = 0; i < 8; i++) {
      final x = i * tileW;
      final plate = Path()
        ..moveTo(x + 5, 6)
        ..lineTo(x + tileW - 6, 6)
        ..lineTo(x + tileW - 14, top.height - 8)
        ..lineTo(x + 14, top.height - 8)
        ..close();
      canvas.drawPath(plate, Paint()..color = i.isEven ? const Color(0xFF34405F) : const Color(0xFF303A56));
      canvas.drawLine(Offset(x + tileW - 4, 8), Offset(x + tileW + 10, top.height - 8), Paint()..color = const Color(0xFF151B2E)..strokeWidth = 4);
    }

    // Línea superior luminosa.
    canvas.drawLine(const Offset(12, 6), Offset(size.x - 12, 6), lightPaint..strokeWidth = 4);

    // Dos luces decorativas inferiores.
    for (final x in [size.x * .23, size.x * .72]) {
      final lightRect = Rect.fromCenter(center: Offset(x, size.y * .76), width: 36, height: 32);
      canvas.drawRRect(RRect.fromRectAndRadius(lightRect, const Radius.circular(6)), Paint()..color = const Color(0xFF0B2238));
      canvas.drawRRect(RRect.fromRectAndRadius(lightRect.deflate(8), const Radius.circular(4)), Paint()..color = const Color(0xFF00AEEF));
    }

    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(10)), borderPaint);
  }
}
