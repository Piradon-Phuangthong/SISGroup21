import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/pages/contact_screen/contact_card.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/controllers/contacts_controller.dart';
import 'package:omada/core/controllers/favourites_controller.dart';
import 'package:omada/ui/pages/contact_form_page.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late final ContactsController _controller;
  late final FavouritesController _favouritesController;
  List<ContactModel> _allContacts = [];
  List<ContactModel> _visibleFavourites = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  // Preloaded data for ContactCard
  Map<String, List<TagModel>> _tagsByContact = {};
  Map<String, List<ContactChannelModel>> _channelsByContact = {};

  @override
  void initState() {
    super.initState();
    _controller = ContactsController(supabase);
    _favouritesController = FavouritesController();
    _favouritesController.addListener(_onFavouritesChanged);
    _searchController.addListener(_onSearchChanged);
    _refreshContacts();
  }

  @override
  void dispose() {
    _favouritesController.removeListener(_onFavouritesChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFavouritesChanged() {
    // Rebuild when favourites change
    _applyFilters();
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

      // Preload tags and channels for the fetched contacts
      await _preloadContactDetails(fetched);

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

  Future<void> _preloadContactDetails(List<ContactModel> contacts) async {
    if (contacts.isEmpty) {
      setState(() {
        _tagsByContact = {};
        _channelsByContact = {};
      });
      return;
    }

    try {
      final [channelsResult, tagsResult] = await Future.wait([
        _controller.getChannelsForContacts(contacts),
        _controller.getTagsForContacts(contacts),
      ]);

      setState(() {
        _channelsByContact =
            channelsResult as Map<String, List<ContactChannelModel>>;
        _tagsByContact = tagsResult as Map<String, List<TagModel>>;
      });
    } catch (e) {
      // If preloading fails, clear the data and continue
      setState(() {
        _tagsByContact = {};
        _channelsByContact = {};
      });
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    // Filter to only favourite contacts
    List<ContactModel> filtered = _allContacts
        .where((c) => _favouritesController.isFavourite(c.id))
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
    _favouritesController.toggleFavourite(contactId);
  }

  Future<void> _onEditContact(ContactModel contact) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ContactFormPage(contact: contact)),
    );
    if (updated == true) await _refreshContacts();
  }

  Future<void> _onDeleteContact(ContactModel contact) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete "${contact.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user cancelled, return early
    if (confirmed != true) return;

    final removedContact = contact;
    setState(() {
      _allContacts = _allContacts
          .where((c) => c.id != removedContact.id)
          .toList();
      _visibleFavourites = _visibleFavourites
          .where((c) => c.id != removedContact.id)
          .toList();
      _tagsByContact.remove(removedContact.id);
      _channelsByContact.remove(removedContact.id);
    });

    try {
      await _controller.deleteContact(removedContact.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${removedContact.displayName}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _controller.restoreContact(removedContact.id);
              await _refreshContacts();
            },
          ),
        ),
      );
    } catch (e) {
      // Revert UI on error
      setState(() {
        _allContacts = [..._allContacts, removedContact];
        _applyFilters();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF5733), // Red-orange
            Color(0xFF4A00B0), // Deep purple
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(OmadaTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: OmadaTokens.space8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(width: OmadaTokens.space8),
                  const Text(
                    'Favourites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OmadaTokens.space4),
              Text(
                '${_visibleFavourites.length} starred contacts',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(OmadaTokens.space16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search favourites...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: OmadaTokens.space16,
            vertical: OmadaTokens.space12,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

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
      return Container(
        padding: const EdgeInsets.all(OmadaTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange[300]!, Colors.pink[300]!],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.star_border,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: OmadaTokens.space24),
            Text(
              'No favourites yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: OmadaTokens.space8),
            Text(
              'Tap the star icon on contacts to add them here',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: OmadaTokens.space2),
      itemCount: _visibleFavourites.length,
      itemBuilder: (context, index) {
        final contact = _visibleFavourites[index];
        return ContactCard(
          contact: contact,
          tags: _tagsByContact[contact.id] ?? const [],
          channels: _channelsByContact[contact.id] ?? const [],
          isFavourite: _favouritesController.isFavourite(contact.id),
          onFavouriteToggle: () => _toggleFavourite(contact.id),
          onTagTap: (tag) {
            // Tag tap handler - could navigate to filtered view if needed
          },
          onLongPress: () => _onEditContact(contact),
          onEdit: () => _onEditContact(contact),
          onDelete: () => _onDeleteContact(contact),
        );
      },
    );
  }
}
