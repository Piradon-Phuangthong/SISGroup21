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
                        final about = _aboutText(data);

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
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OmadaTokens.space16,
                              vertical: OmadaTokens.space16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AboutSection(title: about, textColor: Colors.black87),
                                const SizedBox(height: OmadaTokens.space16),
                                _ChannelCirclesGrid(
                                  channels: data.channels,
                                  selectedIds: _selectedChannelIds,
                                  onOpen: (id) {
                                    final ch =
                                        data.channels.firstWhere((c) => c.id == id);
                                    _launcher.openChannel(context, ch);
                                  },
                                  onLongPress: (id) =>
                                      _onChannelLongPress(context, data, id),
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
            OmadaTokens.space8,
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
              final panelGradient = const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: palette,
              );
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
                backgroundGradient: panelGradient,
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

// Local compact grid of white circular channel icons
class _ChannelCirclesGrid extends StatelessWidget {
  final List<ContactChannelModel> channels;
  final Set<String> selectedIds;
  final void Function(String id) onOpen;
  final void Function(String id)? onLongPress;

  const _ChannelCirclesGrid({
    required this.channels,
    required this.selectedIds,
    required this.onOpen,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
  final c = channels[index];
  final isSelected = selectedIds.contains(c.id);
  // Use the same icon mapping used across the app (Contacts, Contact Card)
  final iconData = ChannelKind.getIcon(c.kind).icon ?? Icons.link;
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onOpen(c.id),
          onLongPress: onLongPress == null ? null : () => onLongPress!(c.id),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(iconData, color: Colors.black87, size: 22),
          ),
        );
      },
    );
  }
}

