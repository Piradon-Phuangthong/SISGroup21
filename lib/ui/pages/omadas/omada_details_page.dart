import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = OmadaServiceExtended(Supabase.instance.client);
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _omada == null) {
      return Scaffold(
        appBar: AppBar(),
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

    // Use stored color, or generate a consistent color based on the name
    final colorValue = _omada!.color != null
        ? ColorUtils.parseColor(
            _omada!.color,
            fallback: ColorUtils.getColorForString(_omada!.name),
          )
        : ColorUtils.getColorForString(_omada!.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(_omada!.name),
        actions: [
          if (_myRole != OmadaRole.owner)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveOmada,
              tooltip: 'Leave Omada',
            ),
          if (_myRole == OmadaRole.owner)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            color: colorValue.withOpacity(0.1),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorValue,
                  child: Text(
                    _omada!.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: ColorUtils.getContrastingTextColor(colorValue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _omada!.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_omada!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _omada!.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(_myRole?.displayName ?? 'Not a member'),
                      avatar: Icon(_getRoleIcon(_myRole), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Chip(label: Text('${_members.length} members')),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
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
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMembersTab(), _buildRequestsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(child: Text('No members'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final canManage = _myRole != null && _myRole!.canManage(member.role);

        return ListTile(
          leading: CircleAvatar(
            child: Text((member.userName ?? 'U')[0].toUpperCase()),
          ),
          title: Text(member.userName ?? 'Unknown User'),
          subtitle: Text(member.role.displayName),
          trailing: canManage
              ? PopupMenuButton(
                  itemBuilder: (context) => [
                    if (member.role != OmadaRole.admin)
                      const PopupMenuItem(
                        value: 'promote',
                        child: Text('Promote to Admin'),
                      ),
                    if (member.role != OmadaRole.member)
                      const PopupMenuItem(
                        value: 'demote',
                        child: Text('Demote to Member'),
                      ),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                  onSelected: (value) => _handleMemberAction(value, member),
                )
              : null,
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

    if (_pendingRequests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text((request.userName ?? 'U')[0].toUpperCase()),
            ),
            title: Text(request.userName ?? 'Unknown User'),
            subtitle: Text('Requested: ${_formatDate(request.createdAt)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _approveRequest(request.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _rejectRequest(request.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getRoleIcon(OmadaRole? role) {
    if (role == null) return Icons.person_outline;
    switch (role) {
      case OmadaRole.owner:
        return Icons.workspace_premium;
      case OmadaRole.admin:
        return Icons.admin_panel_settings;
      case OmadaRole.moderator:
        return Icons.verified_user;
      case OmadaRole.member:
        return Icons.person;
      case OmadaRole.guest:
        return Icons.person_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      await _service.approveJoinRequest(requestId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request approved')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _service.rejectJoinRequest(requestId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request rejected')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
