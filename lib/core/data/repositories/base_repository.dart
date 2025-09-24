import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/exceptions.dart' as exceptions;

/// Base repository class providing common database operations
abstract class BaseRepository {
  final SupabaseClient _client;

  BaseRepository(this._client);

  /// Gets the Supabase client
  SupabaseClient get client => _client;

  /// Gets the current authenticated user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Ensures user is authenticated, throws exception if not
  String get authenticatedUserId {
    final userId = currentUserId;
    if (userId == null) {
      throw const exceptions.UnauthenticatedException();
    }
    return userId;
  }

  /// Handles Supabase exceptions and converts them to domain exceptions
  T handleSupabaseException<T>(Function() operation) {
    try {
      return operation();
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on StorageException catch (e) {
      throw exceptions.FileUploadException(e.message, originalError: e);
    } catch (e) {
      if (e is exceptions.DataException) rethrow;
      throw exceptions.DatabaseException(
        'Unexpected database error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Handles async Supabase operations and converts exceptions
  Future<T> handleSupabaseExceptionAsync<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on StorageException catch (e) {
      throw exceptions.FileUploadException(e.message, originalError: e);
    } catch (e) {
      if (e is exceptions.DataException) rethrow;
      throw exceptions.DatabaseException(
        'Unexpected database error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Maps Postgrest exceptions to domain exceptions
  exceptions.DataException _mapPostgrestException(PostgrestException e) {
    switch (e.code) {
      case '23505': // Unique constraint violation
        return exceptions.ConflictException(
          'Resource',
          message: 'Resource already exists: ${e.message}',
        );
      case '23503': // Foreign key constraint violation
        return exceptions.ValidationException(
          'Invalid reference: ${e.message}',
        );
      case '42501': // Insufficient privilege (RLS)
        return exceptions.ForbiddenException('Access denied: ${e.message}');
      case 'PGRST116': // No rows found
        return exceptions.NotFoundException('Resource', message: e.message);
      default:
        return exceptions.DatabaseException(
          e.message,
          code: e.code,
          originalError: e,
        );
    }
  }

  /// Validates that a resource belongs to the current user
  void validateOwnership(String resourceOwnerId) {
    if (resourceOwnerId != authenticatedUserId) {
      throw exceptions.ForbiddenException(
        'You do not have permission to access this resource',
      );
    }
  }

  /// Executes a query and returns a single result
  Future<Map<String, dynamic>?> executeSingleQuery(
    String table, {
    String? select,
    required String idField,
    required String idValue,
  }) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await _client
          .from(table)
          .select(select ?? '*')
          .eq(idField, idValue)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    });
  }

  /// Builds a standard insert query with error handling
  Future<Map<String, dynamic>> executeInsertQuery(
    String table,
    Map<String, dynamic> data, {
    String? select,
  }) async {
    return await handleSupabaseExceptionAsync(() async {
      dynamic query = _client.from(table).insert(data);

      if (select != null) {
        query = query.select(select);
      } else {
        query = query.select();
      }

      final response = await query.single();
      return Map<String, dynamic>.from(response);
    });
  }

  /// Builds a standard update query with error handling
  Future<Map<String, dynamic>> executeUpdateQuery(
    String table,
    Map<String, dynamic> data, {
    required String idField,
    required String idValue,
    String? select,
  }) async {
    return await handleSupabaseExceptionAsync(() async {
      dynamic query = _client.from(table).update(data).eq(idField, idValue);

      if (select != null) {
        query = query.select(select);
      } else {
        query = query.select();
      }

      final response = await query.single();
      return Map<String, dynamic>.from(response);
    });
  }

  /// Builds a standard delete query with error handling
  Future<void> executeDeleteQuery(
    String table, {
    required String idField,
    required String idValue,
  }) async {
    return await handleSupabaseExceptionAsync(() async {
      await _client.from(table).delete().eq(idField, idValue);
    });
  }

  /// Checks if a resource exists
  Future<bool> resourceExists(
    String table, {
    required String idField,
    required String idValue,
  }) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await _client
          .from(table)
          .select(idField)
          .eq(idField, idValue)
          .maybeSingle();

      return response != null;
    });
  }
}
