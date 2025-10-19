import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/core/utils/color_utils.dart';
import 'omadas/omada_card.dart';
import 'omadas/create_omada_sheet.dart';
import 'omadas/omada_details_page.dart';

/// Main screen showing user's Omadas (groups they own or are member of)
class OmadasScreen extends StatefulWidget {
  const OmadasScreen({super.key});

  @override
  State<OmadasScreen> createState() => _OmadasScreenState();
}

class _OmadasScreenState extends State<OmadasScreen>
    with SingleTickerProviderStateMixin {
  late final OmadaServiceExtended _omadaService;
  late final TabController _tabController;

  List<OmadaModel> _myOmadas = [];
  List<OmadaModel> _publicOmadas = [];
  List<JoinRequestModel> _myRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _omadaService = OmadaServiceExtended(Supabase.instance.client);
    _tabController = TabController(length: 3, vsync: this);
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
        _omadaService.getMyOmadas(),
        _omadaService.getPublicOmadas(),
        _omadaService.getMyJoinRequests(),
      ]);

      setState(() {
        _myOmadas = results[0] as List<OmadaModel>;
        _publicOmadas = results[1] as List<OmadaModel>;
        _myRequests = results[2] as List<JoinRequestModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateOmadaSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateOmadaSheet(
        onCreated: (omada) {
          Navigator.pop(context);
          _loadData();
          _navigateToOmada(omada);
        },
      ),
    );
  }

  void _navigateToOmada(OmadaModel omada) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OmadaDetailsPage(omadaId: omada.id),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _requestToJoin(OmadaModel omada) async {
    try {
      await _omadaService.requestToJoin(omada.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            omada.joinPolicy == JoinPolicy.open
                ? 'Joined ${omada.name} successfully!'
                : 'Join request sent to ${omada.name}',
          ),
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Omadas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Omadas', icon: Icon(Icons.group)),
            Tab(text: 'Discover', icon: Icon(Icons.explore)),
            Tab(text: 'Requests', icon: Icon(Icons.pending)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyOmadasTab(),
                _buildDiscoverTab(),
                _buildRequestsTab(),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(active: AppNav.omadas),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOmadaSheet,
        tooltip: 'Create Omada',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildMyOmadasTab() {
    if (_myOmadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Omadas yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join an Omada to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateOmadaSheet,
              icon: const Icon(Icons.add),
              label: const Text('Create Omada'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myOmadas.length,
        itemBuilder: (context, index) {
          final omada = _myOmadas[index];
          return OmadaCard(omada: omada, onTap: () => _navigateToOmada(omada));
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_publicOmadas.isEmpty) {
      return const Center(child: Text('No public Omadas available'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicOmadas.length,
        itemBuilder: (context, index) {
          final omada = _publicOmadas[index];
          final isMember = _myOmadas.any((o) => o.id == omada.id);
          final hasPendingRequest = _myRequests.any(
            (r) => r.omadaId == omada.id && r.isPending,
          );

          final colorValue = omada.color != null
              ? ColorUtils.parseColor(
                  omada.color,
                  fallback: ColorUtils.getColorForString(omada.name),
                )
              : ColorUtils.getColorForString(omada.name);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorValue,
                child: Text(
                  omada.name[0].toUpperCase(),
                  style: TextStyle(
                    color: ColorUtils.getContrastingTextColor(colorValue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(omada.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (omada.description != null) Text(omada.description!),
                  const SizedBox(height: 4),
                  Text(
                    '${omada.memberCount ?? 0} members • ${omada.joinPolicy.displayName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: isMember
                  ? const Chip(
                      label: Text('Member'),
                      backgroundColor: Colors.green,
                    )
                  : hasPendingRequest
                  ? const Chip(
                      label: Text('Pending'),
                      backgroundColor: Colors.orange,
                    )
                  : IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _requestToJoin(omada),
                    ),
              onTap: isMember ? () => _navigateToOmada(omada) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_myRequests.isEmpty) {
      return const Center(child: Text('No join requests'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final request = _myRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(_getRequestStatusIcon(request.status)),
              ),
              title: Text(request.omadaName ?? 'Unknown Omada'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${request.status.dbValue}'),
                  Text(
                    'Requested: ${_formatDate(request.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (request.reviewedAt != null)
                    Text(
                      'Reviewed: ${_formatDate(request.reviewedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: request.isPending
                  ? IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () => _cancelRequest(request.omadaId),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  IconData _getRequestStatusIcon(JoinRequestStatus status) {
    switch (status) {
      case JoinRequestStatus.pending:
        return Icons.pending;
      case JoinRequestStatus.approved:
        return Icons.check_circle;
      case JoinRequestStatus.rejected:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _cancelRequest(String omadaId) async {
    try {
      await _omadaService.cancelJoinRequest(omadaId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
