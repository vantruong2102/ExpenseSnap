import 'package:flutter/material.dart';

/// Color tokens from the ExpenseSnap Figma file ("paper docket" style).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFD64933); // Primary stamp button
  static const Color ink = Color(0xFFAD2B19); // Stamp ink: badges, errors, shutter
  static const Color background = Color(0xFFFFF8F3); // Form screens
  static const Color canvas = Color(0xFFF4F1EA); // Camera & receipt screens
  static const Color paper = Color(0xFFFAF8F5);
  static const Color dock = Color(0xFFFBFAF6);
  static const Color chip = Color(0xFFF3EDE7);
  static const Color avatar = Color(0xFFEDE7E2);
  static const Color textPrimary = Color(0xFF1D1B18);
  static const Color textSecondary = Color(0xFF635E56);
  static const Color textBrown = Color(0xFF59413C);
  static const Color line = Color(0x261D1B18); // rgba(29,27,24,0.15)
  static const Color cardBorder = Color(0x1F1F1D1A); // rgba(31,29,26,0.12)
  static const Color headerBorder = Color(0x4DE1BFB8); // rgba(225,191,184,0.3)
  static const Color softBorder = Color(0x66E1BFB8); // rgba(225,191,184,0.4)
  static const Color tape = Color(0xD9F5F0E1); // rgba(245,240,225,0.85)
  static const Color viewfinder = Color(0xFF161513);
  static const Color statusDot = Color(0xFFFFB4A6);
}

class AppFonts {
  AppFonts._();

  static const String body = 'BeVietnamPro';
  static const String mono = 'SpaceMono';
}

class AppTheme {
  AppTheme._();

  /// Small uppercase "typewriter" labels (Space Mono 11).
  static const TextStyle monoLabel = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 0.55,
    color: AppColors.textSecondary,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F1F1D1A), offset: Offset(0, 4), blurRadius: 12, spreadRadius: -2),
    BoxShadow(color: Color(0x0A1F1D1A), offset: Offset(0, 1), blurRadius: 3),
  ];

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      error: AppColors.ink,
      surface: AppColors.background,
    );
    return ThemeData(
      fontFamily: AppFonts.body,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: AppColors.headerBorder)),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.only(top: 4, bottom: 5),
        hintStyle: TextStyle(color: Color(0x661D1B18)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.line)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textPrimary)),
        errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.ink)),
        focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.ink)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: Color(0x331D1B18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.ink)),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
