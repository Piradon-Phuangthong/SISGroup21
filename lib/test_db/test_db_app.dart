import 'package:flutter/material.dart';
// Supabase is initialized by caller
// import 'test_db_home_page.dart';
import 'epics/epic_home_entry.dart';

Future<void> runTestDb() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase init handled by caller; ensure it's initialized before calling this.
  runApp(const TestDbApp());
}

class TestDbApp extends StatelessWidget {
  const TestDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      title: 'Test DB',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        listTileTheme: const ListTileThemeData(dense: false),
      ),
      home: const EpicHomeEntry(),
    );
  }
}
