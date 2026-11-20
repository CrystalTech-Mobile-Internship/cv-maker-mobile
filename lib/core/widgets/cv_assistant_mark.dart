import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The app's own assistant symbol: a CV page with a small spark in the
/// corner. Used wherever the writing assistant is offered, so it reads as
/// "help with my CV" rather than a generic robot.
class CvAssistantMark extends StatelessWidget {
  const CvAssistantMark({super.key, this.size = 24, this.color});

  final double size;

  /// Defaults to the surrounding icon colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(resolved)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Own layer so the gap around the spark clears only this drawing.
    canvas.saveLayer(Offset.zero & size, Paint());
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Page with a folded top-right corner.
    final left = s * 0.14;
    final top = s * 0.12;
    final right = s * 0.70;
    final bottom = s * 0.90;
    final fold = s * 0.16;
    final page = Path()
      ..moveTo(left + s * 0.06, top)
      ..lineTo(right - fold, top)
      ..lineTo(right, top + fold)
      ..lineTo(right, bottom - s * 0.06)
      ..quadraticBezierTo(right, bottom, right - s * 0.06, bottom)
      ..lineTo(left + s * 0.06, bottom)
      ..quadraticBezierTo(left, bottom, left, bottom - s * 0.06)
      ..lineTo(left, top + s * 0.06)
      ..quadraticBezierTo(left, top, left + s * 0.06, top);
    canvas.drawPath(page, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(right - fold, top)
        ..lineTo(right - fold, top + fold)
        ..lineTo(right, top + fold),
      stroke,
    );

    // Profile dot and text lines.
    final fill = Paint()..color = color;
    canvas.drawCircle(Offset(left + s * 0.15, top + s * 0.20), s * 0.06, fill);
    for (final (y, end) in [(0.43, 0.56), (0.57, 0.48), (0.71, 0.42)]) {
      canvas.drawLine(
        Offset(left + s * 0.09, s * y),
        Offset(s * end, s * y),
        stroke,
      );
    }

    // Four-point spark at the lower right, overlapping the page edge.
    final c = Offset(s * 0.78, s * 0.72);
    final r = s * 0.20;
    final spark = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final radius = i.isEven ? r : r * 0.32;
      final p = c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      i == 0 ? spark.moveTo(p.dx, p.dy) : spark.lineTo(p.dx, p.dy);
    }
    spark.close();
    // Cut a gap around the spark so it stays readable on the page line.
    canvas.drawPath(
      spark,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.12
        ..blendMode = BlendMode.clear,
    );
    canvas.drawPath(spark, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}
