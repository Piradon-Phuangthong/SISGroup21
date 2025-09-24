import 'package:flutter/material.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:flutter/foundation.dart';
import 'package:omada/core/controllers/auth_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final AuthController _auth;
  @override
  void initState() {
    super.initState();
    _auth = AuthController(supabase);
    _redirect();
  }

  Future<void> _redirect() async {
    // Small delay to show splash screen briefly
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // Check current session and validate with backend
      final session = _auth.currentSession;

      if (session != null) {
        // Additional validation: try to get user to ensure session is still valid
        final userResponse = await _auth.getUser();

        if (!mounted) return;

        if (userResponse.user != null) {
          // Valid session - route to dev selector in debug mode, app in release
          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacementNamed(kDebugMode ? '/dev-selector' : '/app');
          }
        } else {
          // Invalid session - clear and go to login
          await _auth.signOut();
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        // No session - go to login
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Any error - clear session and go to login
      if (!mounted) return;
      await _auth.signOut();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or name
            Text(
              'Omada',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
