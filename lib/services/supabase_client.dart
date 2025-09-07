import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart'; // << put your URL/keys & bucket names here

/// Centralized Supabase client configuration
class SupabaseClientService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Get the singleton Supabase client instance
  static SupabaseClient get client {
    final c = _client;
    if (c == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return c;
  }

  /// Current session (null if signed out)
  static Session? get session => _client?.auth.currentSession;

  /// Current authenticated user (null if signed out)
  static User? get currentUser => _client?.auth.currentUser;

  /// Is user authenticated?
  static bool get isAuthenticated => currentUser != null;

  /// Current user ID
  static String? get currentUserId => currentUser?.id;

  /// Auth state stream
  static Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  /// Initialize Supabase client once
  static Future<void> initialize() async {
    if (_initialized) return;

    // If you use custom deep links for PKCE / magic links, configure here.
    // Example app scheme: com.example.contacts://login-callback
    // For web, set your site URL in the Supabase dashboard.
    final redirectUri = kIsWeb ? null : SupabaseConfig.redirectUri;

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // NOTE: If you aren’t using magic links/OAuth yet, this is still safe.
        // When you do, make sure this matches the app’s deep link config.
        
        // persistSession defaults to true; keep it so users stay signed in.
      ),
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// Sign out current user (everywhere by default = true clears refresh tokens on server)
  static Future<void> signOut({bool all = true}) async {
    await _client?.auth.signOut(scope: all ? SignOutScope.global : SignOutScope.local);
  }

  /// Simple email/password sign up (creates a profile row after sign up)
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    // Create a minimal profile row if sign up succeeded
    final uid = res.user?.id;
    if (uid != null) {
      await client.from('profiles').insert({'id': uid, 'username': username}).onError((e, _) {
        // Swallow unique/duplicate errors; profile might be created by a DB trigger.
        return null;
      });
    }
    return res;
  }

  /// Simple email/password sign in
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Optional: OAuth sign in helper (e.g., with Google/Apple) when you add it
  static Future<void> signInWithOAuth(OAuthProvider provider) async {
    await client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : SupabaseConfig.redirectUri,
      // scopes: 'email profile', // add if needed
    );
  }

  /// Example Edge Function invoker (handy later)
  static Future<dynamic> callFunction(String name, {Map<String, dynamic>? body}) async {
    final resp = await client.functions.invoke(name, body: body ?? {});
    return resp.data;
  }
}
