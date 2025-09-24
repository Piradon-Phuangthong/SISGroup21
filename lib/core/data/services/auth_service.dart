import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../exceptions/exceptions.dart' as exceptions;

/// Service for authentication and user management
class AuthService {
  final SupabaseClient _client;
  final ProfileRepository _profileRepository;

  AuthService(this._client) : _profileRepository = ProfileRepository(_client);

  /// Gets the current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Gets the current user's profile
  Future<ProfileModel?> get currentProfile async {
    return await _profileRepository.getCurrentProfile();
  }

  /// Checks if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Signs up a new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );

      if (response.user == null) {
        throw exceptions.AuthException('Sign up failed: No user returned');
      }

      return response;
    } catch (e) {
      if (e is exceptions.AuthException) rethrow;
      throw exceptions.AuthException(
        'Sign up failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Signs in a user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw exceptions.AuthException('Sign in failed: Invalid credentials');
      }

      return response;
    } catch (e) {
      if (e is exceptions.AuthException) rethrow;
      throw exceptions.AuthException(
        'Sign in failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw exceptions.AuthException(
        'Sign out failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Sends a password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw exceptions.AuthException(
        'Password reset failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Updates the user's password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw exceptions.AuthException('Password update failed');
      }

      return response;
    } catch (e) {
      if (e is exceptions.AuthException) rethrow;
      throw exceptions.AuthException(
        'Password update failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Updates the user's email
  Future<UserResponse> updateEmail(String newEmail) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (response.user == null) {
        throw exceptions.AuthException('Email update failed');
      }

      return response;
    } catch (e) {
      if (e is exceptions.AuthException) rethrow;
      throw exceptions.AuthException(
        'Email update failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Updates the user's profile username
  Future<ProfileModel> updateUsername(String newUsername) async {
    if (!isAuthenticated) {
      throw const exceptions.UnauthenticatedException();
    }

    return await _profileRepository.updateCurrentProfile(username: newUsername);
  }

  /// Checks if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    return await _profileRepository.isUsernameAvailable(username);
  }

  /// Gets user profile by ID
  Future<ProfileModel?> getProfile(String userId) async {
    return await _profileRepository.getProfile(userId);
  }

  /// Gets user profile by username
  Future<ProfileModel?> getProfileByUsername(String username) async {
    return await _profileRepository.getProfileByUsername(username);
  }

  /// Searches for users by username
  Future<List<ProfileModel>> searchUsers(
    String searchTerm, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await _profileRepository.searchProfiles(
      searchTerm,
      limit: limit,
      offset: offset,
    );
  }

  /// Deletes the current user's account
  Future<void> deleteAccount() async {
    if (!isAuthenticated) {
      throw const exceptions.UnauthenticatedException();
    }

    try {
      // Delete profile first (this will cascade delete all user data due to foreign keys)
      await _profileRepository.deleteCurrentProfile();

      // Note: In a real app, you'd need admin privileges to delete auth users
      // For now, we'll just delete the profile
    } catch (e) {
      throw exceptions.AuthException(
        'Account deletion failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Sets up auth state change listener
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Gets current session
  Session? get currentSession => _client.auth.currentSession;

  /// Refreshes the current session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();

      if (response.session == null) {
        throw exceptions.AuthException('Session refresh failed');
      }

      return response;
    } catch (e) {
      if (e is exceptions.AuthException) rethrow;
      throw exceptions.AuthException(
        'Session refresh failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Signs in with OAuth provider
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      final response = await _client.auth.signInWithOAuth(provider);
      return response;
    } catch (e) {
      throw exceptions.AuthException(
        'OAuth sign in failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Resends email confirmation
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      throw exceptions.AuthException(
        'Email confirmation resend failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Verifies OTP for email confirmation or password reset
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );

      if (response.user == null) {
        throw exceptions.AuthException('OTP verification failed');
      }

      return response;
    } catch (e) {
      if (e is exceptions.AuthException) rethrow;
      throw exceptions.AuthException(
        'OTP verification failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Gets profile statistics for the current user
  Future<Map<String, int>> getProfileStats() async {
    if (!isAuthenticated) {
      throw const exceptions.UnauthenticatedException();
    }

    return await _profileRepository.getProfileStats();
  }
}
