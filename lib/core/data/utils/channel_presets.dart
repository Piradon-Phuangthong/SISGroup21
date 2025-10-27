class ChannelPresets {
  static const Map<String, Map<String, String>> presets = {
    'mobile': {'label': 'Mobile', 'valueHint': '+15551234567'},
    'email': {'label': 'Email', 'valueHint': 'name@example.com'},
    'instagram': {'label': 'Instagram', 'valueHint': 'username'},
    'linkedin': {'label': 'LinkedIn', 'valueHint': 'handle'},
    'whatsapp': {'label': 'WhatsApp', 'valueHint': '+15551234567'},
    'messenger': {'label': 'Messenger', 'valueHint': 'username'},
    'telegram': {'label': 'Telegram', 'valueHint': 'username'},
  };

  static String computeUrl(String kindRaw, String valueRaw) {
    final kind = kindRaw.trim().toLowerCase();
    final value = valueRaw.trim();
    switch (kind) {
      case 'mobile':
        final digits = value.replaceAll(RegExp(r'[^\d+]'), '');
        return 'tel:$digits';
      case 'email':
        return 'mailto:$value';
      case 'instagram':
        final username = value.replaceAll('@', '');
        return 'https://instagram.com/$username';
      case 'linkedin':
        return 'https://www.linkedin.com/in/$value';
      case 'whatsapp':
        final digits = value.replaceAll(RegExp(r'\D'), '');
        return 'https://wa.me/$digits';
      case 'messenger':
        return 'https://m.me/$value';
      case 'telegram':
        final username = value.replaceAll('@', '');
        return 'https://t.me/$username';
      default:
        return '';
    }
  }
}
