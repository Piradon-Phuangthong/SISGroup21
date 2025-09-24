import 'package:flutter/material.dart';
import '../themes/color_palette.dart';
import '../data/models/contact_model.dart';

class ContactTile extends StatelessWidget {
  final ContactModel contact;
  final ColorPalette colorPalette;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ContactTile({
    super.key,
    required this.contact,
    required this.colorPalette,
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
      subtitle: Text(
        contact.primaryMobile ?? contact.primaryEmail ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
