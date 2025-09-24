import 'package:flutter/material.dart';
import '../themes/color_palette.dart';
import '../data/models/tag_model.dart';

/// Horizontal list of tag filter buttons.
///
/// MVP supports single-select: when a tag is tapped, it becomes the active
/// filter. Tapping the active tag again clears the selection.
class FilterRow extends StatelessWidget {
  final List<TagModel> tags;
  final Set<String> selectedTagIds;
  final ColorPalette colorPalette;
  final void Function(TagModel tag) onTagToggle;

  const FilterRow({
    super.key,
    required this.tags,
    required this.selectedTagIds,
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

  Widget _buildFilterButton(TagModel tag) {
    final bool isSelected = selectedTagIds.contains(tag.id);
    return ElevatedButton(
      onPressed: () => onTagToggle(tag),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? colorPalette.getColorForItem(tag.id)
            : null,
        foregroundColor: isSelected
            ? Colors.white
            : colorPalette.getColorForItem(tag.id),
      ),
      child: Text(tag.name),
    );
  }
}
