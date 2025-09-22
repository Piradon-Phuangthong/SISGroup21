import 'package:flutter/material.dart';

enum AppNav { contacts, profile }

class AppBottomNav extends StatelessWidget {
  final AppNav active;
  const AppBottomNav({super.key, required this.active});

  int get _index => active == AppNav.contacts ? 0 : 1;

  void _onTap(BuildContext context, int index) {
    if (index == _index) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/app');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) => _onTap(context, i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Contacts'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
