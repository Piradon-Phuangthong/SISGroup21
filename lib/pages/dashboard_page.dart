import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dashboard_service.dart';  // adjust path if needed

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  DashboardSummary? _summary;
  List<DashboardActivity> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToChanges();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final summary = await _dashboardService.fetchSummary(userId);
    final activities = await _dashboardService.fetchRecentActivity(userId);

    setState(() {
      _summary = summary;
      _activities = activities;
      _loading = false;
    });
  }

  void _subscribeToChanges() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _dashboardService.subscribeToChanges(userId, () {
      _loadData(); // refresh dashboard whenever contacts change
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary section
            Text(
              "Contacts: ${_summary?.contactCount ?? 0}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              "Channels: ${_summary?.channelCount ?? 0}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Recent activity section
            Text(
              "Recent Activity",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _activities.isEmpty
                  ? const Text("No recent activity")
                  : ListView.builder(
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return ListTile(
                          title: Text(activity.description),
                          subtitle: Text(activity.timestamp.toString()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
