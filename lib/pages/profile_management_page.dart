import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';
import '../data/services/contact_service.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/contact_channel_repository.dart';
import '../data/services/sharing_service.dart';
import '../widgets/app_bottom_nav.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  State<ProfileManagementPage> createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  late Future<_ProfileData> _future;
  final Set<String> _selectedChannelIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _loadProfileData();
  }

  void _refresh() {
    setState(() {
      _future = _loadProfileData();
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
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, size: 22, color: colorText),
                        const SizedBox(width: 8),
                        Text(
                          'Omada',
                          style: TextStyle(
                            color: colorText,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Data-driven content
              Expanded(
                child: FutureBuilder<_ProfileData>(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                width: MediaQuery.of(context).size.width * 0.32,
                                height:
                                    MediaQuery.of(context).size.width * 0.32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          center: Alignment(0.3, -0.3),
                                          radius: 0.8,
                                          colors: [
                                            Color(0xFF93c5fd), // Blue-300
                                            Color(0xFF4f46e5), // Indigo-600
                                            Color(0xFF1e40af), // Blue-800
                                          ],
                                          stops: [0.0, 0.6, 1.0],
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                          MediaQuery.of(context).size.width *
                                              0.12,
                                          MediaQuery.of(context).size.width *
                                              0.18,
                                          MediaQuery.of(context).size.width *
                                              0.18,
                                        ),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              center: Alignment(0.2, -0.1),
                                              colors: [
                                                Color(0xFF7dd3fc), // Sky-300
                                                Color(0xFF60a5fa), // Blue-400
                                                Colors.transparent,
                                              ],
                                              stops: [0.0, 0.5, 0.85],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                displayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (notes?.isNotEmpty == true)
                                Text(
                                  notes!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorText.withOpacity(0.85),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Text(
                                  about,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorText.withOpacity(0.8),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Channel chips grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ChannelGrid(
                            colorPill: colorPill,
                            colorPillActive: colorPillActive,
                            colorText: colorText,
                            channels: data.channels,
                            selectedIds: _selectedChannelIds,
                            onToggle: (id) {
                              setState(() {
                                if (_selectedChannelIds.contains(id)) {
                                  _selectedChannelIds.remove(id);
                                } else {
                                  _selectedChannelIds.add(id);
                                }
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // CTA / actions panel
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1e40af).withOpacity(0.28),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _CtaItem(
                                  icon: Icons.add,
                                  title: 'Add',
                                  value: 'Channel',
                                  onTap: () => _openAddChannel(context, data),
                                ),
                                _CallButton(),
                                _CtaItem(
                                  icon: Icons.share,
                                  title: 'Share',
                                  value: _selectedChannelIds.isEmpty
                                      ? 'Request'
                                      : '${_selectedChannelIds.length} selected',
                                  onTap: () => _openShare(context, data),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.profile),
    );
  }

  Future<void> _openAddChannel(BuildContext context, _ProfileData data) async {
    final kindCtrl = TextEditingController(text: 'mobile');
    final labelCtrl = TextEditingController(text: 'Mobile');
    final valueCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    final result = await showModalBottomSheet<bool>(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Channel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Kind (e.g., mobile, email)',
                ),
                controller: kindCtrl,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Label'),
                controller: labelCtrl,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Value'),
                controller: valueCtrl,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'URL'),
                controller: urlCtrl,
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
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      final repo = ContactChannelRepository(Supabase.instance.client);
      await repo.createChannel(
        contactId: data.contact.id,
        kind: kindCtrl.text.trim(),
        label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
        value: valueCtrl.text.trim().isEmpty ? null : valueCtrl.text.trim(),
        url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
      );
      _refresh();
    }
  }

  Future<void> _openShare(BuildContext context, _ProfileData data) async {
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

class _ChannelGrid extends StatelessWidget {
  final Color colorPill;
  final Color colorPillActive;
  final Color colorText;
  final List<ContactChannelModel> channels;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;
  const _ChannelGrid({
    required this.colorPill,
    required this.colorPillActive,
    required this.colorText,
    required this.channels,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final chipData = channels
        .map(
          (c) => _ChannelChipData(
            id: c.id,
            label: _labelForChannel(c),
            icon: _iconForKind(c.kind),
            primary: c.isPrimary,
          ),
        )
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: chipData.length,
      itemBuilder: (context, index) {
        final ch = chipData[index];
        final isPrimary = ch.primary;
        final isSelected = selectedIds.contains(ch.id);
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onToggle(ch.id),
          child: Container(
            decoration: BoxDecoration(
              color: isPrimary ? null : colorPill,
              gradient: isPrimary
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colorPillActive, Color(0xFF3b82f6)], // Blue-500
                    )
                  : null,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.06),
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ],
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ch.icon,
                  color: isPrimary ? const Color(0xFF0b1729) : colorText,
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  ch.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: isPrimary
                        ? const Color(0xFF0b1729)
                        : colorText.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChannelChipData {
  final String id;
  final String label;
  final IconData icon;
  final bool primary;
  const _ChannelChipData({
    required this.id,
    required this.label,
    required this.icon,
    this.primary = false,
  });
}

class _CtaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  const _CtaItem({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(0, -0.4),
          radius: 0.8,
          colors: [
            Color(0xFF93c5fd), // Blue-300
            Color(0xFF60a5fa), // Blue-400
            Color(0xFF3b82f6), // Blue-500
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 6),
      ),
      child: const Icon(Icons.bolt, size: 34, color: Colors.black87),
    );
  }
}

// Old local nav item removed; using shared AppBottomNav

// Data aggregation
class _ProfileData {
  final ProfileModel? profile;
  final ContactModel contact;
  final List<ContactChannelModel> channels;
  const _ProfileData({
    this.profile,
    required this.contact,
    required this.channels,
  });
}

Future<_ProfileData> _loadProfileData() async {
  final client = Supabase.instance.client;
  final profiles = ProfileRepository(client);
  final contacts = ContactService(client);
  final channelsRepo = ContactChannelRepository(client);

  final profile = await profiles.getCurrentProfile();
  final existing = await contacts.getContacts(limit: 1);
  final contact = existing.isEmpty
      ? await contacts.createContact(fullName: profile?.username)
      : existing.first;
  final channels = await channelsRepo.getChannelsForContact(contact.id);
  return _ProfileData(profile: profile, contact: contact, channels: channels);
}

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

IconData _iconForKind(String kind) {
  switch (kind.toLowerCase()) {
    case 'mobile':
    case 'phone':
      return Icons.phone;
    case 'email':
      return Icons.email;
    case 'instagram':
      return Icons.camera_alt_outlined;
    case 'linkedin':
      return Icons.business_center;
    case 'whatsapp':
      return Icons.message;
    case 'website':
      return Icons.language;
    case 'telegram':
      return Icons.send;
    case 'address':
      return Icons.place;
    default:
      return Icons.link;
  }
}

String _aboutText(_ProfileData data) {
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
