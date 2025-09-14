import 'package:flutter/material.dart';
import 'package:omada/supabase/supabase_instance.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(label: Text('Username')),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = _usernameController.text.trim();
              final userId = supabase.auth.currentUser!.id;
              await supabase
                  .from('profiles')
                  .update({'username': username})
                  .eq('id', userId);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
