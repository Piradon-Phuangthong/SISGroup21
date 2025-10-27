import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/ui/widgets/add_channel_sheet.dart';
import 'package:omada/core/data/utils/channel_launcher.dart';
import 'package:omada/core/controllers/profile_controller.dart';
import 'profile/cta_panel.dart';
import 'profile/avatar.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omada/core/data/utils/channel_presets.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  late Future<ProfileData> _future;
  final Set<String> _selectedChannelIds = <String>{};
  final ChannelLauncher _launcher = const ChannelLauncher();
  bool _defaultPrimaryEnsured = false;
  String _quickActionValue = 'Call';
  IconData _quickActionIcon = Icons.call;

  @override
  void initState() {
    super.initState();
    _future = ProfileController(Supabase.instance.client).load();
  }

  void _refresh() {
    setState(() {
      _future = ProfileController(Supabase.instance.client).load();
    });
  }

  ContactChannelModel? _findQuickTarget(ProfileData data) {
    // Prefer primary with value/url
    final primary = data.channels
        .where((c) => c.isPrimary)
        .firstWhere(
          (c) => (c.value?.isNotEmpty == true) || (c.url?.isNotEmpty == true),
          orElse: () => ContactChannelModel(
            id: '',
            ownerId: data.contact.ownerId,
            contactId: data.contact.id,
            kind: '',
            label: null,
            value: null,
            url: null,
            extra: null,
            isPrimary: false,
            updatedAt: DateTime.now(),
          ),
        );
    if (primary.id.isNotEmpty) return primary;

    // Fallback: phone/mobile
    final phone = data.channels.firstWhere(
      (c) =>
          (c.kind.toLowerCase() == 'phone' ||
              c.kind.toLowerCase() == 'mobile') &&
          (c.value?.isNotEmpty == true),
      orElse: () => ContactChannelModel(
        id: '',
        ownerId: data.contact.ownerId,
        contactId: data.contact.id,
        kind: '',
        label: null,
        value: null,
        url: null,
        extra: null,
        isPrimary: false,
        updatedAt: DateTime.now(),
      ),
    );
    if (phone.id.isNotEmpty) return phone;

    // Any with value/url
    final any = data.channels.firstWhere(
      (c) => (c.value?.isNotEmpty == true) || (c.url?.isNotEmpty == true),
      orElse: () => ContactChannelModel(
        id: '',
        ownerId: data.contact.ownerId,
        contactId: data.contact.id,
        kind: '',
        label: null,
        value: null,
        url: null,
        extra: null,
        isPrimary: false,
        updatedAt: DateTime.now(),
      ),
    );
    return any.id.isNotEmpty ? any : null;
  }

  void _updateQuickLabel(ProfileData data) {
    final target = _findQuickTarget(data);
    String action;
    IconData icon;
    switch (target?.kind.toLowerCase() ?? '') {
      case 'mobile':
      case 'phone':
        action = 'Call';
        icon = Icons.call;
        break;
      case 'sms':
        action = 'SMS';
        icon = Icons.sms;
        break;
      case 'email':
        action = 'Email';
        icon = Icons.email_outlined;
        break;
      case 'whatsapp':
        action = 'Message';
        icon = Icons.chat;
        break;
      case 'telegram':
        action = 'Telegram';
        icon = Icons.send;
        break;
      case 'instagram':
        action = 'DM';
        icon = Icons.send;
        break;
      case 'linkedin':
        action = 'Message';
        icon = Icons.message;
        break;
      case 'website':
        action = 'Open';
        icon = Icons.public;
        break;
      default:
        action = 'Open';
        icon = Icons.open_in_new;
    }
    if (mounted) {
      setState(() {
        _quickActionValue = action;
        _quickActionIcon = icon;
      });
    } else {
      _quickActionValue = action;
      _quickActionIcon = icon;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double topHeaderHeight =
        315; // Gradient visible down to just below username
    final colorTextOnHeader = Colors.white;
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Color.fromARGB(255, 29, 26, 33)
          : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Top ombre section with new palette
          Container(
            height: topHeaderHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1.1),
                radius: 1.25,
                colors: [
                  Color(0xFFF15A29), // Warm Coral-Orange (top left)
                  Color(0xFFE03C8A), // Magenta-Pink (mid)
                  Color(0xFF7B3FE4), // Violet-Purple (bottom right)
                  Color(0xFF5E2CCF), // Deep Purple (lower section)
                ],
                stops: [0.0, 0.45, 0.8, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top minimal header over the gradient
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OmadaTokens.space16,
                    vertical: OmadaTokens.space12,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 22,
                            color: colorTextOnHeader,
                          ),
                          const SizedBox(width: OmadaTokens.space8),
                          Text(
                            'Omada',
                            style: TextStyle(
                              color: colorTextOnHeader,
                              fontWeight: FontWeight.w800,
                              fontSize: OmadaTokens.fontLg,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          tooltip: 'Account',
                          icon: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/account');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Body scrollable area on white background
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 120),
                    child: FutureBuilder<ProfileData>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Failed to load profile. ${snapshot.error ?? ''}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final displayName =
                            data.profile?.username ?? data.contact.displayName;
                        final notes = data.contact.notes;

                        // Ensure there's a default primary (prefer Mobile) once after load
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _ensureDefaultPrimaryIfNeeded(data);
                          _updateQuickLabel(data);
                        });

                        // Top section (on gradient): Avatar + name (+ optional notes)
                        final headerOnGradient = Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                            vertical: OmadaTokens.space8,
                          ),
                          child: Column(
                            children: [
                              Avatar(
                                displayName: displayName,
                                colorText: Colors.white,
                              ),
                              const SizedBox(height: OmadaTokens.space4),
                              if (notes?.isNotEmpty == true)
                                Text(
                                  notes!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        );

                        // Rest of screen on white background
                        final bodyOnWhite = Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              OmadaTokens.space16,
                              OmadaTokens.space32,
                              OmadaTokens.space16,
                              OmadaTokens.space16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Your Channels',
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontSize: OmadaTokens.fontXl,
                                        fontWeight: OmadaTokens.weightBold,
                                        color: isDark
                                            ? Colors.white
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.92),
                                      ) ??
                                      TextStyle(
                                        fontSize: OmadaTokens.fontXl,
                                        fontWeight: OmadaTokens.weightBold,
                                        color: isDark
                                            ? Colors.black
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.92),
                                      ),
                                ),
                                const SizedBox(height: OmadaTokens.space12),
                                _ChannelList(
                                  channels: data.channels,
                                  selectedIds: _selectedChannelIds,
                                  onOpen: (id) {
                                    _onChannelLongPress(context, data, id);
                                  },
                                  onLongPress: (id) =>
                                      _showChannelActions(context, data, id),
                                  onTogglePrimary: (id) =>
                                      _setPrimaryChannel(context, data, id),
                                  onEdit: (id) =>
                                      _editChannel(context, data, id),
                                  onDelete: (id) =>
                                      _deleteChannel(context, data, id),
                                ),
                                // extra space so list isn't hidden behind bottom sheet CTA
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [headerOnGradient, bodyOnWhite],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.profile),
      bottomSheet: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OmadaTokens.space16,
            0,
            OmadaTokens.space16,
            OmadaTokens.space20,
          ),
          child: Builder(
            builder: (context) {
              // New palette for Share (Request) button
              const palette = <Color>[
                Color(0xFFF15A29), // Warm Coral-Orange
                Color(0xFFE03C8A), // Magenta-Pink
                Color(0xFF7B3FE4), // Violet-Purple
                Color(0xFF5E2CCF), // Deep Purple
              ];
              final callButtonGradient = const RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.0,
                colors: palette,
                stops: [0.0, 0.5, 0.8, 1.0],
              );

              return CtaPanel(
                centerValue: _selectedChannelIds.isEmpty
                    ? 'Request'
                    : '${_selectedChannelIds.length} selected',
                onAdd: () async {
                  final snapshot = await _future;
                  if (!mounted) return;
                  await _openAddChannel(context, snapshot);
                },
                onShare: () async {
                  final snapshot = await _future;
                  if (!mounted) return;
                  await _openShare(context, snapshot);
                },
                onQuickCall: () async {
                  final snapshot = await _future;
                  if (!mounted) return;
                  await _quickCall(context, snapshot);
                },
                backgroundColor: isDark ? Colors.deepPurple[800] : Colors.white,
                callButtonGradient: callButtonGradient,
                quickTitleOverride: 'Quick',
                quickValueOverride: _quickActionValue,
                quickIconOverride: _quickActionIcon,
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedChannelIds.contains(id)) {
        _selectedChannelIds.remove(id);
      } else {
        _selectedChannelIds.add(id);
      }
    });
  }

  Future<void> _setPrimaryChannel(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    final repo = ContactChannelRepository(Supabase.instance.client);
    // Ensure only one primary across all channels: set selected to true, others false
    for (final ch in data.channels) {
      final shouldBePrimary = ch.id == id;
      if (ch.isPrimary != shouldBePrimary) {
        await repo.updateChannel(ch.id, isPrimary: shouldBePrimary);
      }
    }
    _refresh();
  }

  Future<void> _ensureDefaultPrimaryIfNeeded(ProfileData data) async {
    if (_defaultPrimaryEnsured) return;
    _defaultPrimaryEnsured = true;
    final hasPrimary = data.channels.any((c) => c.isPrimary);
    if (hasPrimary) return;

    // Prefer Mobile/Phone with a value; else any first channel
    ContactChannelModel? target;
    for (final ch in data.channels) {
      final k = ch.kind.toLowerCase();
      if ((k == 'mobile' || k == 'phone') && (ch.value?.isNotEmpty == true)) {
        target = ch;
        break;
      }
    }
    target ??= data.channels.isNotEmpty ? data.channels.first : null;
    if (target == null) return;

    final repo = ContactChannelRepository(Supabase.instance.client);
    // Set target as primary and unset others to be explicit
    for (final ch in data.channels) {
      final shouldBePrimary = ch.id == target.id;
      if (ch.isPrimary != shouldBePrimary) {
        await repo.updateChannel(ch.id, isPrimary: shouldBePrimary);
      }
    }
    if (!mounted) return;
    _refresh();
  }

  Future<void> _onChannelLongPress(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    _toggleSelection(id);
    // await _showChannelActions(context, data, id);
  }

  Future<void> _showChannelActions(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    final ch = data.channels.firstWhere((c) => c.id == id);
    final repo = ContactChannelRepository(Supabase.instance.client);

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () => Navigator.pop(ctx, 'open'),
              ),
              if ((ch.kind.toLowerCase() == 'phone' ||
                      ch.kind.toLowerCase() == 'mobile' ||
                      ch.kind.toLowerCase() == 'sms') &&
                  (ch.value?.isNotEmpty == true))
                ListTile(
                  leading: const Icon(Icons.sms),
                  title: const Text('Send SMS'),
                  onTap: () => Navigator.pop(ctx, 'sms'),
                ),
              if (!ch.isPrimary)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: const Text('Set as primary'),
                  onTap: () => {
                    Navigator.pop(ctx, 'primary'),
                    _setPrimaryChannel(context, data, ch.id),
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );

    switch (selected) {
      case 'open':
        await _launcher.openChannel(context, ch);
        break;
      case 'primary':
        await repo.setPrimaryForKind(
          contactId: data.contact.id,
          kind: ch.kind,
          channelId: ch.id,
        );
        _refresh();
        break;
      case 'unprimary':
        await repo.updateChannel(ch.id, isPrimary: false);
        _refresh();
        break;
      case 'sms':
        final num = ch.value;
        if (num == null || num.isEmpty) break;
        final smsUri = Uri.parse('sms:$num');
        await launchUrl(smsUri);
        break;
      case 'delete':
        await _deleteChannel(context, data, ch.id);
        break;
      default:
        break;
    }
  }

  Future<void> _editChannel(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    final ch = data.channels.firstWhere((c) => c.id == id);
    final labelCtrl = TextEditingController(
      text: ch.label ?? _labelForChannel(ch),
    );
    final valueCtrl = TextEditingController(text: ch.value ?? '');
    String _computeUrl(String kind, String value) =>
        ChannelPresets.computeUrl(kind, value);
    String previewUrl = _computeUrl(ch.kind, valueCtrl.text);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Channel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kind: ${ch.kind}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(labelText: 'Value'),
                    onChanged: (v) =>
                        setState(() => previewUrl = _computeUrl(ch.kind, v)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: previewUrl),
                    decoration: const InputDecoration(labelText: 'URL (auto)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmed == true) {
      final repo = ContactChannelRepository(Supabase.instance.client);
      final newLabel = labelCtrl.text.trim();
      final newValue = valueCtrl.text.trim();
      final newUrl = _computeUrl(ch.kind, newValue);
      await repo.updateChannel(
        ch.id,
        label: newLabel.isEmpty ? null : newLabel,
        value: newValue.isEmpty ? null : newValue,
        url: newUrl.isEmpty ? null : newUrl,
      );
      if (!mounted) return;
      _refresh();
    }
  }

  Future<void> _deleteChannel(
    BuildContext context,
    ProfileData data,
    String id,
  ) async {
    final ch = data.channels.firstWhere((c) => c.id == id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Channel?'),
        content: Text(
          'Delete "${_labelForChannel(ch)}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ContactChannelRepository(Supabase.instance.client);
      await repo.deleteChannel(id);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Channel deleted')));
    }
  }

  Future<void> _quickCall(BuildContext context, ProfileData data) async {
    // Prefer explicit primary channel
    ContactChannelModel? target = data.channels.firstWhere(
      (c) =>
          c.isPrimary &&
          ((c.value?.isNotEmpty == true) || (c.url?.isNotEmpty == true)),
      orElse: () => ContactChannelModel(
        id: '',
        ownerId: data.contact.ownerId,
        contactId: data.contact.id,
        kind: '',
        label: null,
        value: null,
        url: null,
        extra: null,
        isPrimary: false,
        updatedAt: DateTime.now(),
      ),
    );

    if (target.id.isEmpty) {
      // Fallbacks: prefer phone/mobile with value, then any channel with value/url
      target = data.channels.firstWhere(
        (c) =>
            (c.kind.toLowerCase() == 'phone' ||
                c.kind.toLowerCase() == 'mobile') &&
            (c.value?.isNotEmpty == true),
        orElse: () => data.channels.firstWhere(
          (c) => (c.value?.isNotEmpty == true) || (c.url?.isNotEmpty == true),
          orElse: () => ContactChannelModel(
            id: '',
            ownerId: data.contact.ownerId,
            contactId: data.contact.id,
            kind: '',
            label: null,
            value: null,
            url: null,
            extra: null,
            isPrimary: false,
            updatedAt: DateTime.now(),
          ),
        ),
      );
    }

    if (target.id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No channel available to open')),
      );
      return;
    }

    await _launcher.openChannel(context, target);
  }

  Future<void> _openAddChannel(BuildContext context, ProfileData data) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddChannelSheet(contactId: data.contact.id),
    );
    if (result == true) _refresh();
  }

  Future<void> _openShare(BuildContext context, ProfileData data) async {
    final sharing = SharingService(Supabase.instance.client);
    final usernameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Share channels'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter recipient username'),
              const SizedBox(height: 8),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'username'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // For now, send a simple share request (no field mask per-channel provided here)
      await sharing.sendShareRequest(
        recipientUsername: usernameCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Share request sent')));
    }
  }
}

