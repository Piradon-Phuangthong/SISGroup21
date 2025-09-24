import 'package:flutter/material.dart';

/// ColorPalette class to hold a collection of themed colors
class ColorPalette {
  final String name;
  final List<Color> colors;

  const ColorPalette({required this.name, required this.colors});

  /// Get color by index with bounds checking
  Color getColor(int index) {
    return colors[index % colors.length];
  }

  /// Get a color for a specific contact or tag based on hash
  Color getColorForItem(String identifier) {
    final hash = identifier.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorPalette &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Modern Ocean Theme - Cool blues and teals with coral accent
final ColorPalette oceanTheme = ColorPalette(
  name: 'Ocean',
  colors: [
    Color(0xFF2196F3), // Bright Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF5722), // Deep Orange (coral accent)
  ],
);

/// Sunset Warm Theme - Warm oranges, pinks, and purples
final ColorPalette sunsetTheme = ColorPalette(
  name: 'Sunset',
  colors: [
    Color(0xFFFF6B6B), // Coral Pink
    Color(0xFFFF8E53), // Orange
    Color(0xFFFFBE0B), // Golden Yellow
    Color(0xFFE056FD), // Purple
    Color(0xFF845EC2), // Deep Purple
  ],
);

/// Forest Earth Theme - Natural greens and earth tones
final ColorPalette forestTheme = ColorPalette(
  name: 'Forest',
  colors: [
    Color(0xFF8BC34A), // Light Green
    Color(0xFF4CAF50), // Green
    Color(0xFF2E7D32), // Dark Green
    Color(0xFF8D6E63), // Brown
    Color(0xFFFF7043), // Deep Orange (autumn accent)
  ],
);

/// List of all available themes
final List<ColorPalette> allThemes = [oceanTheme, sunsetTheme, forestTheme];
