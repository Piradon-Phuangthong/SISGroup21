import 'package:flutter/material.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'test_db/epics/epic_home_entry.dart';
import 'package:omada/core/theme/app_theme.dart';
import 'package:omada/core/theme/app_theme_controller.dart';
import 'package:omada/ui/pages/contacts_screen.dart';
import 'package:omada/ui/pages/profile_management_page.dart';
import 'package:omada/ui/pages/splash_page.dart';
import 'package:omada/ui/pages/login_page.dart';
import 'package:omada/ui/pages/account_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  final themeController = AppThemeController();
  await themeController.load();
  runApp(OmadaRootApp(themeController: themeController));
}

class OmadaRootApp extends StatelessWidget {
  final AppThemeController themeController;
  const OmadaRootApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Omada',
          theme: OmadaTheme.light(),
          darkTheme: OmadaTheme.dark(),
          themeMode: mode,
          routes: {
            '/': (_) => const SplashPage(),
            '/login': (_) => const LoginPage(),
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
