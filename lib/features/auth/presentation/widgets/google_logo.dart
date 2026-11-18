import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The four-colour Google "G" drawn in code, for "Continue with Google"
/// buttons (no image asset needed).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = side * 0.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (side - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double rad(double degrees) => degrees * math.pi / 180;

    void arc(Color color, double from, double to) {
      canvas.drawArc(
        rect,
        rad(from),
        rad(to - from),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // Clockwise from the right: blue, green, yellow, red; open at top right.
    arc(_blue, 0, 45);
    arc(_green, 45, 135);
    arc(_yellow, 135, 215);
    arc(_red, 215, 315);

    // Crossbar of the G.
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        center.dx + radius + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
