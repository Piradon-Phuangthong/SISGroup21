import 'package:flutter/material.dart';
import 'package:omada/pages/account_page.dart';
import 'package:omada/pages/login_page.dart';
import 'package:omada/pages/splash_page.dart';

class UserManagementTest extends StatelessWidget {
  const UserManagementTest({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Flutter',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/account': (context) => const AccountPage(),
      },
    );
  }
}
