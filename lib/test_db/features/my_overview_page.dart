import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/contact_service.dart';
import '../../data/repositories/contact_channel_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/models/models.dart';

class MyOverviewPage extends StatefulWidget {
  const MyOverviewPage({super.key});

  @override
  State<MyOverviewPage> createState() => _MyOverviewPageState();
}

class _MyOverviewPageState extends State<MyOverviewPage> {
  late final ProfileRepository _profiles;
  late final ContactService _contacts;
  late final ContactChannelRepository _channelsRepo;
  late final TagRepository _tagsRepo;

  ProfileModel? _me;
  ContactModel? _myContact;
  List<ContactChannelModel> _channels = [];
  List<TagModel> _contactTags = [];
  String? _status;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _profiles = ProfileRepository(client);
    _contacts = ContactService(client);
    _channelsRepo = ContactChannelRepository(client);
    _tagsRepo = TagRepository(client);
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      _me = await _profiles.getCurrentProfile();

      // Load my contact card (first non-deleted)
      final list = await _contacts.getContacts(limit: 1);
      if (list.isNotEmpty) {
        _myContact = list.first;
        _channels = await _channelsRepo.getChannelsForContact(_myContact!.id);
        _contactTags = await _tagsRepo.getTagsForContact(_myContact!.id);
      } else {
        _myContact = null;
        _channels = [];
        _contactTags = [];
      }

      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Overview')),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_status!),
              ),

            // Profile card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_me != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(_me!.username),
                        subtitle: Text(_me!.id),
                      )
                    else
                      const Text('No profile (sign in required).'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Contact card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Contact Card',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_myContact == null)
                      const Text('No contact found yet.')
                    else ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.badge_outlined),
                        title: Text(_myContact!.fullName ?? '—'),
                        subtitle: Text('id: ${_myContact!.id}'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        runSpacing: 8,
                        spacing: 8,
                        children: [
                          _chip('Given', _myContact!.givenName),
                          _chip('Family', _myContact!.familyName),
                          _chip('Middle', _myContact!.middleName),
                          _chip('Prefix', _myContact!.prefix),
                          _chip('Suffix', _myContact!.suffix),
                          _chip('Email', _myContact!.primaryEmail),
                          _chip('Mobile', _myContact!.primaryMobile),
                          _chip('Avatar', _myContact!.avatarUrl),
                          _chip('Call App', _myContact!.defaultCallApp),
                          _chip('Msg App', _myContact!.defaultMsgApp),
                        ],
                      ),
                      if ((_myContact!.notes ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_myContact!.notes!),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Channels
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Channels',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_channels.isEmpty)
                      const Text('No channels')
                    else
                      ..._channels.map(
                        (ch) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(ch.isPrimary ? Icons.star : Icons.link),
                          title: Text('${ch.kind} • ${ch.label ?? '-'}'),
                          subtitle: Text(
                            'value: ${ch.value ?? '-'} • url: ${ch.url ?? '-'}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tags
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tags',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_contactTags.isEmpty)
                      const Text('No tags')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _contactTags
                            .map((t) => Chip(label: Text(t.name)))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final display = (value ?? '').trim();
    if (display.isEmpty) return const SizedBox.shrink();
    return Chip(label: Text('$label: $display'));
  }
}
