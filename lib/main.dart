import 'package:flutter/material.dart';
// import 'screens/contacts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return const MaterialApp(title: 'Instruments', home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _future = Supabase.instance.client.from('instruments').select();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final instruments = snapshot.data!;
          return ListView.builder(
            itemCount: instruments.length,
            itemBuilder: ((context, index) {
              final instrument = instruments[index];
              return ListTile(title: Text(instrument['name']));
            }),
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
