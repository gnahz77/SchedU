import 'package:flutter/material.dart';

class AppShapes {
  // Card shapes
  static final BorderRadius cardBorderRadius = BorderRadius.circular(16.0);
  static final BorderRadius smallCardBorderRadius = BorderRadius.circular(12.0);

  // Button shapes
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(12.0);
  static final BorderRadius smallButtonBorderRadius = BorderRadius.circular(8.0);

  // Input field shapes
  static final BorderRadius inputBorderRadius = BorderRadius.circular(8.0);

  // Schedule-specific shapes
  static final BorderRadius lessonTileBorderRadius = BorderRadius.circular(10.0);
  static final BorderRadius weekdayHeaderBorderRadius = BorderRadius.circular(8.0);

  // Common shape themes
  static ShapeBorder defaultCardShape = RoundedRectangleBorder(
    borderRadius: cardBorderRadius,
  );

  static OutlinedBorder defaultButtonShape = RoundedRectangleBorder(
    borderRadius: buttonBorderRadius,
  );

  // Schedule tile shape
  static ShapeBorder lessonTileShape = RoundedRectangleBorder(
    borderRadius: lessonTileBorderRadius,
    side: const BorderSide(
      color: Color(0xFFB4D9D9),
      width: 1.0,
    ),
  );
}