import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final Color primaryColor;
  final Color secondaryColor;
  final Brightness brightness;
  final bool minimalMode;

  const ThemeState({
    required this.primaryColor,
    required this.secondaryColor,
    required this.brightness,
    required this.minimalMode,
  });

  ThemeState copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Brightness? brightness,
    bool? minimalMode,
  }) {
    return ThemeState(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      brightness: brightness ?? this.brightness,
      minimalMode: minimalMode ?? this.minimalMode,
    );
  }

  static const ThemeState defaultTheme = ThemeState(
    primaryColor: Color(0xFF673AB7), // deepPurple
    secondaryColor: Color(0xFF03DAC6), // tealAccent
    brightness: Brightness.dark,
    minimalMode: false,
  );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState.defaultTheme) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    final primaryColorValue = prefs.getInt('theme_primary_color');
    final secondaryColorValue = prefs.getInt('theme_secondary_color');
    final brightnessString = prefs.getString('theme_brightness');
    final minimalMode = prefs.getBool('theme_minimal_mode') ?? false;

    state = ThemeState(
      primaryColor: primaryColorValue != null
          ? Color(primaryColorValue)
          : ThemeState.defaultTheme.primaryColor,
      secondaryColor: secondaryColorValue != null
          ? Color(secondaryColorValue)
          : ThemeState.defaultTheme.secondaryColor,
      brightness: brightnessString == 'light'
          ? Brightness.light
          : ThemeState.defaultTheme.brightness,
      minimalMode: minimalMode,
    );
  }

  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_primary_color', color.value);
  }

  Future<void> setSecondaryColor(Color color) async {
    state = state.copyWith(secondaryColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_secondary_color', color.value);
  }

  Future<void> toggleBrightness() async {
    final newBrightness = state.brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;
    state = state.copyWith(brightness: newBrightness);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_brightness', newBrightness == Brightness.light ? 'light' : 'dark');
  }

  Future<void> setMinimalMode(bool enabled) async {
    state = state.copyWith(minimalMode: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_minimal_mode', enabled);
  }

  Future<void> resetToDefault() async {
    state = ThemeState.defaultTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('theme_primary_color');
    await prefs.remove('theme_secondary_color');
    await prefs.remove('theme_brightness');
    await prefs.remove('theme_minimal_mode');
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

