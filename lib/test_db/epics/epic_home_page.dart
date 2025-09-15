import 'package:flutter/material.dart';
import '../features/auth_test_page.dart';
import '../features/profiles_test_page.dart';
import '../features/contacts_test_page.dart';
import '../features/tags_test_page.dart';
import '../features/sharing_test_page.dart';
import '../features/my_contact_card_page.dart';
import '../features/tag_assignment_test_page.dart';

class EpicHomePage extends StatelessWidget {
  const EpicHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test DB by Epics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _EpicCard(
            title: 'E1 — Authentication & Profiles',
            items: [
              _EpicNav('US-E1-2/3: Auth (Sign up/in/out)', AuthTestPage()),
              _EpicNav('US-E1-4: View/Update Profile', ProfilesTestPage()),
            ],
          ),
          _EpicCard(
            title: 'E2 — Contacts CRUD',
            items: [_EpicNav('US-E2: Contacts CRUD', ContactsTestPage())],
          ),
          _EpicCard(
            title: 'E3 — Contact Channels',
            items: [
              _EpicNav(
                'US-E3-1/2: Contact Card & Channels',
                MyContactCardPage(),
              ),
            ],
          ),
          _EpicCard(
            title: 'E4 — Tags & Filtering',
            items: [
              _EpicNav('US-E4-1: Tags CRUD', TagsTestPage()),
              _EpicNav('US-E4-2/3/4: Assign & Filter', TagAssignmentTestPage()),
            ],
          ),
          _EpicCard(
            title: 'E5 — Username Discovery & Requests',
            items: [
              _EpicNav('US-E5-1/2/3: Search & Requests', SharingTestPage()),
            ],
          ),
          _EpicCard(
            title: 'E6 — Avatars (Storage)',
            items: [
              _EpicHint(
                'Use My Contact Card to set avatar_url field (DB write).',
              ),
            ],
          ),
          _EpicCard(
            title: 'E7 — App Shell & Theming',
            items: [_EpicHint('Not DB-related; covered by app UI shell')],
          ),
        ],
      ),
    );
  }
}

class _EpicCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _EpicCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _EpicNav extends StatelessWidget {
  final String label;
  final Widget page;
  const _EpicNav(this.label, this.page);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }
}

class _EpicHint extends StatelessWidget {
  final String text;
  const _EpicHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text),
    );
  }
}
