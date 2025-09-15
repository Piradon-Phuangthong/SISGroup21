import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/contact_service.dart';
import '../../data/repositories/contact_channel_repository.dart';

class DummyUserWizardPage extends StatefulWidget {
  const DummyUserWizardPage({super.key});

  @override
  State<DummyUserWizardPage> createState() => _DummyUserWizardPageState();
}

class _DummyUserWizardPageState extends State<DummyUserWizardPage> {
  late final AuthService _auth;
  late final ContactService _contacts;
  late final ContactChannelRepository _channelsRepo;

  // Profile
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'Password123!');
  final _usernameCtrl = TextEditingController();

  // Contact
  final _fullNameCtrl = TextEditingController();
  final _primaryEmailCtrl = TextEditingController();
  final _primaryPhoneCtrl = TextEditingController();

  // Channel
  final _chanKindCtrl = TextEditingController(text: 'email');
  final _chanLabelCtrl = TextEditingController(text: 'Work');
  final _chanValueCtrl = TextEditingController();

  String? _status;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _auth = AuthService(client);
    _contacts = ContactService(client);
    _channelsRepo = ContactChannelRepository(client);
  }

  Future<void> _runWizard() async {
    try {
      // Step 1: create user
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      final username = _usernameCtrl.text.trim().isEmpty
          ? null
          : _usernameCtrl.text.trim();
      await _auth.signUp(email: email, password: password, username: username);

      // Step 2: sign in as the user
      await _auth.signIn(email: email, password: password);

      // Step 3: create contact card
      final contact = await _contacts.createContact(
        fullName: _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
        primaryEmail: _primaryEmailCtrl.text.trim().isEmpty
            ? null
            : _primaryEmailCtrl.text.trim(),
        primaryMobile: _primaryPhoneCtrl.text.trim().isEmpty
            ? null
            : _primaryPhoneCtrl.text.trim(),
      );

      // Step 4: create one channel
      if (_chanValueCtrl.text.trim().isNotEmpty) {
        await _channelsRepo.createChannel(
          contactId: contact.id,
          kind: _chanKindCtrl.text.trim(),
          label: _chanLabelCtrl.text.trim(),
          value: _chanValueCtrl.text.trim(),
        );
      }

      setState(() => _status = 'Dummy user created and initialized');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dummy User Wizard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Profile'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
              ),
            ),
            const Divider(height: 24),
            const Text('Contact Card'),
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _primaryEmailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Primary email',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _primaryPhoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Primary phone',
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Initial Channel'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chanKindCtrl,
                    decoration: const InputDecoration(labelText: 'Kind'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chanLabelCtrl,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _chanValueCtrl,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runWizard,
              child: const Text('Create Dummy User'),
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}