// Old local nav item removed; using shared AppBottomNav

// Data aggregation
// Helpers for mapping and display
String _labelForChannel(ContactChannelModel c) {
  if (c.label?.isNotEmpty == true) return c.label!;
  switch (c.kind.toLowerCase()) {
    case 'mobile':
    case 'phone':
      return 'Mobile';
    case 'email':
      return 'Email';
    case 'instagram':
      return 'Instagram';
    case 'linkedin':
      return 'LinkedIn';
    case 'whatsapp':
      return 'WhatsApp';
    case 'website':
      return 'Website';
    case 'messenger':
      return 'Messenger';
    case 'address':
      return 'Address';
    default:
      return c.kind;
  }
}

// _iconForKind moved into ChannelGrid; removed here

// Local compact grid of white circular channel icons
// Vertical list of channels with colored icons and label
class _ChannelList extends StatelessWidget {
  final List<ContactChannelModel> channels;
  final Set<String> selectedIds;
  final void Function(String id) onOpen;
  final void Function(String id)? onLongPress;
  final void Function(String id) onTogglePrimary;
  final void Function(String id) onEdit;
  final void Function(String id) onDelete;

  const _ChannelList({
    required this.channels,
    required this.selectedIds,
    required this.onOpen,
    this.onLongPress,
    required this.onTogglePrimary,
    required this.onEdit,
    required this.onDelete,
  });

