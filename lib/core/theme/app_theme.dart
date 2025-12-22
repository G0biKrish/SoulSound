import 'package:flutter/material.dart';
import '../../presentation/providers/theme_providers.dart';

Color _toGrayscale(Color color) {
  final luminance = color.computeLuminance();
  final grayValue = (luminance * 255).round();
  return Color.fromRGBO(grayValue, grayValue, grayValue, 1.0);
}

ThemeData buildThemeData(ThemeState themeState) {
  Color primaryColor = themeState.primaryColor;
  Color secondaryColor = themeState.secondaryColor;
  final brightness = themeState.brightness;
  final isDark = brightness == Brightness.dark;

  // Apply minimal mode (monochrome)
  if (themeState.minimalMode) {
    primaryColor = _toGrayscale(primaryColor);
    secondaryColor = _toGrayscale(secondaryColor);
  }

  // Generate ColorScheme from primary and secondary colors
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: brightness,
    secondary: secondaryColor,
  );

  // Adjust colors for minimal mode
  final adjustedColorScheme = themeState.minimalMode
      ? ColorScheme(
          brightness: brightness,
          primary: _toGrayscale(colorScheme.primary),
          onPrimary: isDark ? Colors.white : Colors.black,
          secondary: _toGrayscale(colorScheme.secondary),
          onSecondary: isDark ? Colors.white : Colors.black,
          error: colorScheme.error,
          onError: colorScheme.onError,
          surface: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
          onSurface: isDark ? Colors.white : Colors.black,
          surfaceContainerHighest:
              isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          onSurfaceVariant: isDark ? Colors.grey[400]! : Colors.grey[700]!,
          outline: isDark ? Colors.grey[700]! : Colors.grey[400]!,
          outlineVariant: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          shadow: Colors.black,
          scrim: Colors.black,
          inverseSurface: isDark ? Colors.white : Colors.black,
          onInverseSurface: isDark ? Colors.black : Colors.white,
          inversePrimary: isDark ? Colors.black : Colors.white,
          tertiary: _toGrayscale(colorScheme.tertiary),
          onTertiary: isDark ? Colors.white : Colors.black,
        )
      : colorScheme;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: adjustedColorScheme,
    primaryColor: primaryColor,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
    fontFamily: 'Inter',
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 2,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      textColor: isDark ? Colors.white : Colors.black,
      iconColor: isDark ? Colors.white70 : Colors.black87,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return isDark ? Colors.grey[600] : Colors.grey[400];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withValues(alpha: 0.5);
        }
        return isDark ? Colors.grey[800] : Colors.grey[300];
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.white : Colors.white,
        elevation: 2,
      ),
    ),
    iconTheme: IconThemeData(
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  );
}
