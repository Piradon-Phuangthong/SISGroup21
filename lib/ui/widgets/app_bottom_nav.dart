import 'package:flutter/material.dart';

enum AppNav { omadas, contacts, profile, account }

class AppBottomNav extends StatelessWidget {
  final AppNav active;
  const AppBottomNav({super.key, required this.active});

  int get _index {
    switch (active) {
      case AppNav.omadas:
        return 0;
      case AppNav.contacts:
        return 1;
      case AppNav.profile:
        return 2;
      case AppNav.account:
        return 3;
    }
  }

  void _onTap(BuildContext context, int index) {
    if (index == _index) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/omadas');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/app');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) => _onTap(context, i),
      type: BottomNavigationBarType.fixed, // Needed for 4+ tabs
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Omadas'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Contacts'),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_membership),
          label: 'My Card',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Account',
        ),
      ],
    );
  }
}
