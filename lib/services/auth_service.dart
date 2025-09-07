import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'supabase_config.dart';
import 'models/profile_model.dart';

/// Authentication service for user sign up, sign in, and profile management
class AuthService {
  // -----------------------------
  // Sign up
  // -----------------------------
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final client = SupabaseClientService.client;
    final uname = username.trim().toLowerCase();

    // 1) Check username availability (fast-fail)
    final available = await checkUsernameAvailability(uname);
    if (!available) {
      throw AuthException('Username is already taken');
    }

    // 2) Sign up (store username in user_metadata as well)
    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': uname},
      // If you want confirm-email flow to return to app:
      // emailRedirectTo: SupabaseConfig.redirectUri,
    );

    // 3) Create profile row if we have a user
    final uid = res.user?.id;
    if (uid != null) {
      try {
        await client.from('profiles').insert({
          'id': uid,
          'username': uname,
        });
      } on PostgrestException catch (e) {
        // If a trigger already created it or unique constraint hit, ignore
        final msg = (e.message ?? '').toLowerCase();
        if (!(msg.contains('duplicate') || msg.contains('unique'))) {
          rethrow;
        }
      }
    }

    return res;
  }

  // -----------------------------
  // Sign in
  // -----------------------------
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await SupabaseClientService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      // Surface a friendly message
      final code = (e.message).toLowerCase();
      if (code.contains('invalid login') || code.contains('invalid credentials')) {
        throw AuthException('Invalid email or password');
      }
      rethrow;
    }
  }

  // -----------------------------
  // Sign out
  // -----------------------------
  static Future<void> signOut() async {
    await SupabaseClientService.signOut(all: true);
  }

  // -----------------------------
  // Username availability
  // -----------------------------
  static Future<bool> checkUsernameAvailability(String username) async {
    final uname = username.trim().toLowerCase();

    // Rely on a case-insensitive unique in DB if you have one; otherwise use ilike.
    // (Best: UNIQUE index on lower(username).)
    final row = await SupabaseClientService.client
        .from('profiles')
        .select('id')
        .eq('username', uname)
        .maybeSingle();

    return row == null; // available if no row found
  }

  // -----------------------------
  // Current user profile
  // -----------------------------
  static Future<ProfileModel?> getCurrentUserProfile() async {
    final user = SupabaseClientService.currentUser;
    if (user == null) return null;

    final row = await SupabaseClientService.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return row != null ? ProfileModel.fromJson(row) : null;
  }

  // -----------------------------
  // Update profile (username)
  // -----------------------------
  static Future<ProfileModel> updateProfile({required String username}) async {
    final user = SupabaseClientService.currentUser;
    if (user == null) throw AuthException('User not authenticated');

    final uname = username.trim().toLowerCase();
    final current = await getCurrentUserProfile();

    if (current?.username != uname) {
      final available = await checkUsernameAvailability(uname);
      if (!available) {
        throw AuthException('Username is already taken');
      }
    }

    final updated = await SupabaseClientService.client
        .from('profiles')
        .update({'username': uname})
        .eq('id', user.id)
        .select()
        .single();

    return ProfileModel.fromJson(updated);
  }

  // -----------------------------
  // Reset password (email link)
  // -----------------------------
  static Future<void> resetPassword(String email) async {
    await SupabaseClientService.client.auth.resetPasswordForEmail(
      email.trim(),
      // So the user gets routed back into your app for password update:
      redirectTo: SupabaseConfig.redirectUri,  //HEREEEEEE
    );
  }

  // -----------------------------
  // Delete account (client side)
  // -----------------------------
  static Future<void> deleteAccount() async {
    final user = SupabaseClientService.currentUser;
    if (user == null) throw AuthException('User not authenticated');

    // Delete profile (and let ON DELETE CASCADE clean up dependent rows if set)
    await SupabaseClientService.client.from('profiles').delete().eq('id', user.id);

    // Deleting the auth user itself requires a SERVICE ROLE key and
    // should be done via a secure server/Edge Function you control.
    // Example (server side):
    // await supabaseAdmin.auth.admin.deleteUser(user.id);
  }

  // -----------------------------
  // Auth state stream passthrough
  // -----------------------------
  static Stream<AuthState> get authStateChanges =>
      SupabaseClientService.authStateChanges;
}
