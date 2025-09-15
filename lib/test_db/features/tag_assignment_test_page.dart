import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/contact_service.dart';
import '../../data/services/tag_service.dart';
import '../../data/models/models.dart';

class TagAssignmentTestPage extends StatefulWidget {
  const TagAssignmentTestPage({super.key});

  @override
  State<TagAssignmentTestPage> createState() => _TagAssignmentTestPageState();
}

class _TagAssignmentTestPageState extends State<TagAssignmentTestPage> {
  late final ContactService _contacts;
  late final TagService _tags;

  List<ContactModel> _contactList = [];
  List<TagModel> _tagList = [];

  ContactModel? _selectedContact;
  TagModel? _selectedTag;

  String? _status;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _contacts = ContactService(client);
    _tags = TagService(client);
    _load();
  }

  Future<void> _load() async {
    try {
      _contactList = await _contacts.getContacts();
      _tagList = await _tags.getTags();
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _assign() async {
    if (_selectedContact == null || _selectedTag == null) return;
    try {
      await _tags.addTagToContact(_selectedContact!.id, _selectedTag!.id);
      setState(() => _status = 'Tag assigned');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _unassign() async {
    if (_selectedContact == null || _selectedTag == null) return;
    try {
      await _tags.removeTagFromContact(_selectedContact!.id, _selectedTag!.id);
      setState(() => _status = 'Tag unassigned');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _filterByTag() async {
    if (_selectedTag == null) return;
    try {
      _contactList = await _contacts.getContactsByTag(_selectedTag!.id);
      setState(() => _status = 'Filtered by ${_selectedTag!.name}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags: Assign & Filter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<ContactModel>(
                    isExpanded: true,
                    value: _selectedContact,
                    hint: const Text('Select contact'),
                    items: _contactList
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedContact = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<TagModel>(
                    isExpanded: true,
                    value: _selectedTag,
                    hint: const Text('Select tag'),
                    items: _tagList
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTag = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _assign, child: const Text('Assign')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _unassign,
                  child: const Text('Unassign'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _filterByTag,
                  child: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
            const SizedBox(height: 12),
            const Text('Contacts'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _contactList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = _contactList[index];
                  return ListTile(
                    title: Text(c.displayName),
                    subtitle: Text(
                      'Email: ${c.primaryEmail ?? '-'} • Phone: ${c.primaryMobile ?? '-'}',
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
