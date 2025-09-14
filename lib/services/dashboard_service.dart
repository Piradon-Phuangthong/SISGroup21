// lib/services/dashboard_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model to hold dashboard summary data
class DashboardSummary {
  final int contactCount;
  final int channelCount;

  DashboardSummary({
    required this.contactCount,
    required this.channelCount,
  });
}

/// Model to hold recent activity (can be extended)
class DashboardActivity {
  final String description;
  final DateTime timestamp;

  DashboardActivity({
    required this.description,
    required this.timestamp,
  });
}

/// Dashboard Service - handles all backend logic for the home page dashboard
class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch summary counts (contacts & channels)
  Future<DashboardSummary> fetchSummary(String userId) async {
    try {
      final contactRes = await _client
          .from('contacts')
          .select('id')
          .eq('user_id', userId);

      final channelRes = await _client
          .from('contact_channels')
          .select('id')
          .eq('user_id', userId);

      return DashboardSummary(
        contactCount: contactRes.length,
        channelCount: channelRes.length,
      );
    } catch (e) {
      // Safe fallback with defaults
      return DashboardSummary(contactCount: 0, channelCount: 0);
    }
  }

  /// Fetch recent activity (e.g., last 5 updates)
  Future<List<DashboardActivity>> fetchRecentActivity(String userId) async {
    try {
      final response = await _client
          .from('contacts')
          .select('full_name, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(5);

      return response.map<DashboardActivity>((row) {
        return DashboardActivity(
          description: "Updated contact: ${row['full_name']}",
          timestamp: DateTime.parse(row['updated_at']),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Subscribe to contact changes (real-time updates)
  void subscribeToChanges(String userId, void Function() onChange) {
    _client
        .from('contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((event) {
      onChange();
    });
  }
}
