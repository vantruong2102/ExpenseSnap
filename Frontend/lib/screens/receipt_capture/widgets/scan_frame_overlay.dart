import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Four corner guides + dashed alignment lines drawn over the camera preview
/// (Figma node 1:44 "Four Corner Framing Guides").
class ScanFrameOverlay extends StatelessWidget {
  const ScanFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _CornerPainter())),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 192, child: _WhiteDashedLine()),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CĂN VUÔNG VẮN BIÊN LAI',
                      style: AppTheme.monoLabel.copyWith(color: const Color(0xE6FFFFFF), letterSpacing: 0.22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(width: 192, child: _WhiteDashedLine()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteDashedLine extends StatelessWidget {
  const _WhiteDashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 1, child: CustomPaint(painter: _DashPainter()));
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x66FFFFFF);
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 3, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const length = 32.0;
    final paint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final corners = [
      [const Offset(0, length), Offset.zero, const Offset(length, 0)],
      [Offset(w - length, 0), Offset(w, 0), Offset(w, length)],
      [Offset(0, h - length), Offset(0, h), Offset(length, h)],
      [Offset(w - length, h), Offset(w, h), Offset(w, h - length)],
    ];
    for (final points in corners) {
      final path = Path()
        ..moveTo(points[0].dx, points[0].dy)
        ..lineTo(points[1].dx, points[1].dy)
        ..lineTo(points[2].dx, points[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
