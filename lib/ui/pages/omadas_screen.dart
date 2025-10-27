import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/theme/design_tokens.dart';
import 'package:omada/ui/widgets/app_bottom_nav.dart';
import 'package:omada/core/utils/color_utils.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/omada_service_extended.dart';
import 'omadas/omada_card.dart';
import 'omadas/create_omada_sheet.dart';
import 'omadas/omada_details_page.dart';
import 'package:omada/core/theme/color_palette.dart';

// New Omada headers (same style as Contacts, but customized)
import 'omadas/omada_header/expanded_omada_header.dart';
import 'omadas/omada_header/collapsed_omada_header.dart';

class OmadasScreen extends StatefulWidget {
  const OmadasScreen({super.key});
  @override
  State<OmadasScreen> createState() => _OmadasScreenState();
}

class _OmadasScreenState extends State<OmadasScreen> {
  late final OmadaServiceExtended _omadaService;

  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastSearchChangeAt;

  List<OmadaModel> _myOmadas = [];
  List<OmadaModel> _visibleOmadas = [];
  List<OmadaModel> _publicOmadas = [];
  List<JoinRequestModel> _myRequests = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _omadaService = OmadaServiceExtended(Supabase.instance.client);
    _searchController.addListener(_onSearchChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ───────────────────── Data ─────────────────────
  Future<void> _loadAll() async {
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
      _myOmadas = results[0] as List<OmadaModel>;
      _publicOmadas = results[1] as List<OmadaModel>;
      _myRequests = results[2] as List<JoinRequestModel>;
      _applyClientFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ───────────────────── Search (debounce) ─────────────────────
  void _onSearchChanged() {
    _lastSearchChangeAt = DateTime.now();
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      final last = _lastSearchChangeAt;
      if (last == null) return;
      if (DateTime.now().difference(last) >=
          const Duration(milliseconds: 290)) {
        _applyClientFilters();
      }
    });
    _applyClientFilters();
  }

  void _applyClientFilters() {
    final q = _searchController.text.trim().toLowerCase();
    var filtered = List.of(_myOmadas);
    if (q.isNotEmpty) {
      filtered = filtered.where((o) {
        final s = [
          o.name,
          o.description ?? '',
          o.joinPolicy.displayName,
          (o.memberCount ?? 0).toString(),
        ].join(' ').toLowerCase();
        return s.contains(q);
      }).toList();
    }
    setState(() => _visibleOmadas = filtered);
  }

  // ───────────────────── Actions (header buttons) ─────────────────────
  Future<void> _showCreateOmadaSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateOmadaSheet(
        onCreated: (omada) {
          Navigator.pop(context);
          _loadAll();
          _navigateToOmada(omada);
        },
      ),
    );
  }

  void _navigateToOmada(OmadaModel omada) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OmadaDetailsPage(omadaId: omada.id)),
    ).then((_) => _loadAll());
  }

  Future<void> _requestToJoin(OmadaModel omada) async {
    try {
      await _omadaService.requestToJoin(omada.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            omada.joinPolicy == JoinPolicy.open
                ? 'Joined ${omada.name} successfully!'
                : 'Join request sent to ${omada.name}',
          ),
        ),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openDiscoverSheet() async {
    try {
      _publicOmadas = await _omadaService.getPublicOmadas();
      print('✅ Loaded ${_publicOmadas.length} public omadas for discovery');
    } catch (e, stackTrace) {
      print('❌ Error loading public omadas: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load public omadas: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DiscoverOmadasSheet(
        publicOmadas: _publicOmadas,
        myOmadas: _myOmadas,
        myRequests: _myRequests,
        onJoinOrRequest: _requestToJoin,
        onOpenOmada: _navigateToOmada,
      ),
    );

    await _loadAll();
  }

  Future<void> _openRequestsSheet() async {
    try {
      _myRequests = await _omadaService.getMyJoinRequests();
    } catch (_) {}
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _RequestsSheet(requests: _myRequests, onCancel: _cancelRequest),
    );

    await _loadAll();
  }

  Future<void> _cancelRequest(String omadaId) async {
    try {
      await _omadaService.cancelJoinRequest(omadaId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ───────────────────── UI (Sliver with custom headers) ─────────────────────
  @override
  Widget build(BuildContext context) {
    const double expandedHeight = 300;
    const double collapsedHeight = 96;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
            pinned: true,
            forceMaterialTransparency: true,
            automaticallyImplyLeading: false, // 🚫 remove useless back button
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                const double collpasedThreshold = 0.99;
                final currentHeight = constraints.biggest.height;
                final double t =
                    ((currentHeight - collapsedHeight) /
                            (expandedHeight - collapsedHeight))
                        .clamp(0.0, 1.0);

                if (t > collpasedThreshold) {
                  return ExpandedOmadaHeader(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onDiscover: _openDiscoverSheet,
                    onRequests: _openRequestsSheet,
                    onCreate: _showCreateOmadaSheet,
                    // tweak gradient here if you like:
                    gradientStart: const Color(0xFF64bdfb),
                    gradientEnd: const Color(0xFFa257e8),
                  );
                } else {
                  return CollapsedOmadaHeader(
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onCreate: _showCreateOmadaSheet,
                    gradientStart: const Color(0xFF64bdfb),
                    gradientEnd: const Color(0xFFa257e8),
                  );
                }
              },
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (_isLoading && _visibleOmadas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_error != null && _visibleOmadas.isEmpty) {
                return _buildError();
              }
              if (_visibleOmadas.isEmpty) {
                return _buildEmpty();
              }

              final omada = _visibleOmadas[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OmadaTokens.space16,
                  vertical: OmadaTokens.space8,
                ),
                child: OmadaCard(
                  omada: omada,
                  onTap: () => _navigateToOmada(omada),
                ),
              );
            }, childCount: _childCount()),
          ),
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

  int _childCount() {
    if (_isLoading && _visibleOmadas.isEmpty) return 1;
    if (_error != null && _visibleOmadas.isEmpty) return 1;
    if (_visibleOmadas.isEmpty) return 1;
    return _visibleOmadas.length;
  }

  Widget _buildError() {
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
            ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: const [
          Icon(Icons.group_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 12),
          Text('No Omadas yet'),
          SizedBox(height: 4),
          Text('Tap + to create your first Omada'),
        ],
      ),
    );
  }
}

