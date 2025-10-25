import 'package:flutter/material.dart';
import 'package:omada/core/data/data.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/data/utils/channel_launcher.dart';
import 'package:omada/core/domain/models/tag.dart';
import 'package:intl/intl.dart';
import 'package:omada/core/theme/app_theme.dart';
import 'package:omada/core/theme/color_palette.dart';
import 'package:omada/ui/pages/contact_screen/contact_tag.dart';

class ContactCard extends StatefulWidget {
  final ContactModel contact;
  final List<TagModel> tags;
  final List<ContactChannelModel> channels;
  final void Function(TagModel tag)? onTagTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;

  const ContactCard({
    super.key,
    required this.contact,
    this.tags = const [],
    this.channels = const [],
    this.onTagTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.isFavourite = false,
    this.onFavouriteToggle,
  });

  @override
  State<ContactCard> createState() => ContactCardState();
}

class ContactCardState extends State<ContactCard>
    with TickerProviderStateMixin {
  bool isExpanded = false;
  final List<Color> _colorPalette = [
    const Color(0xFF3B82F6), // Light Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF22C55E), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFF59E0B), // Orange
    const Color(0xFFEC4899), // Pink
    const Color(0xFF1E40AF), // Dark Blue
    const Color(0xFFEAB308), // Yellow/Gold
  ];

  Color getTagColor(TagModel tag) {
    int colorIndex = tag.hashCode % _colorPalette.length;
    return _colorPalette[colorIndex];
  }

  String _getInitials() {
    final name = widget.contact.displayName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor() {
    final hash = widget.contact.id.hashCode;
    final colors = [
      const Color(0xFF8A2BE2), // Purple
      const Color(0xFF00CED1), // Dark Turquoise
      const Color(0xFFFF8C00), // Dark Orange
      const Color(0xFF20B2AA), // Light Sea Green
      const Color(0xFFFF1493), // Deep Pink
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final ChannelLauncher _launcher = const ChannelLauncher();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultButtonColor = Color.fromARGB(255, 29, 26, 33);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? defaultButtonColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onLongPress: widget.onLongPress,
        onTap: () {
          print("on tap ${widget.contact.fullName}");
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getAvatarColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Contact info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.contact.primaryMobile ??
                          (widget.contact.primaryEmail?.isNotEmpty == true
                              ? widget.contact.primaryEmail!
                              : 'No contact details'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (widget.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.tags.map((tag) {
                          final tagColor = getTagColor(tag);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? tagColor
                                  : tagColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white : tagColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Action icons
              Column(
                children: [
                  IconButton(
                    onPressed: widget.onLongPress,
                    icon: Icon(Icons.edit, color: Colors.grey),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isFavourite ? Icons.star : Icons.star_border,
                      color: widget.isFavourite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: widget.onFavouriteToggle,
                    tooltip: widget.isFavourite
                        ? 'Remove from favourites'
                        : 'Add to favourites',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete contact',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
