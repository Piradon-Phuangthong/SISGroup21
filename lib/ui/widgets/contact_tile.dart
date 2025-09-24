import 'package:flutter/material.dart';
import 'package:omada/core/theme/color_palette.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/tag_model.dart';

class ContactTile extends StatelessWidget {
  final ContactModel contact;
  final ColorPalette colorPalette;
  final List<TagModel> tags;
  final void Function(TagModel tag)? onTagTap;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContactTile({
    super.key,
    required this.contact,
    required this.colorPalette,
    this.tags = const [],
    this.onTagTap,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorPalette.getColorForItem(contact.id),
        child: Text(
          contact.initials,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(contact.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            contact.primaryMobile ?? contact.primaryEmail ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) {
                final bg = colorPalette.getColorForItem(t.id);
                final chip = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                );
                if (onTagTap == null) return chip;
                return GestureDetector(onTap: () => onTagTap!(t), child: chip);
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: (onEdit != null || onDelete != null)
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) onEdit!();
                if (value == 'delete' && onDelete != null) onDelete!();
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
          : null,
    );
  }
}
