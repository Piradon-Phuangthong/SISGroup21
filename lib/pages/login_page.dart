import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omada/supabase/supabase_instance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null) {
        Navigator.of(context).pushReplacementNamed('/account');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(label: Text('Email')),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              try {
                final email = _emailController.text.trim();
                await supabase.auth.signInWithOtp(
                  email: email,
                  emailRedirectTo:
                      'io.supabase.flutterquickstart://login-callback/',
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Check your email for a login link'),
                    ),
                  );
                }
              } on AuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.message}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
