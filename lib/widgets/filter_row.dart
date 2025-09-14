import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../themes/color_palette.dart';

class FilterRow extends StatelessWidget {
  final List<Tag> tags;
  final List<Tag> selectedTags;
  final ColorPalette colorPalette;
  final Function(Tag) onTagToggle;

  const FilterRow({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.colorPalette,
    required this.onTagToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tags
              .map((tag) => _buildFilterButton(tag))
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

  Widget _buildFilterButton(Tag tag) {
    final bool isSelected = selectedTags.contains(tag);
    return ElevatedButton(
      onPressed: () => onTagToggle(tag),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? colorPalette.getColor(tag.colorIndex)
            : null,
        foregroundColor: isSelected
            ? Colors.white
            : colorPalette.getColor(tag.colorIndex),
      ),
      child: Text(tag.name),
    );
  }
}
