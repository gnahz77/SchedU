import 'package:flutter/material.dart';
import 'colors.dart';
import 'shape.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color scheme
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryColor,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.primaryLighter,
      onTertiary: AppColors.primaryDarker,
      background: AppColors.background,
      onBackground: AppColors.onBackground,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      outline: AppColors.outline,
      shadow: Colors.black.withOpacity(0.1),
      inverseSurface: AppColors.primaryDarker,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.primaryLighter,
    ),

    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.onBackground,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.onBackground,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.onBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onBackground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.onBackground,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.onBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.onBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onPrimary,
      ),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    // Card theme
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 2,
      shape: AppShapes.defaultCardShape,
      margin: const EdgeInsets.all(8.0),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onPrimary,
        backgroundColor: AppColors.primaryColor,
        shape: AppShapes.defaultButtonShape,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        shape: AppShapes.defaultButtonShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        shape: AppShapes.defaultButtonShape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input themes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: AppShapes.inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppShapes.inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppShapes.inputBorderRadius,
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Floating Action Button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 24,
    ),

    // Bottom Navigation Bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primaryColor,
      inactiveTrackColor: AppColors.primaryLighter.withOpacity(0.3),
      thumbColor: AppColors.primaryColor,
      overlayColor: AppColors.primaryColor.withOpacity(0.2),
      valueIndicatorColor: AppColors.primaryDark,
      valueIndicatorTextStyle: const TextStyle(color: AppColors.onPrimary),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor;
        }
        return AppColors.surfaceVariant;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor;
        }
        return AppColors.surface;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryLight.withOpacity(0.5);
        }
        return AppColors.onSurfaceVariant.withOpacity(0.3);
      }),
    ),

    // Tab bar theme
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primaryColor,
      unselectedLabelColor: AppColors.onSurfaceVariant,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color scheme
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryColor,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.primaryLighter,
      onTertiary: AppColors.primaryDark,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkOnBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceVariant: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      outline: AppColors.darkOutline,
      shadow: Colors.black.withOpacity(0.3),
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.onSurface,
      inversePrimary: AppColors.primaryDark,
    ),

    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkOnBackground,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.darkOnBackground,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.darkOnBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkOnBackground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkOnBackground,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkOnSurfaceVariant,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.darkOnBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.darkOnBackground,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.darkOnSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onPrimary,
      ),
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    // Card theme
    cardTheme: CardTheme(
      color: AppColors.darkSurface,
      elevation: 3,
      shape: AppShapes.defaultCardShape,
      margin: const EdgeInsets.all(8.0),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.onPrimary,
        backgroundColor: AppColors.primaryColor,
        shape: AppShapes.defaultButtonShape,
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        shape: AppShapes.defaultButtonShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        shape: AppShapes.defaultButtonShape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input themes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: AppShapes.inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppShapes.inputBorderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppShapes.inputBorderRadius,
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
    ),

    // Floating Action Button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.darkOutline,
      thickness: 1,
      space: 24,
    ),

    // Bottom Navigation Bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.darkOnSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primaryColor,
      inactiveTrackColor: AppColors.primaryDark.withOpacity(0.4),
      thumbColor: AppColors.primaryLight,
      overlayColor: AppColors.primaryLight.withOpacity(0.2),
      valueIndicatorColor: AppColors.primaryDark,
      valueIndicatorTextStyle: const TextStyle(color: AppColors.onPrimary),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor;
        }
        return AppColors.darkSurfaceVariant;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryLight;
        }
        return AppColors.darkSurface;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor.withOpacity(0.5);
        }
        return AppColors.darkOnSurfaceVariant.withOpacity(0.3);
      }),
    ),

    // Tab bar theme
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primaryLight,
      unselectedLabelColor: AppColors.darkOnSurfaceVariant,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
      ),
    ),
  );

  /// 自定义方法用于创建日程项主题
  static BoxDecoration lessonTileDecoration = BoxDecoration(
    color: AppColors.lessonTile,
    borderRadius: AppShapes.lessonTileBorderRadius,
    border: Border.all(
      color: AppColors.lessonTileBorder,
      width: 1.0,
    ),
  );

  /// 深色主题的课程项装饰
  static BoxDecoration darkLessonTileDecoration = BoxDecoration(
    color: AppColors.darkLessonTile,
    borderRadius: AppShapes.lessonTileBorderRadius,
    border: Border.all(
      color: AppColors.darkLessonTileBorder,
      width: 1.0,
    ),
  );

  /// 自定义方法用于创建今天指示器装饰
  static BoxDecoration todayIndicatorDecoration = BoxDecoration(
    color: AppColors.todayIndicator.withOpacity(0.15),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(
      color: AppColors.todayIndicator,
      width: 1.5,
    ),
  );

  /// 深色主题的今天指示器装饰
  static BoxDecoration darkTodayIndicatorDecoration = BoxDecoration(
    color: AppColors.darkTodayIndicator.withOpacity(0.25),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(
      color: AppColors.darkTodayIndicator,
      width: 1.5,
    ),
  );

  /// 根据当前主题亮暗获取对应的课程项装饰
  static BoxDecoration getLessonTileDecoration(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lessonTileDecoration
        : darkLessonTileDecoration;
  }

  /// 根据当前主题亮暗获取对应的今天指示器装饰
  static BoxDecoration getTodayIndicatorDecoration(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? todayIndicatorDecoration
        : darkTodayIndicatorDecoration;
  }
}