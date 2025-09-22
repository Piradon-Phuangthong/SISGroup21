import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/tag.dart';
import '../themes/color_palette.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/theme_selector.dart';
import '../widgets/filter_row.dart';
import '../widgets/contact_tile.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Tag> selectedTags = [];
  ColorPalette selectedTheme = oceanTheme;

  static final List<Tag> tags = [
    Tag('Family', 0),
    Tag('Work', 1),
    Tag('School', 2),
    Tag('Uni', 3),
    Tag('Friend', 4),
    Tag('Gym', 5),
  ];

  final List<Contact> contacts = [
    Contact('Anna Martinez', 'AM', [tags[0], tags[4]], 0),
    Contact('Ben Johnson', 'BJ', [tags[1], tags[4]], 1),
    Contact('Clara Liu', 'CL', [tags[2], tags[4]], 2),
    Contact('David Chen', 'DC', [tags[1], tags[3]], 3),
    Contact('Emily Foster', 'EF', [tags[2], tags[3]], 4),
    Contact('Fiona Brown', 'FB', [tags[1], tags[3]], 5),
    Contact('George Green', 'GG', [tags[0], tags[3]], 6),
    Contact('Hannah Lee', 'HL', [tags[1], tags[4]], 7),
    Contact('Isaac Kim', 'IK', [tags[0], tags[4]], 8),
    Contact('Jasmine Patel', 'JP', [tags[1], tags[5]], 9),
    Contact('Kevin Nguyen', 'KN', [tags[0], tags[5]], 10),
    Contact('Liam O\'Connor', 'LO', [tags[1], tags[4]], 11),
  ];

  List<Contact> getFilteredContacts() {
    if (selectedTags.isEmpty) {
      return contacts;
    }
    return contacts
        .where(
          (contact) => contact.tags.any((tag) => selectedTags.contains(tag)),
        )
        .toList();
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  void _changeTheme(ColorPalette theme) {
    setState(() {
      selectedTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          ThemeSelector(
            themes: allThemes,
            selectedTheme: selectedTheme,
            onThemeChanged: _changeTheme,
          ),
          FilterRow(
            tags: tags,
            selectedTags: selectedTags,
            colorPalette: selectedTheme,
            onTagToggle: _toggleTag,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: getFilteredContacts().length,
              itemBuilder: (context, index) {
                final contact = getFilteredContacts()[index];
                return ContactTile(
                  contact: contact,
                  colorPalette: selectedTheme,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.contacts),
    );
  }
}
