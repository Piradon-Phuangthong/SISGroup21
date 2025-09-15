import 'package:flutter/material.dart';

// UNCOMMENT FOR NEW USER MANAGEMENT APP
// import 'user_management_test.dart';
import 'test_db/test_db_app.dart' as testdb; // ignore: unused_import
import 'supabase/supabase_instance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  // To run the Test DB app instead of the current app, uncomment the next line:
  await testdb.runTestDb();
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
