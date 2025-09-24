import 'package:supabase_flutter/supabase_flutter.dart';

/// Encapsulates authentication-related operations.
class AuthController {
  final SupabaseClient client;
  AuthController(this.client);

  Stream<AuthState> onAuthStateChange() => client.auth.onAuthStateChange;

  Session? get currentSession => client.auth.currentSession;

  Future<UserResponse> getUser() => client.auth.getUser();

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return client.auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() => client.auth.signOut();
}
