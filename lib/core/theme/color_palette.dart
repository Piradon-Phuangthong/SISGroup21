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

/// Catppuccin Latte accent colors (light)
const List<Color> catppuccinLatteAccents = <Color>[
  Color(0xFF8839EF), // mauve
  Color(0xFF1E66F5), // blue
  Color(0xFF04A5E5), // sky
  Color(0xFF179299), // teal
  Color(0xFF40A02B), // green
  Color(0xFFDF8E1D), // yellow
  Color(0xFFFE640B), // peach
  Color(0xFFD20F39), // red
  Color(0xFFEA76CB), // pink
];

/// Catppuccin Mocha accent colors (dark)
const List<Color> catppuccinMochaAccents = <Color>[
  Color(0xFFCBA6F7), // mauve
  Color(0xFF89B4FA), // blue
  Color(0xFF89DCEB), // sky
  Color(0xFF94E2D5), // teal
  Color(0xFFA6E3A1), // green
  Color(0xFFF9E2AF), // yellow
  Color(0xFFFAB387), // peach
  Color(0xFFF38BA8), // red
  Color(0xFFF5C2E7), // pink
];

/// Legacy single palette fallback if extension is unavailable
final ColorPalette appPalette = ColorPalette(
  name: 'App',
  colors: catppuccinLatteAccents,
);