// ───────────────────── Bottom sheet: Discover ─────────────────────
class _DiscoverOmadasSheet extends StatelessWidget {
  const _DiscoverOmadasSheet({
    required this.publicOmadas,
    required this.myOmadas,
    required this.myRequests,
    required this.onJoinOrRequest,
    required this.onOpenOmada,
  });

  final List<OmadaModel> publicOmadas;
  final List<OmadaModel> myOmadas;
  final List<JoinRequestModel> myRequests;
  final void Function(OmadaModel) onJoinOrRequest;
  final void Function(OmadaModel) onOpenOmada;

  bool _isMember(OmadaModel o) => myOmadas.any((m) => m.id == o.id);
  bool _hasPending(String id) =>
      myRequests.any((r) => r.omadaId == id && r.isPending);

  @override
  Widget build(BuildContext context) {
    if (publicOmadas.isEmpty) {
      return const SafeArea(
        child: Center(child: Text('No public Omadas available')),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(OmadaTokens.space16),
            itemCount: publicOmadas.length,
            itemBuilder: (context, index) {
              final omada = publicOmadas[index];
              final isMember = _isMember(omada);
              final pending = _hasPending(omada.id);

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
                      : pending
                      ? const Chip(
                          label: Text('Pending'),
                          backgroundColor: Colors.orange,
                        )
                      : IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => onJoinOrRequest(omada),
                        ),
                  onTap: isMember ? () => onOpenOmada(omada) : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ───────────────────── Bottom sheet: Requests ─────────────────────
class _RequestsSheet extends StatelessWidget {
  const _RequestsSheet({required this.requests, required this.onCancel});

  final List<JoinRequestModel> requests;
  final Future<void> Function(String omadaId) onCancel;

  IconData _icon(JoinRequestStatus s) {
    switch (s) {
      case JoinRequestStatus.pending:
        return Icons.pending;
      case JoinRequestStatus.approved:
        return Icons.check_circle;
      case JoinRequestStatus.rejected:
        return Icons.cancel;
    }
  }

  String _fmt(DateTime d) {
    final now = DateTime.now(), diff = now.difference(d);
    if (diff.inDays > 7) return '${d.day}/${d.month}/${d.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const SafeArea(child: Center(child: Text('No join requests')));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(OmadaTokens.space16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_icon(r.status))),
                  title: Text(r.omadaName ?? 'Unknown Omada'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${r.status.dbValue}'),
                      Text(
                        'Requested: ${_fmt(r.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (r.reviewedAt != null)
                        Text(
                          'Reviewed: ${_fmt(r.reviewedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: r.isPending
                      ? IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () => onCancel(r.omadaId),
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
