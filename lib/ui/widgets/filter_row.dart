import 'package:flutter/material.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/core/theme/app_theme.dart';

/// Horizontal list of tag filter buttons.
///
/// MVP supports single-select: when a tag is tapped, it becomes the active
/// filter. Tapping the active tag again clears the selection.
class FilterRow extends StatelessWidget {
  final List<TagModel> tags;
  final Set<String> selectedTagIds;
  final void Function(TagModel tag) onTagToggle;

  const FilterRow({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.onTagToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmadaTokens.space16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tags
              .map((tag) => _buildFilterButton(context, tag))
              .toList()
              .map(
                (button) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OmadaTokens.space4,
                  ),
                  child: button,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, TagModel tag) {
    final bool isSelected = selectedTagIds.contains(tag.id);
    final palette = Theme.of(context).extension<AppPaletteTheme>();
    final Color tagColor =
<<<<<<< HEAD
        palette?.colorForId(tag.id) ?? Theme.of(context).colorScheme.secondary;
=======
        palette?.colorForId(tag.id) ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final isLight =
        Theme.of(context).colorScheme.brightness == Brightness.light;
>>>>>>> main
    return ElevatedButton(
      onPressed: () => onTagToggle(tag),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? tagColor
            : (isDark ? Color.fromARGB(255, 29, 26, 33) : Colors.white),
        foregroundColor: isSelected ? Colors.white : tagColor,
        elevation: isLight ? 0 : null,
      ),
      child: Text(tag.name),
    );
  }
}
