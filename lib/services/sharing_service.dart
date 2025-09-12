import 'package:uuid/uuid.dart';
import 'supabase_client.dart';
import 'models/profile_model.dart';
import 'models/share_request_model.dart';
import 'models/contact_share_model.dart';
import 'models/contact_model.dart';

/// Contact sharing service for username-based sharing and permission management
class SharingService {
  static const _uuid = Uuid();

  /// Find user by username for sharing
  /// TODO: Implement user search by username
  static Future<ProfileModel?> findUserByUsername(String username) async {
    try {
      // TODO: Search for user by username (case insensitive)
      final response = await SupabaseClientService.client
          .from('profiles')
          .select()
          .eq('username', username.toLowerCase())
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

  /// Send share request to another user
  /// TODO: Implement share request creation
  static Future<ShareRequestModel> sendShareRequest({
    required String requesterId,
    required String recipientId,
    String? message,
  }) async {
    try {
      // TODO: Check if request already exists
      final existingRequest = await _getExistingRequest(
        requesterId,
        recipientId,
      );
      if (existingRequest != null) {
        if (existingRequest.isPending) {
          throw Exception('Share request already pending');
        } else if (existingRequest.isBlocked) {
          throw Exception('You are blocked by this user');
        }
      }

      final requestId = _uuid.v4();
      final now = DateTime.now();

      final request = ShareRequestModel(
        id: requestId,
        requesterId: requesterId,
        recipientId: recipientId,
        message: message,
        status: 'pending',
        createdAt: now,
      );

      // TODO: Insert share request
      final response = await SupabaseClientService.client
          .from('share_requests')
          .insert(request.toInsertJson())
          .select()
          .single();

      return ShareRequestModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get incoming share requests for a user
  /// TODO: Implement incoming request retrieval
  static Future<List<ShareRequestModel>> getIncomingRequests({
    required String userId,
    String? status,
  }) async {
    try {
      var query = SupabaseClientService.client
          .from('share_requests')
          .select()
          .eq('recipient_id', userId);

      // TODO: Filter by status if specified
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map((json) => ShareRequestModel.fromJson(json)).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get outgoing share requests sent by a user
  /// TODO: Implement outgoing request retrieval
  static Future<List<ShareRequestModel>> getOutgoingRequests({
    required String userId,
    String? status,
  }) async {
    try {
      var query = SupabaseClientService.client
          .from('share_requests')
          .select()
          .eq('requester_id', userId);

      // TODO: Filter by status if specified
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map((json) => ShareRequestModel.fromJson(json)).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Respond to share request (accept/decline/block)
  /// TODO: Implement request response
  static Future<ShareRequestModel> respondToShareRequest({
    required String requestId,
    required String status, // 'accepted', 'declined', 'blocked'
  }) async {
    try {
      // TODO: Validate status
      if (!ShareRequestModel.validStatuses.contains(status)) {
        throw Exception('Invalid status: $status');
      }

      // TODO: Update request status
      final response = await SupabaseClientService.client
          .from('share_requests')
          .update({
            'status': status,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return ShareRequestModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Grant access to a specific contact with field permissions
  /// TODO: Implement contact sharing with field mask
  static Future<ContactShareModel> grantContactAccess({
    required String ownerId,
    required String toUserId,
    required String contactId,
    required List<String> fieldMask,
  }) async {
    try {
      // TODO: Validate field mask
      final invalidFields = fieldMask
          .where((field) => !ContactShareModel.supportedFields.contains(field))
          .toList();

      if (invalidFields.isNotEmpty) {
        throw Exception('Invalid fields: ${invalidFields.join(', ')}');
      }

      // TODO: Check if share already exists
      final existingShare = await _getExistingShare(
        ownerId,
        toUserId,
        contactId,
      );
      if (existingShare != null && existingShare.isActive) {
        // Update existing share
        return await updateContactShare(
          shareId: existingShare.id,
          fieldMask: fieldMask,
        );
      }

      final shareId = _uuid.v4();
      final now = DateTime.now();

      final share = ContactShareModel(
        id: shareId,
        ownerId: ownerId,
        toUserId: toUserId,
        contactId: contactId,
        fieldMask: fieldMask,
        createdAt: now,
      );

      // TODO: Insert contact share
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .insert(share.toInsertJson())
          .select()
          .single();

      return ContactShareModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Update existing contact share permissions
  /// TODO: Implement share permission updates
  static Future<ContactShareModel> updateContactShare({
    required String shareId,
    required List<String> fieldMask,
  }) async {
    try {
      // TODO: Validate field mask
      final invalidFields = fieldMask
          .where((field) => !ContactShareModel.supportedFields.contains(field))
          .toList();

      if (invalidFields.isNotEmpty) {
        throw Exception('Invalid fields: ${invalidFields.join(', ')}');
      }

      // TODO: Update share permissions
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .update({'field_mask': fieldMask})
          .eq('id', shareId)
          .select()
          .single();

      return ContactShareModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Revoke access to a shared contact
  /// TODO: Implement access revocation
  static Future<ContactShareModel> revokeContactAccess(String shareId) async {
    try {
      // TODO: Set revoked_at timestamp
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .update({'revoked_at': DateTime.now().toIso8601String()})
          .eq('id', shareId)
          .select()
          .single();

      return ContactShareModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get contacts shared with a user (incoming shares)
  /// TODO: Implement shared contact retrieval
  static Future<List<ContactModel>> getSharedContacts({
    required String userId,
    bool includeRevoked = false,
  }) async {
    try {
      var query = SupabaseClientService.client
          .from('contact_shares')
          .select('*, contacts(*)')
          .eq('to_user_id', userId);

      // TODO: Filter out revoked shares unless specified
      if (!includeRevoked) {
        query = query.isFilter('revoked_at', null);
      }

      final response = await query;

      return response
          .map((row) => ContactModel.fromJson(row['contacts']))
          .toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get contacts that a user is sharing (outgoing shares)
  /// TODO: Implement outgoing shares retrieval
  static Future<List<ContactShareModel>> getContactShares({
    required String ownerId,
    String? contactId,
    bool includeRevoked = false,
  }) async {
    try {
      var query = SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('owner_id', ownerId);

      // TODO: Filter by specific contact if specified
      if (contactId != null) {
        query = query.eq('contact_id', contactId);
      }

      // TODO: Filter out revoked shares unless specified
      if (!includeRevoked) {
        query = query.isFilter('revoked_at', null);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map((json) => ContactShareModel.fromJson(json)).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get specific contact share by ID
  /// TODO: Implement single share retrieval
  static Future<ContactShareModel?> getContactShareById(String shareId) async {
    try {
      // TODO: Query single contact share
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('id', shareId)
          .maybeSingle();

      if (response != null) {
        return ContactShareModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Check if user has access to specific contact
  /// TODO: Implement access verification
  static Future<ContactShareModel?> checkContactAccess({
    required String userId,
    required String contactId,
  }) async {
    try {
      // TODO: Check for active share
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('to_user_id', userId)
          .eq('contact_id', contactId)
          .isFilter('revoked_at', null)
          .maybeSingle();

      if (response != null) {
        return ContactShareModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Get filtered contact data based on field permissions
  /// TODO: Implement field-level filtering
  static Map<String, dynamic> filterContactData({
    required ContactModel contact,
    required List<String> allowedFields,
  }) {
    // TODO: Filter contact data based on field mask
    final filtered = <String, dynamic>{};

    if (allowedFields.contains('full_name')) {
      filtered['full_name'] = contact.fullName;
    }
    if (allowedFields.contains('given_name')) {
      filtered['given_name'] = contact.givenName;
    }
    if (allowedFields.contains('family_name')) {
      filtered['family_name'] = contact.familyName;
    }
    if (allowedFields.contains('middle_name')) {
      filtered['middle_name'] = contact.middleName;
    }
    if (allowedFields.contains('prefix')) {
      filtered['prefix'] = contact.prefix;
    }
    if (allowedFields.contains('suffix')) {
      filtered['suffix'] = contact.suffix;
    }
    if (allowedFields.contains('primary_mobile')) {
      filtered['primary_mobile'] = contact.primaryMobile;
    }
    if (allowedFields.contains('primary_email')) {
      filtered['primary_email'] = contact.primaryEmail;
    }
    if (allowedFields.contains('avatar_url')) {
      filtered['avatar_url'] = contact.avatarUrl;
    }
    if (allowedFields.contains('notes')) {
      filtered['notes'] = contact.notes;
    }
    if (allowedFields.contains('custom_fields')) {
      filtered['custom_fields'] = contact.customFields;
    }
    if (allowedFields.contains('default_call_app')) {
      filtered['default_call_app'] = contact.defaultCallApp;
    }
    if (allowedFields.contains('default_msg_app')) {
      filtered['default_msg_app'] = contact.defaultMsgApp;
    }

    // Always include basic metadata
    filtered['id'] = contact.id;
    filtered['created_at'] = contact.createdAt.toIso8601String();
    filtered['updated_at'] = contact.updatedAt.toIso8601String();

    return filtered;
  }

  /// Bulk grant access to multiple contacts
  /// TODO: Implement bulk sharing
  static Future<List<ContactShareModel>> bulkGrantContactAccess({
    required String ownerId,
    required String toUserId,
    required List<String> contactIds,
    required List<String> fieldMask,
  }) async {
    try {
      final now = DateTime.now();
      final shares = contactIds
          .map(
            (contactId) => {
              'id': _uuid.v4(),
              'owner_id': ownerId,
              'to_user_id': toUserId,
              'contact_id': contactId,
              'field_mask': fieldMask,
              'created_at': now.toIso8601String(),
            },
          )
          .toList();

      // TODO: Insert all shares at once
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .insert(shares)
          .select();

      return response.map((json) => ContactShareModel.fromJson(json)).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get existing request between two users
  /// TODO: Implement request lookup
  static Future<ShareRequestModel?> _getExistingRequest(
    String requesterId,
    String recipientId,
  ) async {
    try {
      final response = await SupabaseClientService.client
          .from('share_requests')
          .select()
          .eq('requester_id', requesterId)
          .eq('recipient_id', recipientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return ShareRequestModel.fromJson(response);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get existing share between users for specific contact
  /// TODO: Implement share lookup
  static Future<ContactShareModel?> _getExistingShare(
    String ownerId,
    String toUserId,
    String contactId,
  ) async {
    try {
      final response = await SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('owner_id', ownerId)
          .eq('to_user_id', toUserId)
          .eq('contact_id', contactId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return ContactShareModel.fromJson(response);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to share request changes for real-time updates
  /// TODO: Implement real-time subscriptions
  static Stream<List<ShareRequestModel>> subscribeToIncomingRequests(
    String userId,
  ) {
    // TODO: Set up real-time subscription for incoming requests
    return SupabaseClientService.client
        .from('share_requests')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .map(
          (data) =>
              data.map((json) => ShareRequestModel.fromJson(json)).toList(),
        );
  }

  /// Subscribe to contact share changes for real-time updates
  /// TODO: Implement real-time subscriptions
  static Stream<List<ContactShareModel>> subscribeToContactShares(
    String ownerId,
  ) {
    // TODO: Set up real-time subscription for contact shares
    return SupabaseClientService.client
        .from('contact_shares')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map(
          (data) =>
              data.map((json) => ContactShareModel.fromJson(json)).toList(),
        );
  }
}
