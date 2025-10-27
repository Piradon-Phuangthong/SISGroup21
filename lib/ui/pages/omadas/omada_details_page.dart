import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/core/data/repositories/repositories.dart';
import 'package:omada/core/utils/color_utils.dart';

class OmadaDetailsPage extends StatefulWidget {
  final String omadaId;
  const OmadaDetailsPage({super.key, required this.omadaId});

  @override
  State<OmadaDetailsPage> createState() => _OmadaDetailsPageState();
}

class _OmadaDetailsPageState extends State<OmadaDetailsPage>
    with SingleTickerProviderStateMixin {
  late final OmadaServiceExtended _service;
  late final TabController _tabController;

  OmadaModel? _omada;
  OmadaRole? _myRole;
  List<OmadaMembershipModel> _members = [];
  List<JoinRequestModel> _pendingRequests = [];
  List<ProfileModel> _nonMembers = [];
  final TextEditingController _userSearchController = TextEditingController();
  bool _loadingNonMembers = false;
  // Friend/share state
  late final SharingService _sharingService;
  late final ProfileRepository _profileRepo;
  Map<String, String> _memberUsernames = {};
  Map<String, bool> _isFriend = {};
  bool _loadingFriendStatus = false;

  bool _isLoading = true;
  String? _error;

  static const Color _gradStart = Color(0xFFa257e8);
  static const Color _gradEnd = Color(0xFF64bdfb);

  @override
  void initState() {
    super.initState();
    _service = OmadaServiceExtended(Supabase.instance.client);
    _sharingService = SharingService(Supabase.instance.client);
    _profileRepo = ProfileRepository(Supabase.instance.client);
    _tabController = TabController(length: 3, vsync: this);
    _userSearchController.addListener(_onUserSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.removeListener(_onUserSearchChanged);
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getOmadaById(widget.omadaId),
        _service.getUserRole(widget.omadaId),
        _service.getOmadaMemberships(widget.omadaId),
        _service
            .getPendingRequests(widget.omadaId)
            .catchError((_) => <JoinRequestModel>[]),
      ]);
      setState(() {
        _omada = results[0] as OmadaModel?;
        _myRole = results[1] as OmadaRole?;
        _members = results[2] as List<OmadaMembershipModel>;
        _pendingRequests = results[3] as List<JoinRequestModel>;
        _isLoading = false;
      });
      // Load discoverable non-members once base data is ready
      await _loadNonMembers();
      // Load member profile usernames and friendship (active shares) status
      await _loadMemberProfilesAndFriendStatus();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMemberProfilesAndFriendStatus() async {
    try {
      setState(() => _loadingFriendStatus = true);

      final userIds = _members.map((m) => m.userId).toSet().toList();
      if (userIds.isEmpty) {
        setState(() {
          _memberUsernames = {};
          _isFriend = {};
        });
        return;
      }

      // Fetch profiles in bulk to get usernames
      final profiles = await _profileRepo.getProfilesByIds(userIds);
      final usernameMap = {for (final p in profiles) p.id: p.username};

      // Fill any missing from membership userName
      for (final m in _members) {
        usernameMap.putIfAbsent(m.userId, () => m.userName ?? '');
      }

      // Check active shares (friendship proxy) in parallel
      final futures = userIds
          .map((id) => _sharingService.hasActiveShareWithUser(id))
          .toList();
      final results = await Future.wait(futures);

      final friendMap = <String, bool>{};
      for (var i = 0; i < userIds.length; i++) {
        friendMap[userIds[i]] = results[i];
      }

      if (mounted)
        setState(() {
          _memberUsernames = usernameMap;
          _isFriend = friendMap;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _memberUsernames = {};
          _isFriend = {};
        });
    } finally {
      if (mounted) setState(() => _loadingFriendStatus = false);
    }
  }

  Future<void> _sendShareRequestToMember(String userId, String username) async {
    try {
      if (username.isEmpty) throw Exception('Recipient username unknown');
      await _sharingService.sendShareRequest(recipientUsername: username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share request sent to $username')),
      );
      // No active share yet; refresh outgoing requests or friend status if desired
      await _loadMemberProfilesAndFriendStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadNonMembers() async {
    try {
      setState(() => _loadingNonMembers = true);
      final list = await _service.getNonMembers(
        widget.omadaId,
        search: _userSearchController.text,
        limit: 50,
      );
      if (mounted) setState(() => _nonMembers = list);
    } catch (_) {
      if (mounted) setState(() => _nonMembers = []);
    } finally {
      if (mounted) setState(() => _loadingNonMembers = false);
    }
  }

  DateTime? _lastUserSearchChangeAt;
  void _onUserSearchChanged() {
    _lastUserSearchChangeAt = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300)).then((_) async {
      final last = _lastUserSearchChangeAt;
      if (last == null) return;
      if (DateTime.now().difference(last) >=
          const Duration(milliseconds: 290)) {
        await _loadNonMembers();
      }
    });
  }

  Future<void> _leaveOmada() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Omada?'),
        content: const Text('Are you sure you want to leave this Omada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.leaveOmada(widget.omadaId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _omada == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final colorValue = _omada!.color != null
        ? ColorUtils.parseColor(
            _omada!.color,
            fallback: ColorUtils.getColorForString(_omada!.name),
          )
        : ColorUtils.getColorForString(_omada!.name);

    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Fixed, overflow-proof header (no internal toolbar)
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            collapsedHeight: 300, // fixed height ⇒ header never collapses
            toolbarHeight: 0, // ⬅ remove reserved toolbar space
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            forceMaterialTransparency: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_gradStart, _gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Manual toolbar row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const Spacer(),
                          if (_myRole != OmadaRole.owner)
                            IconButton(
                              icon: const Icon(
                                Icons.exit_to_app,
                                color: Colors.white,
                              ),
                              tooltip: 'Leave Omada',
                              onPressed: _leaveOmada,
                            ),
                          if (_myRole == OmadaRole.owner)
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                /* TODO */
                              },
                            ),
                        ],
                      ),

                      // Content
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: colorValue,
                        child: Text(
                          _omada!.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: ColorUtils.getContrastingTextColor(
                              colorValue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _omada!.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_omada!.description != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _omada!.description!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _chip(
                            Icons.verified_user,
                            _myRole?.displayName ?? 'Not a member',
                          ),
                          _chip(Icons.groups, '${_members.length} members'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pinned TabBar right under the header with extra headroom
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeaderDelegate(
              height: kTextTabBarHeight + 28, // 76 px headroom
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gradStart, _gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0x14000000), width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                alignment: Alignment.center,
                child: SizedBox(
                  height: kTextTabBarHeight, // 48 px
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorWeight: 2,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        text: 'Members',
                        icon: Badge(
                          label: Text('${_members.length}'),
                          child: const Icon(Icons.people),
                        ),
                      ),
                      Tab(
                        text: 'Requests',
                        icon: Badge(
                          label: Text('${_pendingRequests.length}'),
                          isLabelVisible: _pendingRequests.isNotEmpty,
                          child: const Icon(Icons.pending),
                        ),
                      ),
                      const Tab(
                        text: 'Add',
                        icon: Icon(Icons.person_add_alt_1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        // Only the list moves
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMembersTab(),
            _buildRequestsTab(),
            _buildAddPeopleTab(),
          ],
        ),
      ),
    );
  }

  // Tabs
  Widget _buildMembersTab() {
    if (_members.isEmpty) return const Center(child: Text('No members'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final m = _members[index];
        final canManage = _myRole != null && _myRole!.canManage(m.role);
        final username = _memberUsernames[m.userId] ?? m.userName ?? '';
        final isFriend = _isFriend[m.userId] ?? false;
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              (username.isNotEmpty ? username[0] : 'U').toUpperCase(),
            ),
          ),
          title: Text(
            username.isNotEmpty ? username : (m.userName ?? 'Unknown User'),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.role.displayName),
              const SizedBox(height: 4),
              if (_loadingFriendStatus)
                const Text(
                  'Checking friendship...',
                  style: TextStyle(fontSize: 12),
                )
              else if (isFriend)
                const Text(
                  'Friend',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                )
              else
                const Text(
                  'Not friends',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isFriend && !_loadingFriendStatus)
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1),
                  tooltip: 'Send share request',
                  onPressed: () =>
                      _sendShareRequestToMember(m.userId, username),
                ),
              if (canManage)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (m.role != OmadaRole.admin)
                      const PopupMenuItem(
                        value: 'promote',
                        child: Text('Promote to Admin'),
                      ),
                    if (m.role != OmadaRole.member)
                      const PopupMenuItem(
                        value: 'demote',
                        child: Text('Demote to Member'),
                      ),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                  onSelected: (value) => _handleMemberAction(value, m),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    if (!(_myRole?.hasPermission(OmadaRole.moderator) ?? false)) {
      return const Center(
        child: Text('You do not have permission to view requests'),
      );
    }
    if (_pendingRequests.isEmpty)
      return const Center(child: Text('No pending requests'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final r = _pendingRequests[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text((r.userName ?? 'U')[0].toUpperCase()),
            ),
            title: Text(r.userName ?? 'Unknown User'),
            subtitle: Text('Requested: ${_formatDate(r.createdAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveRequest(r.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectRequest(r.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddPeopleTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search users by username',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        if (_loadingNonMembers)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: LinearProgressIndicator(),
          ),
        Expanded(
          child: _nonMembers.isEmpty
              ? const Center(child: Text('No users to add'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: _nonMembers.length,
                  itemBuilder: (context, index) {
                    final p = _nonMembers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(p.username[0].toUpperCase()),
                      ),
                      title: Text(p.username),
                      subtitle: const Text('Not added'),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _inviteUser(p.id, p.username),
                        tooltip: 'Request to add',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _inviteUser(String userId, String username) async {
    try {
      await _service.inviteUserToOmada(widget.omadaId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Requested $username to join')));
      await _loadNonMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Helpers
  static Widget _chip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      backgroundColor: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // Note: role icon helper removed (unused)

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Future<void> _handleMemberAction(
    String action,
    OmadaMembershipModel member,
  ) async {
    try {
      switch (action) {
        case 'promote':
          await _service.updateMemberRole(
            widget.omadaId,
            member.userId,
            OmadaRole.admin,
          );
          break;
        case 'demote':
          await _service.updateMemberRole(
            widget.omadaId,
            member.userId,
            OmadaRole.member,
          );
          break;
        case 'remove':
          await _service.removeMember(widget.omadaId, member.userId);
          break;
      }
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await _service.approveJoinRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request approved')));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _service.rejectJoinRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request rejected')));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabBarHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
