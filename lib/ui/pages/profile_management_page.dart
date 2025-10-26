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
import 'profile/channel_grid.dart';
import 'profile/cta_panel.dart';
import 'profile/about_section.dart';
import 'profile/avatar.dart';
import 'package:omada/core/theme/design_tokens.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  late Future<ProfileData> _future;
  final Set<String> _selectedChannelIds = <String>{};
  final ChannelLauncher _launcher = const ChannelLauncher();

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
    // final colorBg1 = const Color(0xFF7F0F24);
    // final colorBg2 = const Color(0xFF3C0A16);
    // final colorCard = const Color(0xFF3B0D18); // reserved for future use
    final colorPill = const Color(0xFF1d4ed8); // Blue-700
    final colorPillActive = const Color(0xFF93c5fd); // Blue-300
    final colorText = Colors.white;
    // final colorMuted = const Color(0xFFF5D6D1).withOpacity(0.8);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.2,
            colors: [
              Color(0xFF7dd3fc), // Sky-300
              Color(0xFF60a5fa), // Blue-400
              Color(0xFF3b82f6), // Blue-500
              Color(0xFF2563eb), // Blue-600
              Color(0xFF1d4ed8), // Blue-700
              Color(0xFF1e40af), // Blue-800
              Color(0xFF3730a3), // Indigo-700
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.78, 0.9, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                        Icon(Icons.circle, size: 22, color: colorText),
                        const SizedBox(width: OmadaTokens.space8),
                        Text(
                          'Omada',
                          style: TextStyle(
                            color: colorText,
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
                          Navigator.of(
                            context,
                          ).pushNamed('/account'); // or pushReplacementNamed
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Data-driven content
              Expanded(
                child: FutureBuilder<ProfileData>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Failed to load profile. ${snapshot.error ?? ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    final displayName =
                        data.profile?.username ?? data.contact.displayName;
                    final notes = data.contact.notes;
                    final about = _aboutText(data);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                          ),
                          child: Column(
                            children: [
                              Avatar(
                                displayName: displayName,
                                colorText: colorText,
                              ),
                              const SizedBox(height: OmadaTokens.space4),
                              if (notes?.isNotEmpty == true)
                                Text(
                                  notes!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorText.withOpacity(0.85),
                                  ),
                                ),
                              const SizedBox(height: OmadaTokens.space12),
                              AboutSection(title: about, textColor: colorText),
                            ],
                          ),
                        ),

                        const SizedBox(height: OmadaTokens.space16),

                        // Channel chips grid
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                          ),
                          child: ChannelGrid(
                            colorPill: colorPill,
                            colorPillActive: colorPillActive,
                            colorText: colorText,
                            channels: data.channels,
                            selectedIds: _selectedChannelIds,
                            onOpen: (id) {
                              final ch = data.channels.firstWhere(
                                (c) => c.id == id,
                              );
                              _launcher.openChannel(context, ch);
                            },
                            onLongPress: (id) =>
                                _onChannelLongPress(context, data, id),
                          ),
                        ),

                        const SizedBox(height: OmadaTokens.space12),

                        // CTA / actions panel
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OmadaTokens.space16,
                          ),
                          child: CtaPanel(
                            centerValue: _selectedChannelIds.isEmpty
                                ? 'Request'
                                : '${_selectedChannelIds.length} selected',
                            onAdd: () => _openAddChannel(context, data),
                            onShare: () => _openShare(context, data),
                            onQuickCall: () => _quickCall(context, data),
                          ),
                        ),

                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: OmadaTokens.space8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.profile),
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

String _aboutText(ProfileData data) {
  if (data.contact.notes?.isNotEmpty == true) return data.contact.notes!;
  if (data.channels.isNotEmpty) {
    final kinds = data.channels
        .map((c) => _labelForChannel(c))
        .toSet()
        .join(' · ');
    return 'Channels: $kinds';
  }
  return 'Set up your preferred contact channels and profile details.';
}
