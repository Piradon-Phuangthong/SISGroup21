import 'package:flutter/material.dart';
import '../themes/color_palette.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/theme_selector.dart';
import '../widgets/contact_tile.dart';
import '../supabase/supabase_instance.dart';
import '../data/services/contact_service.dart';
import '../data/models/contact_model.dart';
import '../pages/contact_form_page.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _contactService = ContactService(supabase);
  ColorPalette selectedTheme = oceanTheme;
  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  void _changeTheme(ColorPalette theme) =>
      setState(() => selectedTheme = theme);

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  Future<void> _refreshContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetched = await _contactService.getContacts(includeDeleted: false);
      fetched.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      setState(() => _contacts = fetched);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddContact() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ContactFormPage()));
    if (created == true) {
      await _refreshContacts();
    }
  }

  Future<void> _onEditContact(ContactModel contact) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ContactFormPage(contact: contact)),
    );
    if (updated == true) {
      await _refreshContacts();
    }
  }

  Future<void> _onDeleteContact(ContactModel contact) async {
    final removedContact = contact;
    setState(() {
      _contacts = _contacts.where((c) => c.id != removedContact.id).toList();
    });

    try {
      await _contactService.deleteContact(removedContact.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${removedContact.displayName}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _contactService.restoreContact(removedContact.id);
              await _refreshContacts();
            },
          ),
        ),
      );
    } catch (e) {
      // Revert UI on error
      setState(() => _contacts = [..._contacts, removedContact]);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          ThemeSelector(
            themes: allThemes,
            selectedTheme: selectedTheme,
            onThemeChanged: _changeTheme,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshContacts,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.contacts),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddContact,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshContacts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_contacts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.contact_page_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No contacts yet')),
          SizedBox(height: 4),
          Center(child: Text('Tap + to add your first contact')),
        ],
      );
    }
    return ListView.builder(
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return ContactTile(
          contact: contact,
          colorPalette: selectedTheme,
          onTap: () => _onEditContact(contact),
          onEdit: () => _onEditContact(contact),
          onDelete: () => _onDeleteContact(contact),
        );
      },
    );
  }
}
