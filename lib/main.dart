import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'test_db/epics/epic_home_entry.dart';
import 'package:omada/core/theme/app_theme.dart';
import 'package:omada/core/theme/app_theme_controller.dart';
import 'package:omada/ui/pages/contacts_screen.dart';
import 'package:omada/ui/pages/profile_management_page.dart';
import 'package:omada/ui/pages/splash_page.dart';
import 'package:omada/ui/pages/login_page.dart';
import 'package:omada/ui/pages/account_page.dart';
import 'package:omada/ui/pages/reset_password_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  final themeController = AppThemeController();
  await themeController.load();
  runApp(OmadaRootApp(themeController: themeController));
}

class OmadaRootApp extends StatefulWidget {
  final AppThemeController themeController;
  const OmadaRootApp({super.key, required this.themeController});

  @override
  State<OmadaRootApp> createState() => _OmadaRootAppState();
}

class _OmadaRootAppState extends State<OmadaRootApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushNamed('/reset-password');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.themeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Omada',
          theme: OmadaTheme.light(),
          darkTheme: OmadaTheme.dark(),
          themeMode: mode,
          routes: {
            '/': (_) => const SplashPage(),
            '/login': (_) => const LoginPage(),
            '/reset-password': (_) => const ResetPasswordPage(),
            '/app': (_) => const ContactsScreen(),
            '/account': (_) => const AccountPage(),
            '/profile': (_) => const ProfileManagementPage(),
            '/debug': (_) => const EpicHomeEntry(),
            '/dev-selector': (_) => const _RouteSelectorPage(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}

class _RouteSelectorPage extends StatelessWidget {
  const _RouteSelectorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Omada Entry')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/debug'),
              child: const Text('Open DB Debug (Test Suite)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/app'),
              child: const Text('Open Main App'),
            ),
          ],
        ),
      ),
    );
  }
}
