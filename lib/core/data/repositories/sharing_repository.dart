import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../exceptions/exceptions.dart';
import '../utils/utils.dart';
import 'base_repository.dart';

/// Repository for sharing-related database operations
class SharingRepository extends BaseRepository {
  SharingRepository(SupabaseClient client) : super(client);

  /// Creates a share request to another user
  Future<ShareRequestModel> createShareRequest({
    required String recipientUsername,
    String? message,
  }) async {
    final userId = authenticatedUserId;

    // Find recipient by username
    final recipientProfile = await _getProfileByUsername(recipientUsername);
    if (recipientProfile == null) {
      throw NotFoundException(
        'User',
        message: 'User with username "$recipientUsername" not found',
      );
    }

    if (recipientProfile.id == userId) {
      throw ValidationException('Cannot send share request to yourself');
    }

    // Check if there's already a pending request
    final existingRequest = await _getExistingShareRequest(
      userId,
      recipientProfile.id,
    );
    if (existingRequest != null &&
        existingRequest.status == ShareRequestStatus.pending) {
      throw ConflictException(
        'ShareRequest',
        message: 'A pending share request already exists',
      );
    }

    final validationErrors = ValidationUtils.validateShareRequest(
      message: message,
    );
    if (validationErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid share request data',
        fieldErrors: validationErrors,
      );
    }

    final requestData = {
      'requester_id': userId,
      'recipient_id': recipientProfile.id,
      'message': message?.trim(),
      'status': ShareRequestStatus.pending.value,
    };

