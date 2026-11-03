import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Small piece of adhesive tape stuck on top of paper cards.
class WashiTape extends StatelessWidget {
  const WashiTape({super.key, this.width = 96, this.height = 20, this.label, this.angleDegrees = -2});

  final double width;
  final double height;
  final String? label;
  final double angleDegrees;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * 3.1415926535 / 180,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.tape,
          border: Border.all(color: const Color(0x141F1D1A)),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [BoxShadow(color: Color(0x08000000), offset: Offset(0, 1), blurRadius: 2)],
        ),
        child: label == null
            ? null
            : Opacity(
                opacity: 0.4,
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 9,
                    letterSpacing: 0.9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
      ),
    );
  }
}
