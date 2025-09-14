import 'package:flutter/material.dart';
import 'package:omada/supabase/supabase_instance.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);

    try {
      // Validate session with backend; clears any stale local session
      final userResponse = await supabase.auth.getUser();

      if (!mounted) return;

      if (userResponse.user != null) {
        Navigator.of(context).pushReplacementNamed('/account');
      } else {
        await supabase.auth.signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (_) {
      if (!mounted) return;
      await supabase.auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
