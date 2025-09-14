import 'package:flutter/material.dart';

// UNCOMMENT FOR NEW USER MANAGEMENT APP
import 'user_management_test.dart';
import 'supabase/supabase_instance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const UserManagementTest());
}

// // UNCOMMENT FOR OLD CONTACT APP POC
// import 'package:omada/screens/contacts_screen.dart';

// void main() {
//   runApp(const ContactsApp());
// }

// class ContactsApp extends StatelessWidget {
//   const ContactsApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(title: 'Contacts App', home: const ContactsScreen());
//   }
// }
