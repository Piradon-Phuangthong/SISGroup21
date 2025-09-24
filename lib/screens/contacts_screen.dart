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
import '../widgets/filter_row.dart';
import '../data/services/tag_service.dart';
import '../data/models/tag_model.dart';
import '../data/services/sharing_service.dart';
import '../data/models/profile_model.dart';
import '../data/models/share_request_model.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactService _contactService = ContactService(supabase);
  late final TagService _tagService;
  late final SharingService _sharingService;
  ColorPalette selectedTheme = oceanTheme;
  List<ContactModel> _contacts = [];
  List<ContactModel> _visibleContacts = [];
  List<TagModel> _tags = [];
  final Set<String> _selectedTagIds = <String>{};
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastSearchChangeAt;

  void _changeTheme(ColorPalette theme) =>
      setState(() => selectedTheme = theme);

  @override
  void initState() {
    super.initState();
    _tagService = TagService(supabase);
    _sharingService = SharingService(supabase);
    _searchController.addListener(_onSearchChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([_refreshContacts(), _refreshTags()]);
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
      final fetched = await _contactService.getContacts(
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
      final fetched = await _tagService.getTags();
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
    // Fetch tags for visible contacts in parallel
    final entries = await Future.wait(
      _visibleContacts.map((c) async {
        try {
          final tags = await _tagService.getTagsForContact(c.id);
          return MapEntry(c.id, tags);
        } catch (_) {
          return MapEntry(c.id, <TagModel>[]);
        }
      }),
    );
    return Map.fromEntries(entries);
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
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
              colorPalette: selectedTheme,
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
    return FutureBuilder<Map<String, List<TagModel>>>(
      future: _getTagsForVisibleContacts(),
      builder: (context, snapshot) {
        final tagsByContact = snapshot.data ?? const {};
        return ListView.builder(
          itemCount: _visibleContacts.length,
          itemBuilder: (context, index) {
            final contact = _visibleContacts[index];
            return ContactTile(
              contact: contact,
              colorPalette: selectedTheme,
              tags: tagsByContact[contact.id] ?? const [],
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
          },
        );
      },
    );
  }

  Future<void> _openManageTagsSheet() async {
    await _refreshTags();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, controller) {
            final TextEditingController nameController =
                TextEditingController();
            return StatefulBuilder(
              builder: (context, setSheetState) {
                Future<void> addTag() async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  try {
                    await _tagService.createTag(name);
                    nameController.clear();
                    final fetched = await _tagService.getTags();
                    setSheetState(() => _tags = fetched);
                    setState(() => _tags = fetched);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create tag: $e')),
                    );
                  }
                }

                Future<void> deleteTag(TagModel tag) async {
                  try {
                    await _tagService.deleteTag(tag.id);
                    final fetched = await _tagService.getTags();
                    setSheetState(() => _tags = fetched);
                    setState(() => _tags = fetched);
                    if (_selectedTagIds.contains(tag.id)) {
                      setState(() => _selectedTagIds.remove(tag.id));
                      await _refreshContacts();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete tag: $e')),
                    );
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Manage tags',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'New tag name',
                              ),
                              onSubmitted: (_) => addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: addTag,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: _tags.length,
                          itemBuilder: (context, index) {
                            final tag = _tags[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: selectedTheme.getColorForItem(
                                  tag.id,
                                ),
                                child: const Icon(
                                  Icons.label,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(tag.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete tag?'),
                                      content: Text(
                                        'Delete "${tag.name}"? This will remove it from any contacts.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await deleteTag(tag);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openUserDiscoverySheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            final TextEditingController usernameController =
                TextEditingController();
            final TextEditingController messageController =
                TextEditingController();
            List<ProfileModel> results = [];
            bool isSearching = false;
            final Set<String> requestedUsernames = <String>{};
            DateTime? lastChangeAt;

            Future<void> runSearch(
              String term,
              void Function(void Function()) setSheetState,
            ) async {
              final q = term.trim();
              if (q.isEmpty) {
                setSheetState(() => results = []);
                return;
              }
              setSheetState(() => isSearching = true);
              try {
                final fetched = await _sharingService.searchUsersForSharing(q);
                setSheetState(() => results = fetched);
              } catch (e) {
                // Show one-time error; keep UI responsive
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
                }
              } finally {
                setSheetState(() => isSearching = false);
              }
            }

            return StatefulBuilder(
              builder: (context, setSheetState) {
                void onUsernameChanged() {
                  lastChangeAt = DateTime.now();
                  Future.delayed(const Duration(milliseconds: 300)).then((_) {
                    final ts = lastChangeAt;
                    if (ts == null) return;
                    if (DateTime.now().difference(ts) >=
                        const Duration(milliseconds: 290)) {
                      runSearch(usernameController.text, setSheetState);
                    }
                  });
                }

                Future<void> sendRequest(String username) async {
                  if (requestedUsernames.contains(username)) return;
                  setSheetState(() => requestedUsernames.add(username));
                  try {
                    await _sharingService.sendShareRequest(
                      recipientUsername: username,
                      message: messageController.text.trim().isEmpty
                          ? null
                          : messageController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Request sent to @$username')),
                    );
                  } catch (e) {
                    setSheetState(() => requestedUsernames.remove(username));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send request: $e')),
                    );
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Discover users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Search username',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => onUsernameChanged(),
                        autofocus: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: 'Optional message',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isSearching)
                        const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final profile = results[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text('@${profile.username}'),
                              subtitle: Text(
                                'Joined ${profile.createdAt.toLocal().toIso8601String().substring(0, 10)}',
                              ),
                              trailing: FilledButton(
                                onPressed:
                                    requestedUsernames.contains(
                                      profile.username,
                                    )
                                    ? null
                                    : () => sendRequest(profile.username),
                                child:
                                    requestedUsernames.contains(
                                      profile.username,
                                    )
                                    ? const Text('Requested')
                                    : const Text('Request'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openIncomingRequestsSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            List<ShareRequestWithProfile> requests = [];
            bool loading = true;

            Future<void> load(
              void Function(void Function()) setSheetState,
            ) async {
              setSheetState(() => loading = true);
              try {
                final fetched = await _sharingService.getIncomingShareRequests(
                  status: ShareRequestStatus.pending,
                );
                setSheetState(() => requests = fetched);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load requests: $e')),
                  );
                }
              } finally {
                setSheetState(() => loading = false);
              }
            }

            return StatefulBuilder(
              builder: (context, setSheetState) {
                Future<void> respond(
                  ShareRequestWithProfile item,
                  ShareRequestStatus response,
                ) async {
                  try {
                    await _sharingService.respondToShareRequestSimple(
                      item.request.id,
                      response,
                    );
                    setSheetState(() {
                      requests = requests
                          .where((r) => r.request.id != item.request.id)
                          .toList();
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response == ShareRequestStatus.accepted
                              ? 'Request accepted'
                              : 'Request declined',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Action failed: $e')),
                    );
                  }
                }

                if (loading && requests.isEmpty) {
                  // initial load
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    load(setSheetState);
                  });
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Incoming requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => load(setSheetState),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 8),
                      Expanded(
                        child: requests.isEmpty
                            ? const Center(child: Text('No pending requests'))
                            : ListView.builder(
                                controller: controller,
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  final item = requests[index];
                                  final from =
                                      item.requesterProfile?.username ?? 'user';
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'From @${from}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if ((item.request.message ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              child: Text(
                                                item.request.message!,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              FilledButton.icon(
                                                onPressed: () => respond(
                                                  item,
                                                  ShareRequestStatus.accepted,
                                                ),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                ),
                                                label: const Text('Accept'),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton.icon(
                                                onPressed: () => respond(
                                                  item,
                                                  ShareRequestStatus.declined,
                                                ),
                                                icon: const Icon(Icons.close),
                                                label: const Text('Decline'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
