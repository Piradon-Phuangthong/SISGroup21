import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/domain/models/tag.dart';
import 'package:intl/intl.dart';
import 'package:omada/core/theme/app_theme.dart';
import 'package:omada/core/theme/color_palette.dart';
import 'package:omada/ui/pages/contact_screen/contact_tag.dart';

class ContactCard extends StatefulWidget {
  final ContactModel contact;
  final List<TagModel> tags;
  final void Function(TagModel tag)? onTagTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;
  final bool showDeleteOption;
  final bool isShared;
  final String? sharedBy;

  const ContactCard({
    super.key,
    required this.contact,
    this.tags = const [],
    this.onTagTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.isFavourite = false,
    this.onFavouriteToggle,
    this.showDeleteOption = true,
    this.isShared = false,
    this.sharedBy,
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

  @override
  Widget build(BuildContext context) {
    final appPalette = Theme.of(context).extension<AppPaletteTheme>();

    // final lastContactFormatted = DateFormat(
    //   "MMM d, hh:mm a",
    // ).format(widget.lastContact);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),

      child: Container(
        // height: 150,
        padding: EdgeInsets.only(top: 10, bottom: 10),
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: BoxBorder.all(
            color: Color.fromARGB(50, 109, 88, 186),
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          onLongPress: widget.onLongPress,
          onTap: widget.onLongPress,
          //  () {
          //   setState(() {
          //     isExpanded = !isExpanded;
          //   });
          // },
          child: Column(
            children: [
              Row(
                spacing: 10,
                children: [
                  //avatar photo
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.person, size: 30),
                  ),

                  //contact information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.contact.displayName,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.isShared && widget.sharedBy != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.share,
                                        size: 12,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '@${widget.sharedBy}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          widget.contact.primaryMobile ??
                              (widget.contact.primaryEmail?.isNotEmpty == true
                                  ? widget.contact.primaryEmail!
                                  : ''),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 30,
                          width: 200,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: widget.tags.map((tag) {
                              return DashboardTag(
                                label: tag.name,
                                color: getTagColor(tag),
                              );
                            }).toList(),
                          ),
                        ),

                        //last seen information
                        // Text(
                        //   "Last contact: $lastContactFormatted",
                        //   style: TextStyle(fontSize: 10),
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                      ],
                    ),
                  ),

                  // message/phone
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.isFavourite ? Icons.star : Icons.star_border,
                          color: widget.isFavourite ? Colors.amber : null,
                        ),
                        onPressed: widget.onFavouriteToggle,
                        tooltip: widget.isFavourite
                            ? 'Remove from favourites'
                            : 'Add to favourites',
                      ),
                      if (widget.showDeleteOption && widget.onDelete != null)
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: Icon(Icons.delete),
                        ),
                    ],
                  ),
                ],
              ),
              if (isExpanded)
                Padding(
                  padding: EdgeInsetsGeometry.only(top: 8),
                  child: Row(
                    children: [
                      IconButton(onPressed: () {}, icon: Icon(Icons.abc)),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.add_business_rounded),
                      ),
                      IconButton(onPressed: () {}, icon: Icon(Icons.face)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
