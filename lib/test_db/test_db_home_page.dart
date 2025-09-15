import 'package:flutter/material.dart';
import 'features/auth_test_page.dart';
import 'features/profiles_test_page.dart';
import 'features/contacts_test_page.dart';
import 'features/tags_test_page.dart';
import 'features/sharing_test_page.dart';
import 'features/my_contact_card_page.dart';
import 'features/dummy_user_wizard_page.dart';
import 'epics/epic_home_entry.dart';

class TestDbHomePage extends StatelessWidget {
  const TestDbHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('Epics View', const EpicHomeEntry()),
      _NavItem('Auth', const AuthTestPage()),
      _NavItem('Profiles', const ProfilesTestPage()),
      _NavItem('Contacts', const ContactsTestPage()),
      _NavItem('Tags', const TagsTestPage()),
      _NavItem('Sharing', const SharingTestPage()),
      _NavItem('My Contact Card', const MyContactCardPage()),
      _NavItem('Dummy User Wizard', const DummyUserWizardPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Test DB - Home')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 3,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => item.page)),
            borderRadius: BorderRadius.circular(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.title, maxLines: 2)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem {
  final String title;
  final Widget page;
  const _NavItem(this.title, this.page);
}
