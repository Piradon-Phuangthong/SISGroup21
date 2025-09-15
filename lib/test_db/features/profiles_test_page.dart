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
  ProfileModel? _me;
  List<ProfileModel> _profiles = [];
  final _searchCtrl = TextEditingController();
  final _newUsernameCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _repo = ProfileRepository(Supabase.instance.client);
    _loadMe();
    _refresh();
  }

  Future<void> _loadMe() async {
    try {
      _me = await _repo.getCurrentProfile();
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _refresh() async {
    try {
      // Search other profiles by term; leave empty to show none
      if (_searchCtrl.text.trim().isNotEmpty) {
        _profiles = await _repo.searchProfiles(_searchCtrl.text.trim());
      } else {
        _profiles = [];
      }
      setState(() {});
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _updateUsername() async {
    try {
      final name = _newUsernameCtrl.text.trim();
      if (name.isEmpty) return;
      final updated = await _repo.updateCurrentProfile(username: name);
      setState(() {
        _status = 'Updated to ${updated.username}';
        _me = updated;
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update My Username',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _me?.username.isNotEmpty == true ? _me!.username : '—',
                      ),
                      subtitle: Text(_me?.id ?? ''),
                      leading: const Icon(Icons.person_outline),
                    ),
                    TextField(
                      controller: _newUsernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'New username',
                        hintText: 'Enter your new username',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _updateUsername,
                          child: const Text('Update'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _loadMe,
                          child: const Text('Refresh Me'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Profiles',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Search term',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
