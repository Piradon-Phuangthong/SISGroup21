import 'package:flutter/material.dart';
import 'package:omada/core/theme/color_palette.dart';
import 'package:omada/ui/widgets/custom_app_bar.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
// import 'package:omada/ui/widgets/theme_selector.dart';
import 'package:omada/ui/widgets/contact_tile.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'contact_form_page.dart';
import 'package:omada/ui/widgets/filter_row.dart';
import 'manage_tags_page.dart';
import 'contacts/user_discovery_sheet.dart';
import 'contacts/incoming_requests_sheet.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/controllers/contacts_controller.dart';
import 'package:omada/ui/widgets/social_media_section.dart';
import 'package:omada/core/controllers/favourites_controller.dart';
import 'package:omada/ui/pages/deleted_contacts_page.dart';

// Removed unused imports

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late final ContactsController _controller;
  late final FavouritesController _favouritesController;
  final ColorPalette selectedTheme = appPalette;
  List<ContactModel> _contacts = [];
  List<ContactModel> _visibleContacts = [];
  List<TagModel> _tags = [];
  final Set<String> _selectedTagIds = <String>{};
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastSearchChangeAt;

  // Single palette; no runtime theme switching needed

  @override
  void initState() {
    super.initState();
    _controller = ContactsController(supabase);
    _favouritesController = FavouritesController();
    _favouritesController.addListener(_onFavouritesChanged);
    _searchController.addListener(_onSearchChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    // Clean up any existing contacts with empty string emails
    try {
      await _controller.cleanupEmptyEmails();
    } catch (e) {
      // Ignore cleanup errors, continue with normal initialization
    }
    await Future.wait([_refreshContacts(), _refreshTags()]);
  }

  @override
  void dispose() {
    _favouritesController.removeListener(_onFavouritesChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFavouritesChanged() {
    // Rebuild when favourites change to update star icons
    setState(() {});
  }

  Future<void> _refreshContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetched = await _controller.getContacts(
        includeDeleted: false,
        searchTerm: _serverSearchQuery,
        tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds.toList(),
      );
      fetched.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      setState(() {
        _contacts = fetched;
        _applyClientFilters();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshTags() async {
    try {
      final fetched = await _controller.getTags();
      setState(() => _tags = fetched);
    } catch (_) {
      // ignore for MVP
    }
  }

  String? get _serverSearchQuery {
    final q = _searchController.text.trim();
    if (q.isEmpty) return null;
    return q;
  }

  void _onSearchChanged() {
    _lastSearchChangeAt = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      final last = _lastSearchChangeAt;
      if (last == null) return;
      // debounce window
      if (DateTime.now().difference(last) >=
          const Duration(milliseconds: 290)) {
        _refreshContacts();
      }
    });
    _applyClientFilters();
  }

  void _applyClientFilters() {
    final localQuery = _searchController.text.trim().toLowerCase();
    List<ContactModel> filtered = List.of(_contacts);
    if (localQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        final fields = [
          c.displayName,
          c.givenName ?? '',
          c.familyName ?? '',
          c.primaryEmail ?? '',
          c.primaryMobile ?? '',
        ].join(' ').toLowerCase();
        return fields.contains(localQuery);
      }).toList();
    }
    setState(() => _visibleContacts = filtered);
  }

  Future<Map<String, List<TagModel>>> _getTagsForVisibleContacts() async {
    return _controller.getTagsForContacts(_visibleContacts);
  }

  Future<Map<String, List<ContactChannelModel>>>
  _getChannelsForVisibleContacts() async {
    return _controller.getChannelsForContacts(_visibleContacts);
  }

  Future<void> _onAddContact() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ContactFormPage()));
    // Always refresh tags so newly created tags appear in filters,
    // and refresh contacts when something was created.
    await _refreshTags();
    if (created == true) await _refreshContacts();
  }

  Future<void> _onEditContact(ContactModel contact) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ContactFormPage(contact: contact)),
    );
    await _refreshTags();
    if (updated == true) await _refreshContacts();
  }

  Future<void> _onDeleteContact(ContactModel contact) async {
    final removedContact = contact;
    setState(() {
      _contacts = _contacts.where((c) => c.id != removedContact.id).toList();
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
      setState(() => _contacts = [..._contacts, removedContact]);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  void _toggleFavourite(String contactId) {
    _favouritesController.toggleFavourite(contactId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            tooltip: 'Deleted contacts',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeletedContactsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Color theme selector removed in favor of a single app palette
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OmadaTokens.space16,
              vertical: OmadaTokens.space8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _refreshContacts();
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OmadaTokens.space16,
            ),
            child: Wrap(
              spacing: OmadaTokens.space8,
              runSpacing: OmadaTokens.space8,
              children: [
                TextButton.icon(
                  onPressed: _openUserDiscoverySheet,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Discover users'),
                ),
                TextButton.icon(
                  onPressed: _openIncomingRequestsSheet,
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('Requests'),
                ),
                TextButton.icon(
                  onPressed: _openManageTagsSheet,
                  icon: const Icon(Icons.label_outline),
                  label: const Text('Manage tags'),
                ),
              ],
            ),
          ),
          if (_tags.isNotEmpty)
            FilterRow(
              tags: _tags,
              selectedTagIds: _selectedTagIds,
              onTagToggle: (tag) async {
                setState(() {
                  if (_selectedTagIds.contains(tag.id)) {
                    _selectedTagIds.remove(tag.id);
                  } else {
                    _selectedTagIds.add(tag.id);
                  }
                });
                await _refreshContacts();
              },
            ),
          Padding(
            padding: const EdgeInsets.only(top: OmadaTokens.space8),
            child: _buildBody(),
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
    if (_isLoading && _visibleContacts.isEmpty) {
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
    if (_visibleContacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: const [
            Icon(Icons.contact_page_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text('No contacts yet'),
            SizedBox(height: 4),
            Text('Tap + to add your first contact'),
          ],
        ),
      );
    }
    return FutureBuilder<Map<String, List<TagModel>>>(
      future: _getTagsForVisibleContacts(),
      builder: (context, snapshot) {
        final tagsByContact = snapshot.data ?? const {};
        return Column(
          children: _visibleContacts.map((contact) {
            return ContactTile(
              contact: contact,
              tags: tagsByContact[contact.id] ?? const [],
              isFavourite: _favouritesController.isFavourite(contact.id),
              onFavouriteToggle: () => _toggleFavourite(contact.id),
              onTagTap: (tag) async {
                setState(() {
                  if (_selectedTagIds.contains(tag.id)) {
                    _selectedTagIds.remove(tag.id);
                  } else {
                    _selectedTagIds.add(tag.id);
                  }
                });
                await _refreshContacts();
              },
              onTap: () => _onEditContact(contact),
              onEdit: () => _onEditContact(contact),
              onDelete: () => _onDeleteContact(contact),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _openManageTagsSheet() async {
    await _refreshTags();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManageTagsPage(
          initialTags: _tags,
          selectedTagIds: _selectedTagIds,
          tagService: _controller.tagService,
          onTagsUpdated: (t) => setState(() => _tags = t),
          onSelectedIdsChanged: (ids) async {
            setState(
              () => _selectedTagIds
                ..clear()
                ..addAll(ids),
            );
            await _refreshContacts();
          },
        ),
      ),
    );

    // Refresh tags when returning from manage tags page
    if (result == true) {
      await _refreshTags();
    }
  }

  Future<void> _openUserDiscoverySheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          UserDiscoverySheet(sharingService: _controller.sharingService),
    );
  }

  Future<void> _openIncomingRequestsSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IncomingRequestsSheet(
        sharingService: _controller.sharingService,
        contactRepository: _controller.contactRepository,
        contactChannelRepository: _controller.contactChannelRepository,
      ),
    );
  }
}
