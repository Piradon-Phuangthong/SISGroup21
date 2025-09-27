import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/services/sharing_service.dart';

class SharingTestPage extends StatefulWidget {
  const SharingTestPage({super.key});

  @override
  State<SharingTestPage> createState() => _SharingTestPageState();
}

class _SharingTestPageState extends State<SharingTestPage> {
  late final SharingService _service;
  List<ShareRequestWithProfile> _incoming = [];
  List<ShareRequestWithProfile> _outgoing = [];
  List<ContactShareWithDetails> _myShares = [];
  List<ContactShareWithDetails> _sharesWithMe = [];
  final _usernameCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _service = SharingService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      _incoming = await _service.getIncomingShareRequests();
      _outgoing = await _service.getOutgoingShareRequests();
      _myShares = await _service.getMyShares();
      _sharesWithMe = await _service.getSharesWithMe();
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _sendRequest() async {
    try {
      final username = _usernameCtrl.text.trim();
      if (username.isEmpty) return;
      await _service.sendShareRequest(recipientUsername: username);
      _usernameCtrl.clear();
      await _load();
      setState(() => _status = 'Request sent');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _accept(String requestId) async {
    try {
      // For test we don't actually create shares (needs contact id). Only mark as accepted.
      await _service.acceptShareRequest(requestId, shareConfigs: []);
      await _load();
      setState(() => _status = 'Accepted');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _decline(String requestId) async {
    try {
      await _service.declineShareRequest(requestId);
      await _load();
      setState(() => _status = 'Declined');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sharing Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Recipient username',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendRequest,
                  child: const Text('Send Request'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
            const SizedBox(height: 12),
            _section(
              'Incoming Requests',
              _incoming
                  .map(
                    (r) => ListTile(
                      title: Text(
                        r.requesterProfile?.username ?? r.request.requesterId,
                      ),
                      subtitle: Text(
                        'Status: ${r.request.status.value} • ${r.request.createdAt}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () => _accept(r.request.id),
                            icon: const Icon(Icons.check),
                          ),
                          IconButton(
                            onPressed: () => _decline(r.request.id),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _section(
              'Outgoing Requests',
              _outgoing
                  .map(
                    (r) => ListTile(
                      title: Text(
                        r.recipientProfile?.username ?? r.request.recipientId,
                      ),
                      subtitle: Text(
                        'Status: ${r.request.status.value} • ${r.request.createdAt}',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _section(
              'My Shares',
              _myShares
                  .map(
                    (s) => ListTile(
                      title: Text(
                        s.recipientProfile?.username ?? s.share.toUserId,
                      ),
                      subtitle: Text(
                        'Contact: ${s.contact?.displayName ?? s.share.contactId} • Active: ${s.share.isActive}',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _section(
              'Shared With Me',
              _sharesWithMe
                  .map(
                    (s) => ListTile(
                      title: Text(s.ownerProfile?.username ?? s.share.ownerId),
                      subtitle: Text(
                        'Contact: ${s.contact?.displayName ?? s.share.contactId} • Active: ${s.share.isActive}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (children.isEmpty) const Text('No data'),
        ...children,
      ],
    );
  }
}