    final data = await executeInsertQuery('share_requests', requestData);
    return ShareRequestModel.fromJson(data);
  }

  /// Gets profile by username
  Future<ProfileModel?> _getProfileByUsername(String username) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('profiles')
          .select()
          .eq('username', username)
          .maybeSingle();

      return response != null ? ProfileModel.fromJson(response) : null;
    });
  }

  /// Gets existing share request between two users
  Future<ShareRequestModel?> _getExistingShareRequest(
    String requesterId,
    String recipientId,
  ) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('share_requests')
          .select()
          .eq('requester_id', requesterId)
          .eq('recipient_id', recipientId)
          .eq('status', ShareRequestStatus.pending.value)
          .maybeSingle();

      return response != null ? ShareRequestModel.fromJson(response) : null;
    });
  }

  /// Gets incoming share requests (requests to me)
  Future<List<ShareRequestModel>> getIncomingShareRequests({
    ShareRequestStatus? status,
    int? limit,
    int? offset,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('share_requests')
          .select()
          .eq('recipient_id', userId);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ShareRequestModel>(
            (data) => ShareRequestModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Gets outgoing share requests (requests from me)
  Future<List<ShareRequestModel>> getOutgoingShareRequests({
    ShareRequestStatus? status,
    int? limit,
    int? offset,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('share_requests')
          .select()
          .eq('requester_id', userId);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ShareRequestModel>(
            (data) => ShareRequestModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Gets a specific share request
  Future<ShareRequestModel?> getShareRequest(String requestId) async {
    final userId = authenticatedUserId;

    final data = await executeSingleQuery(
      'share_requests',
      idField: 'id',
      idValue: requestId,
    );

    if (data == null) return null;

    final request = ShareRequestModel.fromJson(data);

    // User must be either requester or recipient
    if (request.requesterId != userId && request.recipientId != userId) {
      throw ForbiddenException(
        'You do not have permission to access this share request',
      );
    }

    return request;
  }

  /// Responds to a share request (accept/decline)
  Future<ShareRequestModel> respondToShareRequest(
    String requestId,
    ShareRequestStatus response,
  ) async {
    if (response != ShareRequestStatus.accepted &&
        response != ShareRequestStatus.declined) {
      throw ValidationException('Invalid response status');
    }

    final request = await getShareRequest(requestId);
    if (request == null) {
      throw ExceptionFactory.shareRequestNotFound(requestId);
    }

    final userId = authenticatedUserId;
    if (request.recipientId != userId) {
      throw ForbiddenException(
        'Only the recipient can respond to this request',
      );
    }

    if (request.status != ShareRequestStatus.pending) {
      throw ValidationException('Request has already been responded to');
    }

    final updateData = {
      'status': response.value,
      'responded_at': DateTime.now().toIso8601String(),
    };

    final data = await executeUpdateQuery(
      'share_requests',
      updateData,
      idField: 'id',
      idValue: requestId,
    );

    return ShareRequestModel.fromJson(data);
  }

  /// Cancels a share request (by requester)
  Future<ShareRequestModel> cancelShareRequest(String requestId) async {
    final request = await getShareRequest(requestId);
    if (request == null) {
      throw ExceptionFactory.shareRequestNotFound(requestId);
    }

    final userId = authenticatedUserId;
    if (request.requesterId != userId) {
      throw ForbiddenException('Only the requester can cancel this request');
    }

    if (request.status != ShareRequestStatus.pending) {
      throw ValidationException('Only pending requests can be cancelled');
    }

    final updateData = {
      'status': ShareRequestStatus.cancelled.value,
      'responded_at': DateTime.now().toIso8601String(),
    };

    final data = await executeUpdateQuery(
      'share_requests',
      updateData,
      idField: 'id',
      idValue: requestId,
    );

    return ShareRequestModel.fromJson(data);
  }

  /// Creates a contact share after request acceptance
  Future<ContactShareModel> createContactShare({
    required String toUserId,
    required String contactId,
    required List<String> fieldMask,
  }) async {
    final userId = authenticatedUserId;

    if (fieldMask.isEmpty) {
      throw ValidationException('Field mask cannot be empty');
    }

    // Verify valid field names
    // Support both standard fields and channel-specific fields (channel:uuid)
    final invalidFields = fieldMask
        .where(
          (field) =>
              !ContactFields.all.contains(field) &&
              !field.startsWith('channel:'),
        )
        .toList();
    if (invalidFields.isNotEmpty) {
      throw ValidationException(
        'Invalid field names: ${invalidFields.join(', ')}',
      );
    }

    // Check if share already exists
    final existingShare = await _getExistingContactShare(
      userId,
      contactId,
      toUserId,
    );
    if (existingShare != null && existingShare.isActive) {
      throw ConflictException(
        'ContactShare',
        message: 'An active share already exists for this contact',
      );
    }

    final shareData = {
      'owner_id': userId,
      'to_user_id': toUserId,
      'contact_id': contactId,
      'field_mask': fieldMask,
    };

    final data = await executeInsertQuery('contact_shares', shareData);
    return ContactShareModel.fromJson(data);
  }

  /// Gets existing contact share
  Future<ContactShareModel?> _getExistingContactShare(
    String ownerId,
    String contactId,
    String toUserId,
  ) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contact_shares')
          .select()
          .eq('owner_id', ownerId)
          .eq('contact_id', contactId)
          .eq('to_user_id', toUserId)
          .filter('revoked_at', 'is', 'null')
          .maybeSingle();

      return response != null ? ContactShareModel.fromJson(response) : null;
    });
  }

  /// Gets contacts shared by me
  Future<List<ContactShareModel>> getMyShares({
    bool includeRevoked = false,
    int? limit,
    int? offset,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('contact_shares')
          .select()
          .eq('owner_id', userId);

      if (!includeRevoked) {
        query = query.filter('revoked_at', 'is', 'null');
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ContactShareModel>(
            (data) => ContactShareModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Gets contacts shared with me
  Future<List<ContactShareModel>> getSharesWithMe({
    bool includeRevoked = false,
    int? limit,
    int? offset,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('contact_shares')
          .select()
          .eq('to_user_id', userId);

      if (!includeRevoked) {
        query = query.filter('revoked_at', 'is', 'null');
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ContactShareModel>(
            (data) => ContactShareModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

    /// Checks if the current user has any active contact share with the given user
    Future<bool> hasActiveShareWithUser(String toUserId) async {
      final userId = authenticatedUserId;

      return await handleSupabaseExceptionAsync(() async {
        final response = await client
            .from('contact_shares')
            .select('id')
            .eq('owner_id', userId)
            .eq('to_user_id', toUserId)
            .filter('revoked_at', 'is', 'null')
            .maybeSingle();

        return response != null;
      });
    }

  /// Gets a specific contact share
  Future<ContactShareModel?> getContactShare(String shareId) async {
    final userId = authenticatedUserId;

    final data = await executeSingleQuery(
      'contact_shares',
      idField: 'id',
      idValue: shareId,
    );

    if (data == null) return null;

    final share = ContactShareModel.fromJson(data);

    // User must be either owner or recipient
    if (share.ownerId != userId && share.toUserId != userId) {
      throw ForbiddenException(
        'You do not have permission to access this share',
      );
    }

    return share;
  }

  /// Updates a contact share's field mask
  Future<ContactShareModel> updateContactShare(
    String shareId,
    List<String> newFieldMask,
  ) async {
    final share = await getContactShare(shareId);
    if (share == null) {
      throw NotFoundException('ContactShare', resourceId: shareId);
    }

    final userId = authenticatedUserId;
    if (share.ownerId != userId) {
      throw ForbiddenException('Only the owner can update this share');
    }

    if (newFieldMask.isEmpty) {
      throw ValidationException('Field mask cannot be empty');
    }

    // Verify valid field names
    // Support both standard fields and channel-specific fields (channel:uuid)
    final invalidFields = newFieldMask
        .where(
          (field) =>
              !ContactFields.all.contains(field) &&
              !field.startsWith('channel:'),
        )
        .toList();
    if (invalidFields.isNotEmpty) {
      throw ValidationException(
        'Invalid field names: ${invalidFields.join(', ')}',
      );
    }

    final updateData = {'field_mask': newFieldMask};

    final data = await executeUpdateQuery(
      'contact_shares',
      updateData,
      idField: 'id',
      idValue: shareId,
    );

    return ContactShareModel.fromJson(data);
  }

  /// Revokes a contact share
  Future<ContactShareModel> revokeContactShare(String shareId) async {
    final share = await getContactShare(shareId);
    if (share == null) {
      throw NotFoundException('ContactShare', resourceId: shareId);
    }

    final userId = authenticatedUserId;
    if (share.ownerId != userId) {
      throw ForbiddenException('Only the owner can revoke this share');
    }

    if (!share.isActive) {
      throw ValidationException('Share is already revoked');
    }

    final updateData = {'revoked_at': DateTime.now().toIso8601String()};

    final data = await executeUpdateQuery(
      'contact_shares',
      updateData,
      idField: 'id',
      idValue: shareId,
    );

    return ContactShareModel.fromJson(data);
  }

  /// Gets sharing statistics (simplified)
  Future<Map<String, int>> getSharingStats() async {
    return await handleSupabaseExceptionAsync(() async {
      // Simplified version - returning zeros for now
      return {
        'pendingRequestsToMe': 0,
        'pendingRequestsFromMe': 0,
        'activeSharesByMe': 0,
        'activeSharesWithMe': 0,
      };
    });
  }
}
