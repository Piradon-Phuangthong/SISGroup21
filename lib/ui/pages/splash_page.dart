import 'package:flutter/material.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:flutter/foundation.dart';
import 'package:omada/core/controllers/auth_controller.dart';
import 'package:omada/core/theme/design_tokens.dart';

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
      final session = _auth.currentSession;

      if (session != null) {
        final userResponse = await _auth.getUser();

        if (!mounted) return;

        if (userResponse.user != null) {
          Navigator.of(context).pushReplacementNamed(
            kDebugMode ? '/dev-selector' : '/app',
          );
        } else {
          await _auth.signOut();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      } else {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (!mounted) return;
      await _auth.signOut();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF5F6D), // reddish-pink
              Color(0xFF0D47A1), // deep blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App name/logo
              Text(
                'Omada',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // contrast on gradient
                    ),
              ),
              const SizedBox(height: OmadaTokens.space32),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: OmadaTokens.space16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