  Color _colorForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'mobile':
      case 'phone':
      case 'call':
      case 'sms':
        return Colors.green.shade600;
      case 'email':
        return Colors.red.shade600;
      case 'whatsapp':
        return Colors.green.shade500;
      case 'telegram':
        return Colors.blue.shade400;
      case 'instagram':
        return Colors.purple.shade400;
      case 'linkedin':
        return Colors.blue.shade700;
      case 'website':
        return Colors.indigo.shade500;
      case 'address':
        return Colors.orange.shade600;
      case 'messenger':
        return Colors.blueAccent;
      default:
        return Colors.black87;
    }
  }

  IconData _faIconForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'mobile':
      case 'phone':
      case 'call':
        return FontAwesomeIcons.phone;
      case 'sms':
        return FontAwesomeIcons.message;
      case 'email':
        return FontAwesomeIcons.envelope;
      case 'whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'website':
        return FontAwesomeIcons.globe;
      case 'address':
        return FontAwesomeIcons.locationDot;
      default:
        return FontAwesomeIcons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white : Colors.black54;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final c = channels[index];
        final isSelected = selectedIds.contains(c.id);
        final iconData = _faIconForKind(c.kind);
        final kindIconColor = _colorForKind(c.kind);
        final label = _labelForChannel(c);
        final valueText = (c.value?.isNotEmpty == true)
            ? c.value!
            : (c.url?.isNotEmpty == true ? c.url! : '');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary channel badge
              if (c.isPrimary)
                Container(
                  // Remove padding and decoration from this container
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Primary Channel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Main content
              InkWell(
                onTap: () => onOpen(c.id),
                onLongPress: onLongPress == null
                    ? null
                    : () => onLongPress!(c.id),
                child: Container(
                  // padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Color.fromARGB(255, 29, 26, 33)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: c.isPrimary
                        ? Border.all(color: Colors.amber.shade600, width: 2)
                        : null,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border(
                              left: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 5,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: FaIcon(
                            iconData,
                            color: kindIconColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (valueText.isNotEmpty)
                                const SizedBox(height: 2),
                              if (valueText.isNotEmpty)
                                Text(
                                  valueText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Action buttons: edit, delete (star removed)
                        IconButton(
                          tooltip: 'Edit',
                          icon: Icon(Icons.edit, color: iconColor),
                          onPressed: () => onEdit(c.id),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => onDelete(c.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Subtle breathing animation wrapper for the avatar
// Breathing effect moved inside the Avatar so only the circle animates, not the username text.
