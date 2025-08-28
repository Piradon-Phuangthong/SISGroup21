import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../themes/color_palette.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final ColorPalette colorPalette;

  const ContactTile({
    super.key,
    required this.contact,
    required this.colorPalette,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorPalette.getColor(contact.colorIndex),
        child: Text(
          contact.initials,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(contact.name),
      subtitle: Wrap(
        spacing: 4.0,
        children: contact.tags.map((tag) {
          return Chip(
            label: Text(
              tag.name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: colorPalette.getColor(tag.colorIndex),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}
