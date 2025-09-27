import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/models/models.dart';

class MyChannelsPage extends StatefulWidget {
  const MyChannelsPage({super.key});

  @override
  State<MyChannelsPage> createState() => _MyChannelsPageState();
}

class _MyChannelsPageState extends State<MyChannelsPage> {
  late final ContactService _contacts;
  late final ContactChannelRepository _repo;

  ContactModel? _myContact;
  List<ContactChannelModel> _channels = [];

  final Map<String, Map<String, String>> _presets = const {
    'mobile': {
      'label': 'Mobile',
      'valueHint': '+15551234567',
      'urlHint': 'tel:+15551234567',
    },
    'email': {
      'label': 'Email',
      'valueHint': 'name@example.com',
      'urlHint': 'mailto:name@example.com',
    },
    'instagram': {
      'label': 'Instagram',
      'valueHint': 'username',
      'urlHint': 'https://instagram.com/username',
    },
    'linkedin': {
      'label': 'LinkedIn',
      'valueHint': 'slug',
      'urlHint': 'https://www.linkedin.com/in/slug',
    },
    'messenger': {
      'label': 'Messenger',
      'valueHint': 'username',
      'urlHint': 'https://m.me/username',
    },
  };

  String _selectedKind = 'mobile';
  final _labelCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _contacts = ContactService(client);
    _repo = ContactChannelRepository(client);
    _applyPreset('mobile', applyDefaults: true);
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _contacts.getContacts(limit: 1);
      if (list.isEmpty) {
        _myContact = await _contacts.createContact(fullName: 'My Contact');
      } else {
        _myContact = list.first;
      }
      _channels = await _repo.getChannelsForContact(_myContact!.id);
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _applyPreset(String kind, {bool applyDefaults = false}) {
    final preset = _presets[kind];
    if (preset == null) return;
    if (applyDefaults) {
      if (_labelCtrl.text.trim().isEmpty) {
        _labelCtrl.text = preset['label']!;
      }
    }
    setState(() {
      _selectedKind = kind;
    });
  }

  Future<void> _addChannel() async {
    if (_myContact == null) return;
    try {
      await _repo.createChannel(
        contactId: _myContact!.id,
        kind: _selectedKind,
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

  Future<void> _updateChannel(
    ContactChannelModel ch, {
    String? label,
    String? value,
    String? url,
    bool? isPrimary,
  }) async {
    try {
      await _repo.updateChannel(
        ch.id,
        label: label,
        value: value,
        url: url,
        isPrimary: isPrimary,
      );
      await _load();
      setState(() => _status = 'Channel updated');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _setPrimary(ContactChannelModel ch) async {
    if (_myContact == null) return;
    try {
      await _repo.setPrimaryForKind(
        contactId: _myContact!.id,
        kind: ch.kind,
        channelId: ch.id,
      );
      await _load();
      setState(() => _status = 'Set as primary for ${ch.kind}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _deleteChannel(ContactChannelModel ch) async {
    try {
      await _repo.deleteChannel(ch.id);
      await _load();
      setState(() => _status = 'Channel deleted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kinds = _presets.keys.toList();
    final hint = _presets[_selectedKind]!;
    return Scaffold(
      appBar: AppBar(title: const Text('My Channels')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Contact id: ${_myContact?.id ?? '-'}'),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Channel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _selectedKind,
                          items: kinds
                              .map(
                                (k) =>
                                    DropdownMenuItem(value: k, child: Text(k)),
                              )
                              .toList(),
                          onChanged: (k) {
                            if (k != null) _applyPreset(k, applyDefaults: true);
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _labelCtrl,
                            decoration: InputDecoration(
                              labelText: 'Label',
                              hintText: hint['label'],
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
                            controller: _valueCtrl,
                            decoration: InputDecoration(
                              labelText: 'Value',
                              hintText: hint['valueHint'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _urlCtrl,
                            decoration: InputDecoration(
                              labelText: 'URL',
                              hintText: hint['urlHint'],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addChannel,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Existing Channels',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_channels.isEmpty)
                      const Text('No channels yet')
                    else
                      ..._channels.map(
                        (ch) => _ChannelEditor(
                          channel: ch,
                          onSave: (label, value, url) => _updateChannel(
                            ch,
                            label: label,
                            value: value,
                            url: url,
                          ),
                          onSetPrimary: () => _setPrimary(ch),
                          onDelete: () => _deleteChannel(ch),
                        ),
                      ),
                  ],
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

class _ChannelEditor extends StatefulWidget {
  final ContactChannelModel channel;
  final Future<void> Function(String? label, String? value, String? url) onSave;
  final Future<void> Function() onSetPrimary;
  final Future<void> Function() onDelete;

  const _ChannelEditor({
    required this.channel,
    required this.onSave,
    required this.onSetPrimary,
    required this.onDelete,
  });

  @override
  State<_ChannelEditor> createState() => _ChannelEditorState();
}

class _ChannelEditorState extends State<_ChannelEditor> {
  late final TextEditingController _label;
  late final TextEditingController _value;
  late final TextEditingController _url;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.channel.label ?? '');
    _value = TextEditingController(text: widget.channel.value ?? '');
    _url = TextEditingController(text: widget.channel.url ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.channel;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(ch.isPrimary ? Icons.star : Icons.link),
          title: Text('${ch.kind} • ${ch.label ?? '-'}'),
          subtitle: Text('value: ${ch.value ?? '-'} • url: ${ch.url ?? '-'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Set primary',
                icon: const Icon(Icons.star_outline),
                onPressed: widget.onSetPrimary,
              ),
              IconButton(
                tooltip: 'Edit',
                icon: Icon(_expanded ? Icons.expand_less : Icons.edit),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _label,
                        decoration: const InputDecoration(labelText: 'Label'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _value,
                        decoration: const InputDecoration(labelText: 'Value'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _url,
                        decoration: const InputDecoration(labelText: 'URL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onSave(
                        _label.text.trim().isEmpty ? null : _label.text.trim(),
                        _value.text.trim().isEmpty ? null : _value.text.trim(),
                        _url.text.trim().isEmpty ? null : _url.text.trim(),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }
}
