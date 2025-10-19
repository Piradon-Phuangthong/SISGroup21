import 'package:flutter/material.dart';
import 'package:omada/core/domain/models/tag.dart';
import 'package:intl/intl.dart';
import 'package:omada/core/theme/app_theme.dart';
import 'package:omada/core/theme/color_palette.dart';
import 'package:omada/ui/pages/contact_screen/contact_tag.dart';

class ContactCard extends StatefulWidget {
  final String name;
  final String phone;
  final List<Tag> tags;
  final DateTime lastContact;

  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.tags,
    required this.lastContact,
  });

  @override
  State<ContactCard> createState() => ContactCardState();
}

class ContactCardState extends State<ContactCard>
    with TickerProviderStateMixin {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final appPalette = Theme.of(context).extension<AppPaletteTheme>();

    final lastContactFormatted = DateFormat(
      "MMM d, hh:mm a",
    ).format(widget.lastContact);

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
          onLongPress: () {
            print("goto contact");
          },
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.name, textAlign: TextAlign.left),
                      Text(widget.phone, textAlign: TextAlign.left),
                      SizedBox(
                        height: 30,
                        width: 200,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: widget.tags.map((tag) {
                            return DashboardTag(
                              label: tag.name,
                              color: appPalette!.colorForIndex(tag.colorIndex),
                            );
                          }).toList(),
                        ),
                      ),

                      //last seen information
                      Text(
                        "Last contact: $lastContactFormatted",
                        style: TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // message/phone
                  Row(
                    children: [
                      IconButton(onPressed: () {}, icon: Icon(Icons.phone)),
                      IconButton(onPressed: () {}, icon: Icon(Icons.message)),
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
