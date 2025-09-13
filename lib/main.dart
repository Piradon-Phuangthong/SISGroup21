import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/contact_service.dart';
import 'services/models/contact_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kjkitypxpuqzoajautly.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtqa2l0eXB4cHVxem9hamF1dGx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzODYwNDksImV4cCI6MjA3MTk2MjA0OX0.ugh30Y2_o3Tf4wFoBMjRzRu585awYX1vJPLG1DEE9Xo',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Contacts', home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<ContactModel>> _future = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _future = ContactService.getContacts(ownerId: user.id);
      });
    } else {
      setState(() {
        _future = Future.error('User not authenticated');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }

          final contacts = snapshot.data!;
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: contact.avatarUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(contact.avatarUrl!),
                      )
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(contact.fullName ?? 'Unnamed Contact'),
                subtitle: Text(
                  contact.primaryEmail ?? contact.primaryMobile ?? '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
