import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0050CB);
  static const primaryStrong = Color(0xFF0066FF);
  static const secondary = Color(0xFF6FCEFE);
  static const accent = Color(0xFFB3C5FF);
  static const deepBlue = Color(0xFF1F4AA8);

  static const lightBg = Color(0xFFF7F9FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightLine = Color(0xFFCFE0FF);
  static const lightText = Color(0xFF191C1E);
  static const lightMuted = Color(0xFF5D6B82);

  static const darkBg = Color(0xFF0E1525);
  static const darkCard = Color(0xFF121C30);
}

class AppTheme {
  static BoxDecoration glassCard({bool highlight = false}) => BoxDecoration(
        gradient: LinearGradient(
          colors: highlight
              ? [
                  Colors.white.withValues(alpha: 0.72),
                  const Color(0xFFEAF2FF).withValues(alpha: 0.65),
                ]
              : [
                  Colors.white.withValues(alpha: 0.58),
                  const Color(0xFFF6FAFF).withValues(alpha: 0.46),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140050CB),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightCard,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Noto Sans KR',
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.lightText,
            displayColor: AppColors.lightText,
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryStrong, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.42),
        selectedColor: AppColors.accent.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        labelStyle: const TextStyle(
          color: AppColors.lightText,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE3ECFA)),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.secondary,
      brightness: Brightness.dark,
      primary: AppColors.secondary,
      secondary: AppColors.accent,
      surface: AppColors.darkCard,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: 'Noto Sans KR',
    );
  }
}
