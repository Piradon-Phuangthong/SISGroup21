import 'package:flutter/material.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/widgets/app_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaSection extends StatelessWidget {
  final List<ContactChannelModel> channels;
  final String contactName;

  const SocialMediaSection({
    super.key,
    required this.channels,
    required this.contactName,
  });

  @override
  Widget build(BuildContext context) {
    // Filter for social media channels only
    final socialChannels = channels.where((channel) {
      return [
        'instagram',
        'facebook',
        'linkedin',
        'twitter',
        'github',
        'whatsapp',
        'telegram',
        'website',
      ].contains(channel.kind.toLowerCase());
    }).toList();

    if (socialChannels.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(OmadaTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Social Media',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: OmadaTokens.space12),
          Wrap(
            spacing: OmadaTokens.space8,
            runSpacing: OmadaTokens.space8,
            children: socialChannels.map((channel) {
              return _SocialMediaChip(
                channel: channel,
                contactName: contactName,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SocialMediaChip extends StatelessWidget {
  final ContactChannelModel channel;
  final String contactName;

  const _SocialMediaChip({
    required this.channel,
    required this.contactName,
  });

  @override
  Widget build(BuildContext context) {
    final platformInfo = _getPlatformInfo(channel.kind);
    
    return InkWell(
      onTap: () => _launchUrl(channel.url ?? ''),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OmadaTokens.space12,
          vertical: OmadaTokens.space8,
        ),
        decoration: BoxDecoration(
          color: platformInfo.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: platformInfo.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              platformInfo.icon,
              size: 16,
              color: platformInfo.color,
            ),
            const SizedBox(width: OmadaTokens.space4),
            Text(
              platformInfo.name,
              style: TextStyle(
                color: platformInfo.color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  _PlatformInfo _getPlatformInfo(String kind) {
    switch (kind.toLowerCase()) {
      case 'instagram':
        return _PlatformInfo(
          name: 'Instagram',
          icon: Icons.camera_alt_outlined,
          color: const Color(0xFFE4405F),
        );
      case 'facebook':
        return _PlatformInfo(
          name: 'Facebook',
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
        );
      case 'linkedin':
        return _PlatformInfo(
          name: 'LinkedIn',
          icon: Icons.work_outline,
          color: const Color(0xFF0A66C2),
        );
      case 'twitter':
        return _PlatformInfo(
          name: 'Twitter',
          icon: Icons.alternate_email,
          color: const Color(0xFF1DA1F2),
        );
      case 'github':
        return _PlatformInfo(
          name: 'GitHub',
          icon: Icons.code,
          color: const Color(0xFF333333),
        );
      case 'whatsapp':
        return _PlatformInfo(
          name: 'WhatsApp',
          icon: Icons.chat,
          color: const Color(0xFF25D366),
        );
      case 'telegram':
        return _PlatformInfo(
          name: 'Telegram',
          icon: Icons.send,
          color: const Color(0xFF0088CC),
        );
      case 'website':
        return _PlatformInfo(
          name: 'Website',
          icon: Icons.language,
          color: const Color(0xFF6B7280),
        );
      default:
        return _PlatformInfo(
          name: kind,
          icon: Icons.link,
          color: const Color(0xFF6B7280),
        );
    }
  }
}

class _PlatformInfo {
  final String name;
  final IconData icon;
  final Color color;

  const _PlatformInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}

