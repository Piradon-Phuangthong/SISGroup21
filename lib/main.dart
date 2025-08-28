import 'package:flutter/material.dart';
import 'screens/contacts_screen.dart';

void main() {
  runApp(const ContactsApp());
}

class ContactsApp extends StatelessWidget {
  const ContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Contacts App', home: const ContactsScreen());
  }
}
