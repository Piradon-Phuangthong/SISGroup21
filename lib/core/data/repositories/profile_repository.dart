import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../exceptions/exceptions.dart';
import '../utils/utils.dart';
import 'base_repository.dart';

/// Repository for profile-related database operations
class ProfileRepository extends BaseRepository {
  ProfileRepository(SupabaseClient client) : super(client);

  /// Gets the current user's profile
  Future<ProfileModel?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    return await getProfile(userId);
  }

  /// Gets a profile by user ID
  Future<ProfileModel?> getProfile(String userId) async {
    final data = await executeSingleQuery(
      'profiles',
      idField: 'id',
      idValue: userId,
    );

    return data != null ? ProfileModel.fromJson(data) : null;
  }

  /// Gets a profile by username
  Future<ProfileModel?> getProfileByUsername(String username) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      return response != null ? ProfileModel.fromJson(response) : null;
    });
  }

  /// Creates a new profile (usually called automatically by trigger)
  Future<ProfileModel> createProfile({
    required String id,
    required String username,
  }) async {
    ValidationUtils.validateUsername(username);

    final data = await executeInsertQuery('profiles', {
      'id': id,
      'username': username,
    });

    return ProfileModel.fromJson(data);
  }

  /// Updates the current user's profile
  Future<ProfileModel> updateCurrentProfile({String? username}) async {
    final userId = authenticatedUserId;

    if (username != null) {
      ValidationUtils.validateUsername(username);
    }

    final updateData = <String, dynamic>{};
    if (username != null) updateData['username'] = username;

    if (updateData.isEmpty) {
      throw ValidationException('No fields to update');
    }

    final data = await executeUpdateQuery(
      'profiles',
      updateData,
      idField: 'id',
      idValue: userId,
    );

    return ProfileModel.fromJson(data);
  }

  /// Checks if a username is available
  Future<bool> isUsernameAvailable(String username) async {
    ValidationUtils.validateUsername(username);

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    });
  }

  /// Searches for profiles by username (for user discovery)
  Future<List<ProfileModel>> searchProfiles(
    String searchTerm, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (searchTerm.trim().isEmpty) return [];

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('profiles')
          .select()
          .ilike('username', '%${searchTerm.trim()}%')
          .limit(limit)
          .range(offset, offset + limit - 1);

      return response
          .map<ProfileModel>(
            (data) => ProfileModel.fromJson(Map<String, dynamic>.from(data)),
          )
          .toList();
    });
  }

  /// Gets multiple profiles by IDs
  Future<List<ProfileModel>> getProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('profiles')
          .select()
          .filter('id', 'in', '(${userIds.join(',')})');

      return response
          .map<ProfileModel>(
            (data) => ProfileModel.fromJson(Map<String, dynamic>.from(data)),
          )
          .toList();
    });
  }

  /// Deletes the current user's profile
  Future<void> deleteCurrentProfile() async {
    final userId = authenticatedUserId;

    await executeDeleteQuery('profiles', idField: 'id', idValue: userId);
  }

  /// Gets profile statistics (simplified version without count)
  Future<Map<String, int>> getProfileStats() async {
    return await handleSupabaseExceptionAsync(() async {
      // For now, return empty stats - counting operations are complex in current Supabase version
      return {
        'contactCount': 0,
        'tagCount': 0,
        'activeShareCount': 0,
        'pendingRequestCount': 0,
      };
    });
  }
}
