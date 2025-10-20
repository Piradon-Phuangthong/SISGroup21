import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/models/models.dart';

/// Test page to show all users who have accepted share requests
/// and the specific channels they have allowed access to
class AcceptedSharesTestPage extends StatefulWidget {
  const AcceptedSharesTestPage({super.key});

  @override
  State<AcceptedSharesTestPage> createState() => _AcceptedSharesTestPageState();
}

class _AcceptedSharesTestPageState extends State<AcceptedSharesTestPage> {
  late final ContactChannelRepository _channelRepo;
  
  List<_ShareRecipientInfo> _recipients = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _channelRepo = ContactChannelRepository(client);
    _loadAcceptedShares();
  }

  Future<void> _loadAcceptedShares() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      // Query contact_shares where current user is the owner
      // and the share is active (not revoked)
      final response = await Supabase.instance.client
          .from('contact_shares')
          .select('''
            *,
            recipient:profiles!contact_shares_to_user_id_fkey(id, username),
            contact:contacts(id, full_name, given_name, family_name)
          ''')
          .eq('owner_id', userId)
          .isFilter('revoked_at', null)
          .order('created_at', ascending: false);

      debugPrint('=== Accepted Shares Query Response ===');
      debugPrint('Raw data: $response');

      final List<_ShareRecipientInfo> recipientsList = [];

      for (final shareJson in response as List<dynamic>) {
        final share = ContactShareModel.fromJson(shareJson);
        final recipientData = shareJson['recipient'] as Map<String, dynamic>?;
        final contactData = shareJson['contact'] as Map<String, dynamic>?;

        // Build contact name from available fields
        String contactName = 'Unknown Contact';
        if (contactData != null) {
          final fullName = contactData['full_name'] as String?;
          final givenName = contactData['given_name'] as String?;
          final familyName = contactData['family_name'] as String?;
          
          if (fullName != null && fullName.isNotEmpty) {
            contactName = fullName;
          } else if (givenName != null || familyName != null) {
            contactName = [givenName, familyName]
                .where((n) => n != null && n.isNotEmpty)
                .join(' ');
          }
        }

        // Get channels that are shared (automatically filtered by field_mask)
        final allowedChannels = await _channelRepo.getSharedChannelsForContact(
          contactId: share.contactId,
          share: share,
        );

        recipientsList.add(_ShareRecipientInfo(
          share: share,
          recipientUsername: recipientData?['username'] as String? ?? 'Unknown',
          recipientId: recipientData?['id'] as String? ?? share.toUserId,
          contactName: contactName,
          allowedChannels: allowedChannels,
          sharesAllChannels: share.sharesAllChannels,
        ));
      }

      setState(() {
        _recipients = recipientsList;
        _loading = false;
      });

      debugPrint('=== Accepted Shares Loaded ===');
      debugPrint('Total recipients: ${recipientsList.length}');
      for (final recipient in recipientsList) {
        debugPrint('  - ${recipient.recipientUsername}: ${recipient.allowedChannels.length} channels');
      }
    } catch (e, stackTrace) {
      debugPrint('=== Error Loading Accepted Shares ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Share Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAcceptedShares,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading shares',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAcceptedShares,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Accepted Share Requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Users who accept your share requests\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recipients.length,
      itemBuilder: (context, index) {
        final recipient = _recipients[index];
        return _buildRecipientCard(recipient);
      },
    );
  }

  Widget _buildRecipientCard(_ShareRecipientInfo recipient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and username
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    recipient.recipientUsername[0].toUpperCase(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient.recipientUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ID: ${recipient.recipientId.substring(0, 8)}...',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACCEPTED',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Contact being shared
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Contact: ${recipient.contactName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Channel access information
            if (recipient.sharesAllChannels) ...[
              Row(
                children: [
                  const Icon(Icons.all_inclusive, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Access: All Channels',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Access: ${recipient.allowedChannels.length} Channel(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // List of allowed channels
            if (recipient.allowedChannels.isNotEmpty) ...[
              const Text(
                'Allowed Channels:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...recipient.allowedChannels.map((channel) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      _getChannelIcon(channel.kind),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${channel.label ?? channel.kind}: ${channel.value}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else if (!recipient.sharesAllChannels) ...[
              const Text(
                'No channels shared',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),

            // Metadata
            Text(
              'Share ID: ${recipient.share.id}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Created: ${_formatDateTime(recipient.share.createdAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getChannelIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'email':
        return const Icon(Icons.email, size: 16);
      case 'phone':
      case 'mobile':
        return const Icon(Icons.phone, size: 16);
      case 'whatsapp':
        return const Icon(Icons.chat, size: 16);
      case 'telegram':
        return const Icon(Icons.telegram, size: 16);
      case 'instagram':
        return const Icon(Icons.camera_alt, size: 16);
      case 'linkedin':
        return const Icon(Icons.work, size: 16);
      default:
        return const Icon(Icons.contact_page, size: 16);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Internal data structure to hold recipient info with their allowed channels
class _ShareRecipientInfo {
  final ContactShareModel share;
  final String recipientUsername;
  final String recipientId;
  final String contactName;
  final List<ContactChannelModel> allowedChannels;
  final bool sharesAllChannels;

  _ShareRecipientInfo({
    required this.share,
    required this.recipientUsername,
    required this.recipientId,
    required this.contactName,
    required this.allowedChannels,
    required this.sharesAllChannels,
  });
}
