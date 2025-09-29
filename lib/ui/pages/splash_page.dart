import 'package:flutter/material.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:flutter/foundation.dart';
import 'package:omada/core/controllers/auth_controller.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:shimmer/shimmer.dart';

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
    await Future.delayed(const Duration(seconds: 3));

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
          if (mounted) Navigator.of(context).pushReplacementNamed('/login');
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
      body: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 5),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFFFF5F6D), const Color(0xFF42A5F5), value)!,
                  Color.lerp(const Color(0xFF0D47A1), const Color(0xFFE91E63), value)!,
                ],
              ),
            ),
            child: child,
          );
        },
        onEnd: () {
          setState(() {}); // Loop gradient animation
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.white,
                highlightColor: Colors.blueAccent,
                child: Text(
                  'Omada',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(height: OmadaTokens.space16),
              // Text(
                // 'Loading...',
               // style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  //    color: Colors.white70,
                 //   ),
            //  ),
            ],
          ),
        ),
      ),
    );
  }
}
