import 'package:flutter/material.dart';
import '../themes/color_palette.dart';

class ThemeSelector extends StatelessWidget {
  final List<ColorPalette> themes;
  final ColorPalette selectedTheme;
  final Function(ColorPalette) onThemeChanged;

  const ThemeSelector({
    super.key,
    required this.themes,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: themes
              .map((palette) => _buildColorPaletteButton(palette))
              .toList()
              .map(
                (button) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: button,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildColorPaletteButton(ColorPalette palette) {
    final bool isSelected = selectedTheme == palette;
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => onThemeChanged(palette),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? palette.getColor(0) : null,
            foregroundColor: isSelected ? Colors.white : palette.getColor(0),
          ),
          child: Text(palette.name),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: palette.getColor(index),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }
}
