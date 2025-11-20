import 'package:flutter/material.dart';

class AppColors {
  // Primary Mars Green color
  static const Color primaryColor = Color(0xFF008C8C);

  // Light variants of primary color
  static const Color primaryLight = Color(0xFF4FBCBC);
  static const Color primaryLighter = Color(0xFF9FDDDD);

  // Dark variants of primary color
  static const Color primaryDark = Color(0xFF006060);
  static const Color primaryDarker = Color(0xFF004040);

  // Background and surface colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color surfaceVariant = Color(0xFFF0F7F7);

  // Text colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceVariant = Color(0xFF424242);

  // Other utility colors
  static const Color outline = Color(0xFFDCE8E8);
  static const Color error = Color(0xFFB00020);
  static const Color onError = Color(0xFFFFFFFF);

  // Schedule-specific colors
  static const Color lessonTile = Color(0xFFE0F2F2);
  static const Color lessonTileBorder = Color(0xFFB4D9D9);
  static const Color todayIndicator = Color(0xFF008C8C);

  // Dark theme specific colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF242D2D);

  static const Color darkOnBackground = Color(0xFFE6E6E6);
  static const Color darkOnSurface = Color(0xFFE6E6E6);
  static const Color darkOnSurfaceVariant = Color(0xFFB8B8B8);

  static const Color darkOutline = Color(0xFF3A4D4D);

  // Dark theme schedule-specific colors
  static const Color darkLessonTile = Color(0xFF1C3333);
  static const Color darkLessonTileBorder = Color(0xFF2D5151);
  static const Color darkTodayIndicator = Color(0xFF00A3A3);

  // Preset palette for lesson tiles (used to vary course background colors)
  static const List<Color> lessonTilePalette = [
    Color(0xFFB3E5FC),
    Color(0xFFB2DFDB),
    Color(0xFFFFF59D),
    Color(0xFFFFCCBC),
    Color(0xFFD1C4E9),
    Color(0xFFE6EE9C),
    Color(0xFF81D4FA),
    Color(0xFFFFAB91),
    Color(0xFFC5E1A5),
    Color(0xFFFFF176),
    Color(0xFFB39DDB),
    Color(0xFF80CBC4),
  ];

  // Dark theme counterparts for lesson tiles (indexes align with light palette)
  static const List<Color> darkLessonTilePalette = [
    Color(0xFF274C5E),
    Color(0xFF1D4B44),
    Color(0xFF5C521F),
    Color(0xFF5E3A2C),
    Color(0xFF493D63),
    Color(0xFF485227),
    Color(0xFF1F4A63),
    Color(0xFF5B2F24),
    Color(0xFF3C4D29),
    Color(0xFF4F471C),
    Color(0xFF34294E),
    Color(0xFF1F4B46),
  ];
}