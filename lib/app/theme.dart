import 'package:flutter/material.dart';

abstract final class AppColors {
  static const green = Color(0xFF079447);
  static const deepGreen = Color(0xFF067A3B);
  static const paleGreen = Color(0xFFEAF7EF);
  static const teal = Color(0xFF0794A0);
  static const purple = Color(0xFF7446B8);
  static const orange = Color(0xFFFF9500);
  static const navy = Color(0xFF08142C);
  static const slate = Color(0xFF657087);
  static const line = Color(0xFFE2E6EA);
  static const background = Color(0xFFFCFDFC);
  static const card = Colors.white;
}

abstract final class ProfitTrackTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Arial',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),
      dividerColor: AppColors.line,
      cardTheme: const CardThemeData(
        color: AppColors.card,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}
