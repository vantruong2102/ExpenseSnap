import 'package:flutter/material.dart';

/// Horizontal dashed "perforation" line used across the receipt-style cards.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.color = const Color(0x2E1F1D1A), this.dashWidth = 4, this.gap = 3});

  final Color color;
  final double dashWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(color, dashWidth, gap)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color, this.dashWidth, this.gap);

  final Color color;
  final double dashWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += dashWidth + gap) {
      canvas.drawLine(Offset(x, 0.5), Offset((x + dashWidth).clamp(0, size.width), 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashWidth != dashWidth || oldDelegate.gap != gap;
}
