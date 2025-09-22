import 'package:flutter/material.dart';
import 'supabase/supabase_instance.dart';
import 'test_db/epics/epic_home_entry.dart';
import 'screens/contacts_screen.dart';
import 'pages/profile_management_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const OmadaRootApp());
}

class OmadaRootApp extends StatelessWidget {
  const OmadaRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omada',
      routes: {
        '/': (_) => const _RouteSelectorPage(),
        '/debug': (_) => const EpicHomeEntry(),
        '/app': (_) => const ContactsScreen(),
        '/profile': (_) => const ProfileManagementPage(),
      },
      initialRoute: '/',
    );
  }
}

class _RouteSelectorPage extends StatelessWidget {
  const _RouteSelectorPage({super.key});

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
