import 'dart:math';
import 'package:flutter/material.dart';

/// Utility class for color operations in the app
class ColorUtils {
  ColorUtils._();

  /// Predefined color palette for Omadas and other entities
  static const List<String> omadaColorPalette = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DFE6E9', // Gray
    '#A29BFE', // Purple
    '#FD79A8', // Pink
    '#FF9FF3', // Light Pink
    '#54A0FF', // Sky Blue
    '#48DBFB', // Cyan
    '#1DD1A1', // Mint
    '#F368E0', // Magenta
    '#FF6348', // Coral
    '#5F27CD', // Deep Purple
    '#00D2D3', // Turquoise
  ];

  /// Parse a color string (hex format) to Color object
  /// Returns a default color if parsing fails
  static Color parseColor(String? colorString, {Color? fallback}) {
    if (colorString == null || colorString.isEmpty) {
      return fallback ?? getRandomColor();
    }

    try {
      final hexColor = colorString.replaceFirst('#', '0xFF');
      return Color(int.parse(hexColor));
    } catch (e) {
      return fallback ?? getRandomColor();
    }
  }

  /// Generate a random color from the palette
  static Color getRandomColor() {
    final random = Random();
    final colorString =
        omadaColorPalette[random.nextInt(omadaColorPalette.length)];
    return parseColor(colorString);
  }

  /// Get a consistent color for a given string (e.g., name)
  /// Same string will always generate the same color
  static Color getColorForString(String text) {
    if (text.isEmpty) return getRandomColor();

    final hash = text.hashCode.abs();
    final index = hash % omadaColorPalette.length;
    return parseColor(omadaColorPalette[index]);
  }

  /// Convert Color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Get a lighter version of a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Get a darker version of a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Check if a color is light or dark
  static bool isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }

  /// Get contrasting text color (white or black) for a background color
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }
}
