import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/models/models.dart';

class MyContactCardPage extends StatefulWidget {
  const MyContactCardPage({super.key});

  @override
  State<MyContactCardPage> createState() => _MyContactCardPageState();
}

class _MyContactCardPageState extends State<MyContactCardPage> {
  late final ContactService _contacts;
  late final ContactChannelRepository _channelsRepo;

  ContactModel? _myContact;
  List<ContactChannelModel> _channels = [];

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _givenNameCtrl = TextEditingController();
  final _familyNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  final _suffixCtrl = TextEditingController();
  final _avatarUrlCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _defaultCallAppCtrl = TextEditingController();
  final _defaultMsgAppCtrl = TextEditingController();

  // channel inputs
  final _kindCtrl = TextEditingController(text: 'email');
  final _labelCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

  String? _status;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _contacts = ContactService(client);
    _channelsRepo = ContactChannelRepository(client);
    _load();
  }

  Future<void> _load() async {
    try {
      // Strategy: pick first non-deleted contact as "my card" (or create one)
      final all = await _contacts.getContacts(limit: 1);
      if (all.isEmpty) {
        _myContact = await _contacts.createContact(fullName: 'My Contact');
      } else {
        _myContact = all.first;
      }
      _nameCtrl.text = _myContact?.fullName ?? '';
      _emailCtrl.text = _myContact?.primaryEmail ?? '';
      _phoneCtrl.text = _myContact?.primaryMobile ?? '';
      _givenNameCtrl.text = _myContact?.givenName ?? '';
      _familyNameCtrl.text = _myContact?.familyName ?? '';
      _middleNameCtrl.text = _myContact?.middleName ?? '';
      _prefixCtrl.text = _myContact?.prefix ?? '';
      _suffixCtrl.text = _myContact?.suffix ?? '';
      _avatarUrlCtrl.text = _myContact?.avatarUrl ?? '';
      _notesCtrl.text = _myContact?.notes ?? '';
      _defaultCallAppCtrl.text = _myContact?.defaultCallApp ?? '';
      _defaultMsgAppCtrl.text = _myContact?.defaultMsgApp ?? '';

      _channels = await _channelsRepo.getChannelsForContact(_myContact!.id);
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _saveCard() async {
    if (_myContact == null) return;
    try {
      await _contacts.updateContact(
        _myContact!.id,
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        givenName: _givenNameCtrl.text.trim().isEmpty
            ? null
            : _givenNameCtrl.text.trim(),
        familyName: _familyNameCtrl.text.trim().isEmpty
            ? null
            : _familyNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim().isEmpty
            ? null
            : _middleNameCtrl.text.trim(),
        prefix: _prefixCtrl.text.trim().isEmpty
            ? null
            : _prefixCtrl.text.trim(),
        suffix: _suffixCtrl.text.trim().isEmpty
            ? null
            : _suffixCtrl.text.trim(),
        primaryEmail: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        primaryMobile: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        avatarUrl: _avatarUrlCtrl.text.trim().isEmpty
            ? null
            : _avatarUrlCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        defaultCallApp: _defaultCallAppCtrl.text.trim().isEmpty
            ? null
            : _defaultCallAppCtrl.text.trim(),
        defaultMsgApp: _defaultMsgAppCtrl.text.trim().isEmpty
            ? null
            : _defaultMsgAppCtrl.text.trim(),
      );
      await _load();
      setState(() => _status = 'Saved');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _addChannel() async {
    if (_myContact == null) return;
    try {
      await _channelsRepo.createChannel(
        contactId: _myContact!.id,
        kind: _kindCtrl.text.trim(),
        label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        value: _valueCtrl.text.trim().isEmpty ? null : _valueCtrl.text.trim(),
        url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      );
      _labelCtrl.clear();
      _valueCtrl.clear();
      _urlCtrl.clear();
      await _load();
      setState(() => _status = 'Channel added');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _deleteChannel(ContactChannelModel ch) async {
    try {
      await _channelsRepo.deleteChannel(ch.id);
      await _load();
      setState(() => _status = 'Channel deleted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Contact Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Contact id: ${_myContact?.id ?? '-'}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _givenNameCtrl,
                    decoration: const InputDecoration(labelText: 'First name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _familyNameCtrl,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _middleNameCtrl,
                    decoration: const InputDecoration(labelText: 'Middle name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _prefixCtrl,
                    decoration: const InputDecoration(labelText: 'Prefix'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _suffixCtrl,
                    decoration: const InputDecoration(labelText: 'Suffix'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Primary email',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Primary mobile',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveCard,
              child: const Text('Save Contact'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Channels',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Optional fields'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _avatarUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Avatar URL'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _defaultCallAppCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Default call app',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _defaultMsgAppCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Default msg app',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kindCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kind (e.g., email, phone, whatsapp)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _valueCtrl,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(labelText: 'URL'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addChannel,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._channels.map(
              (ch) => ListTile(
                title: Text('${ch.kind} • ${ch.label ?? '-'}'),
                subtitle: Text(
                  'value: ${ch.value ?? '-'}  •  url: ${ch.url ?? '-'}  •  primary: ${ch.isPrimary}',
                ),
                trailing: IconButton(
                  onPressed: () => _deleteChannel(ch),
                  icon: const Icon(Icons.delete),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}
