import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_channel_model.dart';

class ChannelLauncher {
  const ChannelLauncher();

  Future<void> openChannel(BuildContext context, ContactChannelModel ch) async {
    final kind = ch.kind.toLowerCase();
    try {
      switch (kind) {
        case 'instagram':
          await _openInstagram(context, ch.value);
          break;
        case 'whatsapp':
          await _openWhatsApp(context, ch.value);
          break;
        case 'messenger':
          await _openMessenger(context, ch.value);
          break;
        case 'linkedin':
          await _openLinkedIn(context, ch.value);
          break;
        case 'phone':
        case 'mobile':
          await _openTel(context, ch.value);
          break;
        case 'sms':
          await _openSms(context, ch.value);
          break;
        case 'email':
          await _openMailto(context, ch.value);
          break;
        default:
          if (ch.url != null && ch.url!.isNotEmpty) {
            await _openUrl(context, ch.url!);
          } else {
            _showError(context, 'No URL/value to open');
          }
      }
    } catch (e) {
      _showError(context, 'Could not open: $e');
    }
  }

  Future<void> _openInstagram(BuildContext context, String? username) async {
    if (username == null || username.isEmpty) {
      _showError(context, 'Missing Instagram username');
      return;
    }
    final appUri = Uri.parse('instagram://user?username=$username');
    final webUri = Uri.parse('https://instagram.com/$username');
    await _tryAppThenWeb(context, appUri, webUri);
  }

  Future<void> _openWhatsApp(BuildContext context, String? e164) async {
    if (e164 == null || e164.isEmpty) {
      _showError(context, 'Missing WhatsApp number');
      return;
    }
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    final appUri = Uri.parse('whatsapp://send?phone=$digits');
    final webUri = Uri.parse('https://wa.me/$digits');
    await _tryAppThenWeb(context, appUri, webUri);
  }

  Future<void> _openMessenger(BuildContext context, String? idOrUser) async {
    if (idOrUser == null || idOrUser.isEmpty) {
      _showError(context, 'Missing Messenger id/username');
      return;
    }
    final appUri = Uri.parse('fb-messenger://user-thread/$idOrUser');
    final webUri = Uri.parse('https://m.me/$idOrUser');
    await _tryAppThenWeb(context, appUri, webUri);
  }

  Future<void> _openLinkedIn(BuildContext context, String? handle) async {
    if (handle == null || handle.isEmpty) {
      _showError(context, 'Missing LinkedIn handle');
      return;
    }
    final appUri = Uri.parse('linkedin://in/$handle');
    final webUri = Uri.parse('https://www.linkedin.com/in/$handle');
    await _tryAppThenWeb(context, appUri, webUri);
  }

  Future<void> _openTel(BuildContext context, String? number) async {
    if (number == null || number.isEmpty) {
      _showError(context, 'No phone number');
      return;
    }
    final telUri = Uri.parse('tel:$number');
    if (!await launchUrl(telUri)) {
      _showError(context, 'Dialer not available');
    }
  }

  Future<void> _openSms(BuildContext context, String? number) async {
    if (number == null || number.isEmpty) {
      _showError(context, 'No phone number');
      return;
    }
    final smsUri = Uri.parse('sms:$number');
    if (!await launchUrl(smsUri)) {
      _showError(context, 'Messaging app not available');
    }
  }

  Future<void> _openMailto(BuildContext context, String? email) async {
    if (email == null || email.isEmpty) {
      _showError(context, 'No email');
      return;
    }
    final mailUri = Uri.parse('mailto:$email');
    if (!await launchUrl(mailUri)) {
      _showError(context, 'Mail app not available');
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError(context, 'Cannot open link');
    }
  }

  Future<void> _tryAppThenWeb(
    BuildContext context,
    Uri appUri,
    Uri webUri,
  ) async {
    if (await canLaunchUrl(appUri)) {
      final ok = await launchUrl(appUri);
      if (ok) return;
    }
    if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      _showError(context, 'Cannot open link');
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
