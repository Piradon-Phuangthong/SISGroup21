import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/models/models.dart';

class ContactsTestPage extends StatefulWidget {
  const ContactsTestPage({super.key});

  @override
  State<ContactsTestPage> createState() => _ContactsTestPageState();
}

class _ContactsTestPageState extends State<ContactsTestPage> {
  late final ContactService _service;
  List<ContactModel> _contacts = [];
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _service = ContactService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      _contacts = await _service.getContacts();
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _create() async {
    try {
      await _service.createContact(
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        primaryEmail: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        primaryMobile: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
      );
      _clearInputs();
      await _load();
      setState(() => _status = 'Created');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _seedDummyContacts() async {
    setState(() => _status = 'Seeding...');
    try {
      final samples = <Map<String, String?>>[
        {
          'name': 'Anna Martinez',
          'email': 'anna.martinez@example.com',
          'phone': '+1 555 0101',
        },
        {
          'name': 'Ben Johnson',
          'email': 'ben.johnson@example.com',
          'phone': '+1 555 0102',
        },
        {
          'name': 'Clara Liu',
          'email': 'clara.liu@example.com',
          'phone': '+1 555 0103',
        },
        {
          'name': 'David Chen',
          'email': 'david.chen@example.com',
          'phone': '+1 555 0104',
        },
        {
          'name': 'Emily Foster',
          'email': 'emily.foster@example.com',
          'phone': '+1 555 0105',
        },
        {
          'name': 'Fiona Brown',
          'email': 'fiona.brown@example.com',
          'phone': '+1 555 0106',
        },
        {
          'name': 'George Green',
          'email': 'george.green@example.com',
          'phone': '+1 555 0107',
        },
        {
          'name': 'Hannah Lee',
          'email': 'hannah.lee@example.com',
          'phone': '+1 555 0108',
        },
        {
          'name': 'Isaac Kim',
          'email': 'isaac.kim@example.com',
          'phone': '+1 555 0109',
        },
        {
          'name': 'Jasmine Patel',
          'email': 'jasmine.patel@example.com',
          'phone': '+1 555 0110',
        },
        {
          'name': 'Kevin Nguyen',
          'email': 'kevin.nguyen@example.com',
          'phone': '+1 555 0111',
        },
        {
          'name': "Liam O'Connor",
          'email': 'liam.oconnor@example.com',
          'phone': '+1 555 0112',
        },
      ];

      for (final s in samples) {
        await _service.createContact(
          fullName: s['name'],
          primaryEmail: s['email'],
          primaryMobile: s['phone'],
        );
      }

      await _load();
      setState(() => _status = 'Seeded ${samples.length} contacts');
    } catch (e) {
      setState(() => _status = 'Error seeding: $e');
    }
  }

  Future<void> _update(ContactModel c) async {
    try {
      await _service.updateContact(
        c.id,
        fullName: _nameCtrl.text.trim().isEmpty
            ? c.fullName
            : _nameCtrl.text.trim(),
        primaryEmail: _emailCtrl.text.trim().isEmpty
            ? c.primaryEmail
            : _emailCtrl.text.trim(),
        primaryMobile: _phoneCtrl.text.trim().isEmpty
            ? c.primaryMobile
            : _phoneCtrl.text.trim(),
      );
      _clearInputs();
      await _load();
      setState(() => _status = 'Updated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _delete(ContactModel c) async {
    try {
      await _service.permanentlyDeleteContact(c.id);
      await _load();
      setState(() => _status = 'Deleted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _clearInputs() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _create,
                          child: const Text('Create'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _seedDummyContacts,
                          child: const Text('Seed 12 contacts'),
                        ),
                      ],
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_status!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final c = _contacts[index];
                  return Card(
                    child: ListTile(
                      title: Text(c.displayName),
                      subtitle: Text(
                        'Email: ${c.primaryEmail ?? '-'}  •  Phone: ${c.primaryMobile ?? '-'}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () => _update(c),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _delete(c),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
