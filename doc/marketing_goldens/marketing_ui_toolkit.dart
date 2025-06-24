import 'dart:math';

import 'package:flutter/material.dart';

class AngledLinePainter extends CustomPainter {
  AngledLinePainter({
    required this.angleDegrees,
    required this.gap,
    required this.thickness,
    required this.lineColor,
    this.backgroundColor = Colors.transparent,
  });

  final double angleDegrees;
  final double gap;
  final double thickness;
  final Color lineColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(rect);

    // Fill background.
    canvas.drawRect(rect, Paint()..color = backgroundColor);

    // Draw lines.
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = thickness;

    final angleRadians = angleDegrees * pi / 180;

    // Calculate line direction
    final dx = cos(angleRadians);
    final dy = sin(angleRadians);
    final direction = Offset(dx, dy);
    final perpendicular = Offset(-dy, dx); // unit perpendicular vector

    // Calculate diagonal length to cover the canvas
    final diagonal = sqrt(size.width * size.width + size.height * size.height);

    // Center of canvas
    final center = Offset(size.width / 2, size.height / 2);

    // Number of lines needed to cover the canvas
    final numLines = (diagonal / gap).ceil();

    for (int i = -numLines; i <= numLines; i++) {
      final offset = perpendicular * (i * gap);
      final start = center + offset - direction * diagonal;
      final end = center + offset + direction * diagonal;

      canvas.drawLine(start, end, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
