import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase client configuration
class SupabaseClientService {
  static SupabaseClient? _client;

  /// Get the singleton Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase client not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// Initialize Supabase client
  /// TODO: Replace with your actual Supabase URL and anon key
  static Future<void> initialize() async {
    // TODO: Add your Supabase project URL and anon key here
    const supabaseUrl = 'YOUR_SUPABASE_URL';
    const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _client = Supabase.instance.client;
  }

  /// Get current authenticated user
  static User? get currentUser => _client?.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  static String? get currentUserId => currentUser?.id;

  /// Auth state stream
  static Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Sign out current user
  static Future<void> signOut() async {
    await _client?.auth.signOut();
  }
}
