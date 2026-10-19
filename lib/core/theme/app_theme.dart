import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const surface = Color(0xFFFCF9F8);
  static const surfaceContainerLow = Color(0xFFF6F3F2);
  static const surfaceContainerHigh = Color(0xFFEAE7E7);
  static const text = Color(0xFF1B1B1C);
  static const muted = Color(0xFF424654);
  static const outline = Color(0xFF737785);
  static const blue = Color(0xFF0B57D0);
  static const purple = Color(0xFF9C27B0);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppPalette.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.blue,
      surface: AppPalette.surface,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppPalette.text, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.surface,
      foregroundColor: AppPalette.text,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
  );
}
