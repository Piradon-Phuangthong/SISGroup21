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

  @override
  Widget build(BuildContext context) {
    const double topHeaderHeight = 315; // Gradient visible down to just below username
    final colorTextOnHeader = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top blue ombre section (same palette and size as Contacts)
          Container(
            height: topHeaderHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1.1),
                radius: 1.2,
                colors: [
                  Color(0xFF7de3f8), // Light Cyan-Blue
                  Color(0xFF64bdfb), // Sky Blue
                  Color(0xFF5194fa), // Bright Blue
                  Color(0xFF6a7af7), // Periwinkle
                  Color(0xFF8765f3), // Soft Violet
                  Color(0xFFa257e8), // Medium Purple
                  Color(0xFFc44adf), // Magenta-Purple
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.78, 0.9, 1.0],
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
                          Icon(Icons.circle, size: 22, color: colorTextOnHeader),
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
                        });

                        // Top section (on gradient): Avatar + name (+ optional notes)
                        final headerOnGradient = Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                            vertical: OmadaTokens.space8,
                          ),
                          child: Column(
                            children: [
                              _Breathing(
                                minScale: 0.98,
                                maxScale: 1.04,
                                duration: const Duration(milliseconds: 2800),
                                child: Avatar(
                                  displayName: displayName,
                                  colorText: Colors.white,
                                ),
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
                          decoration: const BoxDecoration(
                            color: Colors.white,
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
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: OmadaTokens.fontXl,
                                        fontWeight: OmadaTokens.weightBold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.92),
                                      ) ??
                                      TextStyle(
                fontSize: OmadaTokens.fontXl,
                                        fontWeight: OmadaTokens.weightBold,
                                        color: Theme.of(context)
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
                                    final ch = data.channels.firstWhere((c) => c.id == id);
                                    _launcher.openChannel(context, ch);
                                  },
                                  onLongPress: (id) => _onChannelLongPress(context, data, id),
                                  onTogglePrimary: (id) => _setPrimaryChannel(context, data, id),
                                  onEdit: (id) => _editChannel(context, data, id),
                                  onDelete: (id) => _deleteChannel(context, data, id),
                                ),
                                // extra space so list isn't hidden behind bottom sheet CTA
                                const SizedBox(height: 120),
                              ],
                            ),
                          ),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            headerOnGradient,
                            bodyOnWhite,
                          ],
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
              // Gradient palette per request
              const palette = <Color>[
                Color(0xFF7de3f8),
                Color(0xFF64bdfb),
                Color(0xFF5194fa),
                Color(0xFF6a7af7),
                Color(0xFF8765f3),
                Color(0xFFa257e8),
                Color(0xFFc44adf),
              ];
              final callButtonGradient = const RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.0,
                colors: palette,
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
                backgroundColor: Colors.white,
                callButtonGradient: callButtonGradient,
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
    await _showChannelActions(context, data, id);
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
                  onTap: () => Navigator.pop(ctx, 'primary'),
                ),
              if (ch.isPrimary)
                ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: const Text('Unset primary'),
                  onTap: () => Navigator.pop(ctx, 'unprimary'),
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
    final labelCtrl = TextEditingController(text: ch.label ?? _labelForChannel(ch));
    final valueCtrl = TextEditingController(text: ch.value ?? '');
    String _computeUrl(String kind, String value) => ChannelPresets.computeUrl(kind, value);
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
                  const Text('Edit Channel', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Kind: ${ch.kind}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(labelText: 'Value'),
                    onChanged: (v) => setState(() => previewUrl = _computeUrl(ch.kind, v)),
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
                  )
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
        content: Text('Delete "${_labelForChannel(ch)}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Channel deleted')));
    }
  }

  Future<void> _quickCall(BuildContext context, ProfileData data) async {
    String? number = data.contact.primaryMobile;
    if (number == null || number.isEmpty) {
      final primaryPhone = data.channels.firstWhere(
        (c) =>
            (c.kind.toLowerCase() == 'phone' ||
                c.kind.toLowerCase() == 'mobile') &&
            c.isPrimary &&
            (c.value?.isNotEmpty == true),
        orElse: () => data.channels.firstWhere(
          (c) =>
              (c.kind.toLowerCase() == 'phone' ||
                  c.kind.toLowerCase() == 'mobile') &&
              (c.value?.isNotEmpty == true),
          orElse: () => ContactChannelModel(
            id: '_',
            ownerId: data.contact.ownerId,
            contactId: data.contact.id,
            kind: 'phone',
            label: null,
            value: '',
            url: null,
            extra: null,
            isPrimary: false,
            updatedAt: DateTime.now(),
          ),
        ),
      );
      number = primaryPhone.value;
    }

    if (number == null || number.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No number available')));
      return;
    }

    final telUri = Uri.parse('tel:$number');
    if (!await launchUrl(telUri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open dialer')));
    }
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
    case 'telegram':
      return 'Telegram';
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
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.7),
      itemBuilder: (context, index) {
        final c = channels[index];
        final isSelected = selectedIds.contains(c.id);
        final iconData = _faIconForKind(c.kind);
        final iconColor = _colorForKind(c.kind);
        final label = _labelForChannel(c);
        final valueText = (c.value?.isNotEmpty == true)
            ? c.value!
            : (c.url?.isNotEmpty == true ? c.url! : '');

        return InkWell(
          onTap: () => onOpen(c.id),
          onLongPress: onLongPress == null ? null : () => onLongPress!(c.id),
          child: Container
          (
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isSelected
                  ? Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: FaIcon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons: edit, star (primary), delete
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () => onEdit(c.id),
                ),
                IconButton(
                  tooltip: c.isPrimary ? 'Primary' : 'Set as primary',
                  icon: Icon(
                    c.isPrimary ? Icons.star : Icons.star_border,
                    color: c.isPrimary ? Colors.amber.shade600 : Colors.black38,
                  ),
                  onPressed: () => onTogglePrimary(c.id),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => onDelete(c.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Subtle breathing animation wrapper for the avatar
class _Breathing extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const _Breathing({
    required this.child,
    this.minScale = 0.98,
    this.maxScale = 1.04,
    this.duration = const Duration(milliseconds: 2800),
  });

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _scale = Tween<double>(begin: widget.minScale, end: widget.maxScale)
        .animate(curved);

    // Respect reduced motion if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mq = context.mounted ? MediaQuery.maybeOf(context) : null;
      final disable = mq?.disableAnimations ?? false;
      if (!disable && mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final disable = mq?.disableAnimations ?? false;
    if (disable) return widget.child;

    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

