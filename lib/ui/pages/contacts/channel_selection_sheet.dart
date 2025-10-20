import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/repositories/contact_repository.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/core/data/utils/channel_presets.dart';
import 'package:omada/core/theme/design_tokens.dart';

/// Sheet for selecting which contact channels to share when accepting a share request
class ChannelSelectionSheet extends StatefulWidget {
  final ShareRequestWithProfile request;
  final SharingService sharingService;
  final ContactRepository contactRepository;
  final ContactChannelRepository contactChannelRepository;

  const ChannelSelectionSheet({
    super.key,
    required this.request,
    required this.sharingService,
    required this.contactRepository,
    required this.contactChannelRepository,
  });

  @override
  State<ChannelSelectionSheet> createState() => _ChannelSelectionSheetState();
}

class _ChannelSelectionSheetState extends State<ChannelSelectionSheet> {
  bool _loading = true;
  String? _errorMessage;
  List<ContactChannelModel> _channels = [];
  Set<String> _selectedChannelIds = {};
  bool _accepting = false;

  int get _selectedCount => _selectedChannelIds.length;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  void _toggleChannel(String channelId) {
    setState(() {
      if (_selectedChannelIds.contains(channelId)) {
        _selectedChannelIds.remove(channelId);
      } else {
        _selectedChannelIds.add(channelId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedChannelIds = _channels.map((c) => c.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedChannelIds.clear();
    });
  }

  Future<void> _loadChannels() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Get user's own contact
      final myContact = await widget.contactRepository.getMyOwnContact();

      if (myContact == null) {
        setState(() {
          _errorMessage = 'Your profile contact was not found. Please set up your profile first.';
          _loading = false;
        });
        return;
      }

      // Get all channels for the user's contact
      final channels = await widget.contactChannelRepository.getChannelsForContact(
        myContact.id,
      );

      setState(() {
        _channels = channels;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load channels: $e';
        _loading = false;
      });
    }
  }

  IconData _getIconForChannelKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'mobile':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.work;
      case 'whatsapp':
        return Icons.message;
      case 'messenger':
        return Icons.chat;
      default:
        return Icons.link;
    }
  }



  @override
  Widget build(BuildContext context) {
    final requesterUsername = widget.request.requesterProfile?.username ?? 'Unknown User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.5, 0.8, 0.95],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(OmadaTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: OmadaTokens.space8),

                    // Requester info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            requesterUsername[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: OmadaTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose what to share',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'with @$requesterUsername',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OmadaTokens.space16),

                    // Selection controls (shown only when channels are loaded)
                    if (!_loading && _errorMessage == null && _channels.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OmadaTokens.space12,
                          vertical: OmadaTokens.space8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: OmadaTokens.space8),
                            Expanded(
                              child: Text(
                                _selectedCount == 0
                                    ? 'Select channels to share'
                                    : '$_selectedCount channel${_selectedCount == 1 ? '' : 's'} selected',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _selectedCount == _channels.length ? _clearSelection : _selectAll,
                              icon: Icon(
                                _selectedCount == _channels.length ? Icons.clear : Icons.select_all,
                                size: 18,
                              ),
                              label: Text(_selectedCount == _channels.length ? 'Clear' : 'Select All'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: OmadaTokens.space12,
                                  vertical: OmadaTokens.space4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: OmadaTokens.space16),
                    ],

                    // Content
                    Expanded(
                      child: _loading
                          ? _buildLoadingState()
                          : _errorMessage != null
                              ? _buildErrorState()
                              : _channels.isEmpty
                                  ? _buildEmptyState()
                                  : _buildChannelsList(scrollController),
                    ),

                    // Accept & Share button (shown only when channels are available)
                    if (!_loading && _errorMessage == null && _channels.isNotEmpty) ...[
                      const SizedBox(height: OmadaTokens.space16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _selectedCount == 0 || _accepting ? null : _acceptAndShare,
                          icon: _accepting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _accepting 
                                ? 'Processing...' 
                                : 'Accept & Share ($_selectedCount)',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: OmadaTokens.space16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _acceptAndShare() async {
    // TODO: Implement in User Story 3
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accept & Share functionality coming in User Story 3'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: OmadaTokens.space16),
          Text('Loading your channels...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OmadaTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: OmadaTokens.space16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OmadaTokens.space8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OmadaTokens.space24),
            FilledButton.icon(
              onPressed: _loadChannels,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OmadaTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: OmadaTokens.space16),
            Text(
              'No channels to share',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OmadaTokens.space8),
            Text(
              "You haven't added any contact channels yet. Add channels to your profile before accepting share requests.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OmadaTokens.space24),
            FilledButton.icon(
              onPressed: () {
                // TODO: Navigate to profile/channel management
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Channels'),
            ),
            const SizedBox(height: OmadaTokens.space8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelsList(ScrollController scrollController) {
    // Group channels by category
    final phoneChannels = <ContactChannelModel>[];
    final emailChannels = <ContactChannelModel>[];
    final socialChannels = <ContactChannelModel>[];
    final otherChannels = <ContactChannelModel>[];

    for (final channel in _channels) {
      final kind = channel.kind.toLowerCase();
      if (kind == 'mobile') {
        phoneChannels.add(channel);
      } else if (kind == 'email') {
        emailChannels.add(channel);
      } else if (['instagram', 'linkedin', 'whatsapp', 'messenger'].contains(kind)) {
        socialChannels.add(channel);
      } else {
        otherChannels.add(channel);
      }
    }

    return ListView(
      controller: scrollController,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(OmadaTokens.space16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: OmadaTokens.space12),
              Expanded(
                child: Text(
                  'Tap on channels to select which ones you want to share. Only selected channels will be visible to the requester.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: OmadaTokens.space24),

        // Phone Numbers
        if (phoneChannels.isNotEmpty) ...[
          _buildGroupHeader('Phone Numbers', phoneChannels.length),
          const SizedBox(height: OmadaTokens.space8),
          ...phoneChannels.map((channel) => _buildChannelCard(channel)),
          const SizedBox(height: OmadaTokens.space16),
        ],

        // Email Addresses
        if (emailChannels.isNotEmpty) ...[
          _buildGroupHeader('Email Addresses', emailChannels.length),
          const SizedBox(height: OmadaTokens.space8),
          ...emailChannels.map((channel) => _buildChannelCard(channel)),
          const SizedBox(height: OmadaTokens.space16),
        ],

        // Social Media
        if (socialChannels.isNotEmpty) ...[
          _buildGroupHeader('Social Media', socialChannels.length),
          const SizedBox(height: OmadaTokens.space8),
          ...socialChannels.map((channel) => _buildChannelCard(channel)),
          const SizedBox(height: OmadaTokens.space16),
        ],

        // Other Channels
        if (otherChannels.isNotEmpty) ...[
          _buildGroupHeader('Other Channels', otherChannels.length),
          const SizedBox(height: OmadaTokens.space8),
          ...otherChannels.map((channel) => _buildChannelCard(channel)),
          const SizedBox(height: OmadaTokens.space16),
        ],

        const SizedBox(height: 80), // Space for bottom padding
      ],
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: OmadaTokens.space8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OmadaTokens.space8,
            vertical: OmadaTokens.space4,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(ContactChannelModel channel) {
    final icon = _getIconForChannelKind(channel.kind);
    final label = channel.label ?? ChannelPresets.presets[channel.kind.toLowerCase()]?['label'] ?? channel.kind;
    final value = channel.value ?? channel.url ?? '';
    final isSelected = _selectedChannelIds.contains(channel.id);

    return Card(
      margin: const EdgeInsets.only(bottom: OmadaTokens.space8),
      elevation: isSelected ? 2 : 1,
      color: isSelected 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) => _toggleChannel(channel.id),
        secondary: CircleAvatar(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
            if (channel.isPrimary)
              Chip(
                label: const Text('Primary'),
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        subtitle: value.isNotEmpty
            ? Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : null,
      ),
    );
  }
}
