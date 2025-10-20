import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/models/models.dart';

/// Test page to show all contacts shared with YOU (where you are the recipient)
/// and the specific channels you have been granted access to
class ReceivedSharesTestPage extends StatefulWidget {
  const ReceivedSharesTestPage({super.key});

  @override
  State<ReceivedSharesTestPage> createState() => _ReceivedSharesTestPageState();
}

class _ReceivedSharesTestPageState extends State<ReceivedSharesTestPage> {
  late final ContactChannelRepository _channelRepo;
  
  List<_ReceivedShareInfo> _receivedShares = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _channelRepo = ContactChannelRepository(client);
    _loadReceivedShares();
  }

  Future<void> _loadReceivedShares() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      // Query contact_shares where current user is the RECIPIENT (to_user_id)
      // and the share is active (not revoked)
      final response = await Supabase.instance.client
          .from('contact_shares')
          .select('''
            *,
            owner:profiles!contact_shares_owner_id_fkey(id, username),
            contact:contacts(id, full_name, given_name, family_name)
          ''')
          .eq('to_user_id', userId)
          .isFilter('revoked_at', null)
          .order('created_at', ascending: false);

      debugPrint('=== Received Shares Query Response ===');
      debugPrint('Raw data: $response');

      final List<_ReceivedShareInfo> sharesList = [];

      for (final shareJson in response as List<dynamic>) {
        final share = ContactShareModel.fromJson(shareJson);
        final ownerData = shareJson['owner'] as Map<String, dynamic>?;
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

        // Get all channels for this contact
        final allChannels = await _channelRepo.getChannelsForContact(
          share.contactId,
        );

        // Filter channels based on field_mask (what WE have access to)
        final List<ContactChannelModel> accessibleChannels = [];
        
        if (share.sharesAllChannels) {
          // We have access to all channels
          accessibleChannels.addAll(allChannels);
        } else {
          // We only have access to specific channels
          final sharedChannelIds = share.sharedChannelIds;
          for (final channel in allChannels) {
            if (sharedChannelIds.contains(channel.id)) {
              accessibleChannels.add(channel);
            }
          }
        }

        sharesList.add(_ReceivedShareInfo(
          share: share,
          ownerUsername: ownerData?['username'] as String? ?? 'Unknown',
          ownerId: ownerData?['id'] as String? ?? share.ownerId,
          contactName: contactName,
          accessibleChannels: accessibleChannels,
          hasAllChannels: share.sharesAllChannels,
        ));
      }

      setState(() {
        _receivedShares = sharesList;
        _loading = false;
      });

      debugPrint('=== Received Shares Loaded ===');
      debugPrint('Total shares received: ${sharesList.length}');
      for (final share in sharesList) {
        debugPrint('  - ${share.contactName} from ${share.ownerUsername}: ${share.accessibleChannels.length} channels');
      }
    } catch (e, stackTrace) {
      debugPrint('=== Error Loading Received Shares ===');
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
        title: const Text('Contacts Shared With Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceivedShares,
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
                onPressed: _loadReceivedShares,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_receivedShares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Contacts Shared With You',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'When others share contacts with you,\nthey will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receivedShares.length,
      itemBuilder: (context, index) {
        final share = _receivedShares[index];
        return _buildShareCard(share);
      },
    );
  }

  Widget _buildShareCard(_ReceivedShareInfo share) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with contact name and status
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    share.contactName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.contactName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Shared by @${share.ownerUsername}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RECEIVED',
                    style: TextStyle(
                      color: Colors.purple,
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

            // Access level information
            if (share.hasAllChannels) ...[
              Row(
                children: [
                  const Icon(Icons.all_inclusive, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'You have access to: All Channels',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
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
                    'You have access to: ${share.accessibleChannels.length} Channel(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // List of accessible channels
            if (share.accessibleChannels.isNotEmpty) ...[
              const Text(
                'Your Accessible Channels:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...share.accessibleChannels.map((channel) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        _getChannelIcon(channel.kind),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                channel.label ?? channel.kind.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                channel.value ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ] else if (!share.hasAllChannels) ...[
              const Text(
                'No channels accessible',
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
              'Share ID: ${share.share.id}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              'Received: ${_formatDateTime(share.share.createdAt)}',
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
        return const Icon(Icons.email, size: 20, color: Colors.blue);
      case 'phone':
      case 'mobile':
        return const Icon(Icons.phone, size: 20, color: Colors.green);
      case 'whatsapp':
        return const Icon(Icons.chat, size: 20, color: Colors.green);
      case 'telegram':
        return const Icon(Icons.telegram, size: 20, color: Colors.blue);
      case 'instagram':
        return const Icon(Icons.camera_alt, size: 20, color: Colors.pink);
      case 'linkedin':
        return const Icon(Icons.work, size: 20, color: Colors.blue);
      case 'twitter':
      case 'x':
        return const Icon(Icons.alternate_email, size: 20, color: Colors.black);
      default:
        return const Icon(Icons.contact_page, size: 20, color: Colors.grey);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Internal data structure to hold received share info with accessible channels
class _ReceivedShareInfo {
  final ContactShareModel share;
  final String ownerUsername;
  final String ownerId;
  final String contactName;
  final List<ContactChannelModel> accessibleChannels;
  final bool hasAllChannels;

  _ReceivedShareInfo({
    required this.share,
    required this.ownerUsername,
    required this.ownerId,
    required this.contactName,
    required this.accessibleChannels,
    required this.hasAllChannels,
  });
}
