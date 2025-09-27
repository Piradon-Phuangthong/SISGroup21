import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';

class ChannelGrid extends StatelessWidget {
  final Color colorPill;
  final Color colorPillActive;
  final Color colorText;
  final List<ContactChannelModel> channels;
  final Set<String> selectedIds;
  final void Function(String id) onOpen;
  final void Function(String id)? onLongPress;
  const ChannelGrid({
    super.key,
    required this.colorPill,
    required this.colorPillActive,
    required this.colorText,
    required this.channels,
    required this.selectedIds,
    required this.onOpen,
    this.onLongPress,
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
          onTap: () => onOpen(ch.id),
          onLongPress: onLongPress == null ? null : () => onLongPress!(ch.id),
          child: Container(
            decoration: BoxDecoration(
              color: isPrimary ? null : colorPill,
              gradient: isPrimary
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colorPillActive, const Color(0xFF3b82f6)],
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
