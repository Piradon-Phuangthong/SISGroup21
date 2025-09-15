import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/models.dart';

class ProfilesTestPage extends StatefulWidget {
  const ProfilesTestPage({super.key});

  @override
  State<ProfilesTestPage> createState() => _ProfilesTestPageState();
}

class _ProfilesTestPageState extends State<ProfilesTestPage> {
  late final ProfileRepository _repo;
  List<ProfileModel> _profiles = [];
  final _usernameCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _repo = ProfileRepository(Supabase.instance.client);
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      // Quick list by search if provided, otherwise get current profile
      if (_usernameCtrl.text.trim().isNotEmpty) {
        _profiles = await _repo.searchProfiles(_usernameCtrl.text.trim());
      } else {
        final me = await _repo.getCurrentProfile();
        _profiles = me != null ? [me] : [];
      }
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _updateUsername() async {
    try {
      final name = _usernameCtrl.text.trim();
      if (name.isEmpty) return;
      final updated = await _repo.updateCurrentProfile(username: name);
      setState(() {
        _status = 'Updated to ${updated.username}';
      });
      await _refresh();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profiles Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username or search term',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Search/Load'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateUsername,
                  child: const Text('Update My Username'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_status != null)
              Align(alignment: Alignment.centerLeft, child: Text(_status!)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _profiles.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = _profiles[index];
                  return ListTile(
                    title: Text(p.username),
                    subtitle: Text(p.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
