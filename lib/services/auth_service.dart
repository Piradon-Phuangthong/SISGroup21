import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'models/profile_model.dart';

/// Authentication service for user sign up, sign in, and profile management
class AuthService {
  /// Sign up new user with email and password
  /// TODO: Implement user registration with profile creation
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // TODO: First check if username is available
      final isUsernameAvailable = await checkUsernameAvailability(username);
      if (!isUsernameAvailable) {
        throw Exception('Username is already taken');
      }

      // TODO: Sign up user with Supabase Auth
      final response = await SupabaseClientService.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // TODO: Create profile record with username
        await _createUserProfile(response.user!.id, username);
      }

      return response;
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Sign in existing user with email and password
  /// TODO: Implement user authentication
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Sign in user with Supabase Auth
      final response = await SupabaseClientService.client.auth
          .signInWithPassword(email: email, password: password);

      return response;
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Sign out current user
  /// TODO: Implement user sign out
  static Future<void> signOut() async {
    try {
      // TODO: Sign out from Supabase Auth
      await SupabaseClientService.signOut();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Check if username is available
  /// TODO: Implement username availability check
  static Future<bool> checkUsernameAvailability(String username) async {
    try {
      // TODO: Query profiles table to check if username exists
      final response = await SupabaseClientService.client
          .from('profiles')
          .select('username')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      return response == null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return false;
    }
  }

  /// Get current user profile
  /// TODO: Implement profile retrieval
  static Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final user = SupabaseClientService.currentUser;
      if (user == null) return null;

      // TODO: Query profiles table for current user
      final response = await SupabaseClientService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return ProfileModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Update user profile
  /// TODO: Implement profile updates
  static Future<ProfileModel> updateProfile({required String username}) async {
    try {
      final user = SupabaseClientService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // TODO: Check if new username is available (if changed)
      final currentProfile = await getCurrentUserProfile();
      if (currentProfile?.username != username.toLowerCase()) {
        final isUsernameAvailable = await checkUsernameAvailability(username);
        if (!isUsernameAvailable) {
          throw Exception('Username is already taken');
        }
      }

      // TODO: Update profile in database
      final response = await SupabaseClientService.client
          .from('profiles')
          .update({'username': username.toLowerCase()})
          .eq('id', user.id)
          .select()
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Reset password
  /// TODO: Implement password reset
  static Future<void> resetPassword(String email) async {
    try {
      // TODO: Send password reset email
      await SupabaseClientService.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Create user profile after successful sign up
  /// TODO: Implement profile creation
  static Future<void> _createUserProfile(String userId, String username) async {
    try {
      // TODO: Insert new profile record
      await SupabaseClientService.client.from('profiles').insert({
        'id': userId,
        'username': username.toLowerCase(),
      });
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Delete user account and all associated data
  /// TODO: Implement account deletion
  static Future<void> deleteAccount() async {
    try {
      final user = SupabaseClientService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // TODO: Delete all user data (contacts, tags, shares, etc.)
      // This should be handled by database triggers or RLS policies
      // For now, just delete the profile (which should cascade)
      await SupabaseClientService.client
          .from('profiles')
          .delete()
          .eq('id', user.id);

      // TODO: Delete auth user account
      // Note: This might require admin privileges depending on setup
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Listen to auth state changes
  /// TODO: Implement auth state monitoring
  static Stream<AuthState> get authStateChanges =>
      SupabaseClientService.authStateChanges;
}
