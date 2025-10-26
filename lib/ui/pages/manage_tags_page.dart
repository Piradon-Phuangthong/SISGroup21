import 'package:flutter/material.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/data/services/tag_service.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/core/theme/app_theme.dart';
import 'package:omada/ui/widgets/app_card.dart';

class ManageTagsPage extends StatefulWidget {
  final List<TagModel> initialTags;
  final Set<String> selectedTagIds;
  final TagService tagService;
  final void Function(List<TagModel> tags) onTagsUpdated;
  final void Function(Set<String> selectedIds) onSelectedIdsChanged;

  const ManageTagsPage({
    super.key,
    required this.initialTags,
    required this.selectedTagIds,
    required this.tagService,
    required this.onTagsUpdated,
    required this.onSelectedIdsChanged,
  });

  @override
  State<ManageTagsPage> createState() => _ManageTagsPageState();
}

class _ManageTagsPageState extends State<ManageTagsPage> {
  late List<TagModel> tags;
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    tags = List<TagModel>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Get color for a tag using hash-based color assignment
  Color _getTagColor(BuildContext context, TagModel tag) {
    final palette = Theme.of(context).extension<AppPaletteTheme>();
    return palette?.colorForId(tag.id) ?? Theme.of(context).colorScheme.secondary;
  }

  Future<void> _createTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      // Create tag (color will be determined by hash-based system)
      await widget.tagService.createTag(name);
      _nameController.clear();
      
      final fetched = await widget.tagService.getTags();
      setState(() {
        tags = fetched;
      });
      widget.onTagsUpdated(fetched);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create tag: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteTag(TagModel tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete tag?'),
        content: Text('Delete "${tag.name}"? This will remove it from any contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.tagService.deleteTag(tag.id);
        final fetched = await widget.tagService.getTags();
        setState(() => tags = fetched);
        widget.onTagsUpdated(fetched);
        
        if (widget.selectedTagIds.contains(tag.id)) {
          final updated = Set<String>.from(widget.selectedTagIds)..remove(tag.id);
          widget.onSelectedIdsChanged(updated);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete tag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B5CF6), // Purple
                      Color(0xFF3B82F6), // Blue
                    ],
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Text(
                      'Manage Tags',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(OmadaTokens.space16),
              child: Column(
                children: [
                  // Create New Tag Section
                  AppCard(
                    padding: const EdgeInsets.all(OmadaTokens.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.label_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Create New Tag',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: OmadaTokens.space16),
                        
                        // Tag Name Input
                        Text(
                          'Tag Name',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter tag name...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _createTag(),
                        ),
                        const SizedBox(height: OmadaTokens.space16),
                        const SizedBox(height: OmadaTokens.space20),
                        
                        // Create Tag Button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FilledButton.icon(
                              onPressed: _isCreating ? null : _createTag,
                              icon: _isCreating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add, color: Colors.white),
                              label: Text(
                                _isCreating ? 'Creating...' : 'Create Tag',
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: OmadaTokens.space16),
                  
                  // Existing Tags Section
                  AppCard(
                    padding: const EdgeInsets.all(OmadaTokens.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Existing Tags (${tags.length})',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: OmadaTokens.space16),
                        
                        if (tags.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'No tags created yet',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) {
                              // Use hash-based color assignment
                              final Color tagColor = _getTagColor(context, tag);
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: tagColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tag.name,
                                      style: TextStyle(
                                        color: tagColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _deleteTag(tag),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: tagColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

