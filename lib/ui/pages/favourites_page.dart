import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/widgets/custom_app_bar.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/ui/widgets/contact_tile.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/controllers/contacts_controller.dart';
import 'package:omada/ui/pages/contact_form_page.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late final ContactsController _controller;
  final Set<String> _favouriteContactIds = <String>{}; // Placeholder state
  List<ContactModel> _allContacts = [];
  List<ContactModel> _visibleFavourites = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ContactsController(supabase);
    _searchController.addListener(_onSearchChanged);
    _refreshContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetched = await _controller.getContacts(includeDeleted: false);
      fetched.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      setState(() {
        _allContacts = fetched;
        _applyFilters();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    
    // Filter to only favourite contacts
    List<ContactModel> filtered = _allContacts
        .where((c) => _favouriteContactIds.contains(c.id))
        .toList();
    
    // Apply search filter
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        final fields = [
          c.displayName,
          c.givenName ?? '',
          c.familyName ?? '',
          c.primaryEmail ?? '',
          c.primaryMobile ?? '',
        ].join(' ').toLowerCase();
        return fields.contains(query);
      }).toList();
    }
    
    setState(() => _visibleFavourites = filtered);
  }

  void _toggleFavourite(String contactId) {
    setState(() {
      if (_favouriteContactIds.contains(contactId)) {
        _favouriteContactIds.remove(contactId);
      } else {
        _favouriteContactIds.add(contactId);
      }
      _applyFilters();
    });
  }

  Future<void> _onEditContact(ContactModel contact) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ContactFormPage(contact: contact)),
    );
    if (updated == true) await _refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(OmadaTokens.space16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search favourites',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshContacts,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.favourites),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _visibleFavourites.isEmpty) {
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
    
    if (_visibleFavourites.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.star_border, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'No favourites yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(height: 4),
          Center(
            child: Text(
              'Tap the star icon on contacts to add them here',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    
    return ListView.builder(
      itemCount: _visibleFavourites.length,
      itemBuilder: (context, index) {
        final contact = _visibleFavourites[index];
        return ContactTile(
          contact: contact,
          isFavourite: _favouriteContactIds.contains(contact.id),
          onFavouriteToggle: () => _toggleFavourite(contact.id),
          onTap: () => _onEditContact(contact),
          onEdit: () => _onEditContact(contact),
        );
      },
    );
  }
}

