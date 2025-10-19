import 'package:flutter/material.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/data/models/contact_model.dart';
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
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
                  colors: [
                    Colors.orange[300]!,
                    Colors.pink[300]!,
                  ],
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
            const Text(
              'No favourites yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: OmadaTokens.space8),
            Text(
              'Tap the star icon on contacts to add them here',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: OmadaTokens.space16),
      itemCount: _visibleFavourites.length,
      itemBuilder: (context, index) {
        final contact = _visibleFavourites[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(ContactModel contact) {
    return GestureDetector(
      onTap: () => _onEditContact(contact),
      child: Container(
        margin: const EdgeInsets.only(bottom: OmadaTokens.space12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(OmadaTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple[400]!,
                          Colors.blue[400]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        contact.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: OmadaTokens.space12),
                  // Contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                contact.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _toggleFavourite(contact.id),
                              icon: Icon(
                                Icons.star,
                                color: Colors.amber[600],
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        if (contact.primaryMobile != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                contact.primaryMobile!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (contact.primaryEmail != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                contact.primaryEmail!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OmadaTokens.space12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone,
                      label: 'Call',
                      onTap: () {
                        // TODO: Implement call functionality
                      },
                    ),
                  ),
                  const SizedBox(width: OmadaTokens.space8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.message,
                      label: 'Message',
                      onTap: () {
                        // TODO: Implement message functionality
                      },
                    ),
                  ),
                  const SizedBox(width: OmadaTokens.space8),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.email,
                      label: 'Email',
                      onTap: () {
                        // TODO: Implement email functionality
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: OmadaTokens.space8,
          horizontal: OmadaTokens.space12,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

