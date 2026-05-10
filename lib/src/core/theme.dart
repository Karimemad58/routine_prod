import 'package:flutter/material.dart';

class AppTheme {
  // Surfaces
  static const bg = Color(0xFFF5F0EB);
  static const charcoal = Color(0xFF2C2720);
  static const surfaceWhite = Color(0xFFFFFDFA);

  // Pastel category colors
  static const sage = Color(0xFFD8EBE4);
  static const blush = Color(0xFFF5E8E0);
  static const powder = Color(0xFFE0E8F5);
  static const lavender = Color(0xFFF0E8F5);
  static const beige = Color(0xFFEDE8E2);
  static const peach = Color(0xFFF5E0D8);
  static const softGray = Color(0xFFEFEAE4);

  // Text
  static const textPrimary = charcoal;
  static const textSecondary = Color(0xFF9A9088);
  static const textMuted = Color(0xFFB5AFA8);

  // Shadows (soft ambient only)
  static const softShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -8,
    ),
  ];

  static const microShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 14,
      offset: Offset(0, 6),
      spreadRadius: -8,
    ),
  ];

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: sage,
          surface: bg,
          onSurface: textPrimary,
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.1,
            letterSpacing: -0.4,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          headlineSmall: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          bodySmall: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          labelSmall: TextStyle(
            color: textMuted,
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: bg,
          indicatorColor: beige,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 70,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 11,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: textPrimary, size: 22),
          ),
        ),
      );
}
