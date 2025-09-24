import 'package:flutter/material.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/data/services/tag_service.dart';
import 'package:omada/core/theme/color_palette.dart';

class ManageTagsSheet extends StatelessWidget {
  final ColorPalette selectedTheme;
  final List<TagModel> initialTags;
  final Set<String> selectedTagIds;
  final TagService tagService;
  final void Function(List<TagModel> tags) onTagsUpdated;
  final void Function(Set<String> selectedIds) onSelectedIdsChanged;

  const ManageTagsSheet({
    super.key,
    required this.selectedTheme,
    required this.initialTags,
    required this.selectedTagIds,
    required this.tagService,
    required this.onTagsUpdated,
    required this.onSelectedIdsChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<TagModel> tags = List<TagModel>.from(initialTags);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, controller) {
        final TextEditingController nameController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> addTag() async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await tagService.createTag(name);
                nameController.clear();
                final fetched = await tagService.getTags();
                setSheetState(() => tags = fetched);
                onTagsUpdated(fetched);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create tag: $e')),
                );
              }
            }

            Future<void> deleteTag(TagModel tag) async {
              try {
                await tagService.deleteTag(tag.id);
                final fetched = await tagService.getTags();
                setSheetState(() => tags = fetched);
                onTagsUpdated(fetched);
                if (selectedTagIds.contains(tag.id)) {
                  final updated = Set<String>.from(selectedTagIds)
                    ..remove(tag.id);
                  onSelectedIdsChanged(updated);
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete tag: $e')),
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Manage tags',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'New tag name',
                          ),
                          onSubmitted: (_) => addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: addTag,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: tags.length,
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selectedTheme.getColorForItem(
                              tag.id,
                            ),
                            child: const Icon(
                              Icons.label,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(tag.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete tag?'),
                                  content: Text(
                                    'Delete "${tag.name}"? This will remove it from any contacts.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await deleteTag(tag);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
