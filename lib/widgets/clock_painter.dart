import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';

class ClockPainter extends CustomPainter {
  final TimeOfDay time;

  ClockPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dessiner le cercle extérieur
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, paint);

    // Dessiner les marques des heures
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final markerLength = i % 3 == 0 ? 8.0 : 4.0;
      final x1 = center.dx + (radius - markerLength) * cos(angle);
      final y1 = center.dy + (radius - markerLength) * sin(angle);
      final x2 = center.dx + radius * cos(angle);
      final y2 = center.dy + radius * sin(angle);

      paint.color = Colors.grey[300]!;
      paint.strokeWidth = 1;

      if (i % 3 == 0) {
        // Ne dessine pas de ligne pour les positions 3, 6, 9 et 12
        final textPainter = TextPainter(
          text: TextSpan(
            text: ((i + 3).toString()),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final numberX =
            center.dx + (radius - 30) * cos(angle) - textPainter.width / 2;
        final numberY =
            center.dy + (radius - 30) * sin(angle) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(numberX, numberY));
      } else {
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }

    // Dessiner les aiguilles
    final hourAngle =
        (time.hour % 12 + time.minute / 60) * 30 * pi / 180 - pi / 2;
    final minuteAngle = time.minute * 6 * pi / 180 - pi / 2;

    // Aiguille des heures
    paint
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.4 * cos(hourAngle),
        center.dy + radius * 0.4 * sin(hourAngle),
      ),
      paint,
    );

    // Aiguille des minutes
    paint
      ..color = Colors.blue
      ..strokeWidth = 3;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.6 * cos(minuteAngle),
        center.dy + radius * 0.6 * sin(minuteAngle),
      ),
      paint,
    );

    // Point central
    paint
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
