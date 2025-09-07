import 'package:flutter/material.dart';
import 'screens/contacts_screen.dart';
import 'services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientService.initialize();
  print("✅ Supabase initialized: ${SupabaseClientService.client}");
  runApp(const ContactsApp());
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Contacts App', home: const ContactsScreen());
  }
}
