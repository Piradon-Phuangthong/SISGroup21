import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/services/auth_service.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({super.key});

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  late final AuthService _auth;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String? _status;

  @override
  void initState() {
    super.initState();
    _auth = AuthService(Supabase.instance.client);
  }

  Future<void> _signup() async {
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passwordCtrl.text.trim();
      final username = _usernameCtrl.text.trim().isEmpty
          ? null
          : _usernameCtrl.text.trim();
      await _auth.signUp(email: email, password: pass, username: username);
      setState(() => _status = 'Signed up');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _signin() async {
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passwordCtrl.text.trim();
      await _auth.signIn(email: email, password: pass);
      setState(() => _status = 'Signed in');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _signout() async {
    try {
      await _auth.signOut();
      setState(() => _status = 'Signed out');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Current user: ${user?.email ?? 'none'}'),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _signup,
                  child: const Text('Sign Up'),
                ),
                ElevatedButton(
                  onPressed: _signin,
                  child: const Text('Sign In'),
                ),
                ElevatedButton(
                  onPressed: _signout,
                  child: const Text('Sign Out'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
          ],
        ),
      ),
    );
  }
}
