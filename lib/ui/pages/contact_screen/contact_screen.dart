import 'package:flutter/material.dart';
import 'package:omada/core/controllers/contacts_controller.dart';
import 'package:omada/core/controllers/favourites_controller.dart';
import 'package:omada/core/data/models/contact_channel_model.dart';
import 'package:omada/core/data/models/contact_model.dart';
import 'package:omada/core/data/models/tag_model.dart';
import 'package:omada/core/domain/models/tag.dart';
import 'package:omada/core/supabase/supabase_instance.dart';
import 'package:omada/core/theme/color_palette.dart';
import 'package:omada/ui/pages/account_page.dart';
import 'package:omada/ui/pages/contact_form_page.dart';
import 'package:omada/ui/pages/contact_screen/contact_card.dart';
import 'package:omada/ui/pages/contact_screen/contact_header/collapsed_contact_header.dart';
import 'package:omada/ui/pages/contact_screen/contact_header/expanded_contact_header.dart';
import 'package:omada/ui/pages/contacts/incoming_requests_sheet.dart';
import 'package:omada/ui/pages/contacts/user_discovery_sheet.dart';
import 'package:omada/ui/pages/deleted_contacts_page.dart';
import 'package:omada/ui/pages/manage_tags_page.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/ui/widgets/contact_tile.dart';
import 'package:omada/ui/widgets/filter_row.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
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

  // Preloaded data
  Map<String, List<TagModel>> _tagsByContact = {};
  Map<String, List<ContactChannelModel>> _channelsByContact = {};

  // Refresh indicator key
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

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

      // Preload tags and channels for the fetched contacts
      await _preloadContactDetails(fetched);

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
      _visibleContacts = _visibleContacts
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
        _contacts = [..._contacts, removedContact];
        _applyClientFilters();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  void _toggleFavourite(String contactId) {
    _favouritesController.toggleFavourite(contactId);
  }

  // Method to trigger refresh programmatically if needed
  Future<void> _handleRefresh() async {
    await Future.wait([_refreshContacts(), _refreshTags()]);
  }

  @override
  Widget build(BuildContext context) {
    final double expandedHeight = 315;
    final double collapsedHeight = 120;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        displacement: 80.0, // How far down the indicator comes
        color: Colors.blue,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        strokeWidth: 2.0,
        child: CustomScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator to work
          slivers: [
            SliverAppBar(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              pinned: true,
              forceMaterialTransparency: true,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double currentHeight = constraints.biggest.height;

                  final double t =
                      ((currentHeight - collapsedHeight) /
                              (expandedHeight - collapsedHeight))
                          .clamp(0.0, 1.0);

                  if (currentHeight > (expandedHeight + collapsedHeight) / 2) {
                    return ExpandedContactHeader(
                      onDiscoverUsers: _openUserDiscoverySheet,
                      onGetDeleted: _openDeletedContacts,
                      onGetRequests: _openIncomingRequestsSheet,
                      onManageTags: _openManageTagsSheet,
                      onAddContact: _onAddContact,
                      onGetAccountPage: _openAccountPage,
                      onSearchChanged: _onSearchChanged,
                      searchController: _searchController,
                    );
                  } else {
                    return CollapsedContactHeader(
                      onAddContact: _onAddContact,
                      onSearchChanged: _onSearchChanged,
                      searchController: _searchController,
                    );
                  }
                },
              ),
            ),
            if (_tags.isNotEmpty)
              SliverToBoxAdapter(
                child: FilterRow(
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
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                // Handle different states based on index
                if (_isLoading && _visibleContacts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null && _visibleContacts.isEmpty) {
                  return _buildErrorWidget();
                }
                if (_visibleContacts.isEmpty) {
                  return _buildEmptyState();
                }

                // Return contact tile for actual contacts
                final contact = _visibleContacts[index];
                return ContactCard(
                  contact: contact,
                  tags: _tagsByContact[contact.id] ?? const [],
                  channels: _channelsByContact[contact.id] ?? const [],
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
                  onLongPress: () => _onEditContact(contact),
                  onEdit: () => _onEditContact(contact),
                  onDelete: () => _onDeleteContact(contact),
                );
              }, childCount: _getChildCount()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.contacts),
    );
  }

  int _getChildCount() {
    if (_isLoading && _visibleContacts.isEmpty) return 1;
    if (_error != null && _visibleContacts.isEmpty) return 1;
    if (_visibleContacts.isEmpty) return 1;
    return _visibleContacts.length;
  }

  Widget _buildErrorWidget() {
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
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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

  // ... rest of your methods remain the same
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
      builder: (context) =>
          IncomingRequestsSheet(sharingService: _controller.sharingService),
    );
  }

  void _openDeletedContacts(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => DeletedContactsPage()));
  }

  void _openAccountPage(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AccountPage()));
  }
}
