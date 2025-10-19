import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/ui/widgets/app_tag_chip.dart';
import 'package:omada/core/theme/app_theme.dart';

class ContactTile extends StatelessWidget {
  final ContactModel contact;
  final List<TagModel> tags;
  final void Function(TagModel tag)? onTagTap;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;

  const ContactTile({
    super.key,
    required this.contact,
    this.tags = const [],
    this.onTagTap,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isFavourite = false,
    this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(
              context,
            ).extension<AppPaletteTheme>()?.colorForId(contact.id) ??
            Theme.of(context).colorScheme.secondary,
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
            contact.primaryMobile ?? (contact.primaryEmail?.isNotEmpty == true ? contact.primaryEmail! : ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (t) => AppTagChip(
                      label: t.name,
                      backgroundColor:
                          Theme.of(
                            context,
                          ).extension<AppPaletteTheme>()?.colorForId(t.id) ??
                          Theme.of(context).colorScheme.secondary,
                      onTap: onTagTap == null ? null : () => onTagTap!(t),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onFavouriteToggle != null)
            IconButton(
              icon: Icon(
                isFavourite ? Icons.star : Icons.star_border,
                color: isFavourite ? Colors.amber : null,
              ),
              onPressed: onFavouriteToggle,
              tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
            ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
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
            ),
        ],
      ),
    );
  }
}
