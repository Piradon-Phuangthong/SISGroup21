import 'package:flutter/material.dart';
import 'package:omada/core/data/models/shared_contact_data.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/controllers/contacts_controller.dart';
import 'package:omada/core/theme/design_tokens.dart';

/// Detail page for a shared contact (read-only view)
/// Shows only the information and channels that were shared with the user
class SharedContactDetailPage extends StatefulWidget {
  final SharedContactData sharedContact;
  final ContactsController controller;

  const SharedContactDetailPage({
    super.key,
    required this.sharedContact,
    required this.controller,
  });

  @override
  State<SharedContactDetailPage> createState() =>
      _SharedContactDetailPageState();
}

class _SharedContactDetailPageState extends State<SharedContactDetailPage> {
  List<ContactChannelModel>? _channels;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final channels =
          await widget.controller.getSharedChannelsForContact(
        contactId: widget.sharedContact.contact.id,
        share: widget.sharedContact.share,
      );

      if (mounted) {
        setState(() {
          _channels = channels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.sharedContact.contact;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName),
        actions: [
          // Info button to show sharing details
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sharing info',
            onPressed: _showSharingInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(OmadaTokens.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: OmadaTokens.space16),
                        Text(
                          'Error loading channels',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: OmadaTokens.space8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: OmadaTokens.space16),
                        ElevatedButton(
                          onPressed: _loadChannels,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with avatar and name
                      Container(
                        width: double.infinity,
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.3),
                        padding: const EdgeInsets.all(OmadaTokens.space24),
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage: contact.avatarUrl != null
                                  ? NetworkImage(contact.avatarUrl!)
                                  : null,
                              child: contact.avatarUrl == null
                                  ? Text(
                                      contact.initials,
                                      style: TextStyle(
                                        fontSize: 32,
                                        color: theme.colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: OmadaTokens.space16),
                            
                            // Name
                            Text(
                              contact.displayName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: OmadaTokens.space8),
                            
                            // Shared badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: OmadaTokens.space12,
                                vertical: OmadaTokens.space6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: OmadaTokens.radius12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 16,
                                    color: theme.colorScheme
                                        .onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Shared by @${widget.sharedContact.sharedBy}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: theme.colorScheme
                                          .onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Basic info section (if shared)
                      if (_hasBasicInfo()) ...[
                        const SizedBox(height: OmadaTokens.space24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                          ),
                          child: Text(
                            'Basic Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: OmadaTokens.space12),
                        _buildBasicInfoSection(theme),
                      ],

                      // Channels section
                      if (_channels != null && _channels!.isNotEmpty) ...[
                        const SizedBox(height: OmadaTokens.space24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                          ),
                          child: Text(
                            'Contact Channels',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: OmadaTokens.space12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                          ),
                          child: Column(
                            children: _channels!
                                .map((channel) => _buildChannelCard(channel))
                                .toList(),
                          ),
                        ),
                      ] else if (_channels != null && _channels!.isEmpty) ...[
                        const SizedBox(height: OmadaTokens.space24),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(OmadaTokens.space24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.link_off,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: OmadaTokens.space12),
                                Text(
                                  'No channels shared',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: OmadaTokens.space8),
                                Text(
                                  'This contact hasn\'t shared any contact channels with you.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: OmadaTokens.space24),
                    ],
                  ),
                ),
    );
  }

  bool _hasBasicInfo() {
    final share = widget.sharedContact.share;
    return share.includesField('primary_mobile') ||
        share.includesField('primary_email') ||
        share.includesField('notes');
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    final contact = widget.sharedContact.contact;
    final share = widget.sharedContact.share;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OmadaTokens.space16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(OmadaTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (share.includesField('primary_mobile') &&
                  contact.primaryMobile != null) ...[
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: contact.primaryMobile!,
                ),
                const Divider(height: OmadaTokens.space24),
              ],
              if (share.includesField('primary_email') &&
                  contact.primaryEmail != null) ...[
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: contact.primaryEmail!,
                ),
                if (share.includesField('notes') && contact.notes != null)
                  const Divider(height: OmadaTokens.space24),
              ],
              if (share.includesField('notes') && contact.notes != null) ...[
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.note_outlined,
                  label: 'Notes',
                  value: contact.notes!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: OmadaTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(ContactChannelModel channel) {
    final theme = Theme.of(context);
    final icon = _getIconForChannelKind(channel.kind);
    final label = channel.label ?? channel.kind;
    final value = channel.value ?? channel.url ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: OmadaTokens.space8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _onChannelTap(channel),
      ),
    );
  }

  IconData _getIconForChannelKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'mobile':
      case 'phone':
        return Icons.phone_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'whatsapp':
        return Icons.message_outlined;
      case 'instagram':
      case 'facebook':
      case 'twitter':
      case 'linkedin':
        return Icons.public;
      case 'address':
        return Icons.location_on_outlined;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  void _onChannelTap(ContactChannelModel channel) {
    // TODO: Implement channel interaction (call, message, open URL, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped ${channel.kind}: ${channel.value ?? channel.url}'),
      ),
    );
  }

  void _showSharingInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sharing Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This contact is shared with you by:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: OmadaTokens.space8),
            Text(
              '@${widget.sharedContact.sharedBy}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: OmadaTokens.space16),
            Text(
              'Shared on:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: OmadaTokens.space4),
            Text(
              _formatDate(widget.sharedContact.share.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: OmadaTokens.space16),
            Text(
              'You can view and interact with the shared information, but you cannot edit or delete this contact.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
