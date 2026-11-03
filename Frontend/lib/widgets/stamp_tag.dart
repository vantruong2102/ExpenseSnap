import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Rubber-stamp style tag tilted -3°, e.g. "MỚI", "SỔ THUẾ #06".
class StampTag extends StatelessWidget {
  const StampTag(this.text, {super.key, this.fontSize = 12, this.filled = false});

  final String text;
  final double fontSize;

  /// Light pink fill used by the small "ĐÃ QUÉT OCR" style tags.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * 3.1415926535 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: filled ? const Color(0x33FFDAD4) : null,
          border: Border.all(color: filled ? const Color(0x99AD2B19) : AppColors.ink),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.mono,
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
            height: 16 / 12,
            letterSpacing: fontSize * 0.08,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
