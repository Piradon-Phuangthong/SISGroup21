import 'package:uuid/uuid.dart';
import 'supabase_client.dart';
import 'models/profile_model.dart';
import 'models/share_request_model.dart';
import 'models/contact_share_model.dart';
import 'models/contact_model.dart';

/// Contact sharing service for username-based sharing and permission management
class SharingService {
  static const _uuid = Uuid();

  /// Find user by username (case-insensitive)
  static Future<ProfileModel?> findUserByUsername(String username) async {
    try {
      final row = await SupabaseClientService.client
          .from('profiles')
          .select()
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();

      return row != null ? ProfileModel.fromJson(row) : null;
    } catch (_) {
      return null;
    }
  }

  /// Send share request to another user
  static Future<ShareRequestModel> sendShareRequest({
    required String requesterId,
    required String recipientId,
    String? message,
  }) async {
    // Check existing
    final existing = await _getExistingRequest(requesterId, recipientId);
    if (existing != null) {
      if (existing.isPending) {
        throw Exception('Share request already pending');
      } else if (existing.isBlocked) {
        throw Exception('You are blocked by this user');
      }
    }

    final now = DateTime.now();
    final req = ShareRequestModel(
      id: _uuid.v4(),
      requesterId: requesterId,
      recipientId: recipientId,
      message: message,
      status: 'pending',
      createdAt: now,
    );

    final inserted = await SupabaseClientService.client
        .from('share_requests')
        .insert(req.toInsertJson())
        .select()
        .single();

    return ShareRequestModel.fromJson(inserted);
  }

  /// Incoming share requests for a user
  static Future<List<ShareRequestModel>> getIncomingRequests({
    required String userId,
    String? status,
  }) async {
    try {
      final table = SupabaseClientService.client.from('share_requests');

      // Build FILTERS first
      var qb = table.select().eq('recipient_id', userId);
      if (status != null) {
        qb = qb.eq('status', status);
      }

      // Then order/limit
      final rows = await qb.order('created_at', ascending: false);

      return (rows as List)
          .map((j) => ShareRequestModel.fromJson(j))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Outgoing share requests sent by a user
  static Future<List<ShareRequestModel>> getOutgoingRequests({
    required String userId,
    String? status,
  }) async {
    try {
      final table = SupabaseClientService.client.from('share_requests');

      // Build FILTERS first
      var qb = table.select().eq('requester_id', userId);
      if (status != null) {
        qb = qb.eq('status', status);
      }

      // Then order/limit
      final rows = await qb.order('created_at', ascending: false);

      return (rows as List)
          .map((j) => ShareRequestModel.fromJson(j))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Respond to a share request
  static Future<ShareRequestModel> respondToShareRequest({
    required String requestId,
    required String status, // 'accepted', 'declined', 'blocked'
  }) async {
    if (!ShareRequestModel.validStatuses.contains(status)) {
      throw Exception('Invalid status: $status');
    }

    final updated = await SupabaseClientService.client
        .from('share_requests')
        .update({
          'status': status,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .select()
        .single();

    return ShareRequestModel.fromJson(updated);
  }

  /// Grant access to a specific contact (with field mask)
  static Future<ContactShareModel> grantContactAccess({
    required String ownerId,
    required String toUserId,
    required String contactId,
    required List<String> fieldMask,
  }) async {
    final invalid = fieldMask
        .where((f) => !ContactShareModel.supportedFields.contains(f))
        .toList();
    if (invalid.isNotEmpty) {
      throw Exception('Invalid fields: ${invalid.join(', ')}');
    }

    // If already active, update
    final existing = await _getExistingShare(ownerId, toUserId, contactId);
    if (existing != null && existing.isActive) {
      return updateContactShare(shareId: existing.id, fieldMask: fieldMask);
    }

    final now = DateTime.now();
    final share = ContactShareModel(
      id: _uuid.v4(),
      ownerId: ownerId,
      toUserId: toUserId,
      contactId: contactId,
      fieldMask: fieldMask,
      createdAt: now,
    );

    final row = await SupabaseClientService.client
        .from('contact_shares')
        .insert(share.toInsertJson())
        .select()
        .single();

    return ContactShareModel.fromJson(row);
  }

  /// Update the field mask of a share
  static Future<ContactShareModel> updateContactShare({
    required String shareId,
    required List<String> fieldMask,
  }) async {
    final invalid = fieldMask
        .where((f) => !ContactShareModel.supportedFields.contains(f))
        .toList();
    if (invalid.isNotEmpty) {
      throw Exception('Invalid fields: ${invalid.join(', ')}');
    }

    final row = await SupabaseClientService.client
        .from('contact_shares')
        .update({'field_mask': fieldMask})
        .eq('id', shareId)
        .select()
        .single();

    return ContactShareModel.fromJson(row);
  }

  /// Revoke access (sets revoked_at)
  static Future<ContactShareModel> revokeContactAccess(String shareId) async {
    final row = await SupabaseClientService.client
        .from('contact_shares')
        .update({'revoked_at': DateTime.now().toIso8601String()})
        .eq('id', shareId)
        .select()
        .single();

    return ContactShareModel.fromJson(row);
  }

  /// Contacts shared with a user (incoming)
  static Future<List<ContactModel>> getSharedContacts({
    required String userId,
    bool includeRevoked = false,
  }) async {
    try {
      final table = SupabaseClientService.client.from('contact_shares');

      var qb = table.select('*, contacts(*)').eq('to_user_id', userId);
      if (!includeRevoked) {
        qb = qb.isFilter('revoked_at', null);
      }

      final rows = await qb;
      return (rows as List)
          .map((r) => ContactModel.fromJson(r['contacts']))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Contacts that a user is sharing (outgoing)
  static Future<List<ContactShareModel>> getContactShares({
    required String ownerId,
    String? contactId,
    bool includeRevoked = false,
  }) async {
    try {
      final table = SupabaseClientService.client.from('contact_shares');

      var qb = table.select().eq('owner_id', ownerId);
      if (contactId != null) {
        qb = qb.eq('contact_id', contactId);
      }
      if (!includeRevoked) {
        qb = qb.isFilter('revoked_at', null);
      }

      final rows = await qb.order('created_at', ascending: false);
      return (rows as List)
          .map((j) => ContactShareModel.fromJson(j))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific contact share
  static Future<ContactShareModel?> getContactShareById(String shareId) async {
    try {
      final row = await SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('id', shareId)
          .maybeSingle();

      return row != null ? ContactShareModel.fromJson(row) : null;
    } catch (_) {
      return null;
    }
  }

  /// Does user have access to a contact?
  static Future<ContactShareModel?> checkContactAccess({
    required String userId,
    required String contactId,
  }) async {
    try {
      final row = await SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('to_user_id', userId)
          .eq('contact_id', contactId)
          .isFilter('revoked_at', null)
          .maybeSingle();

      return row != null ? ContactShareModel.fromJson(row) : null;
    } catch (_) {
      return null;
    }
  }

  /// Field-level filtering helper
  static Map<String, dynamic> filterContactData({
    required ContactModel contact,
    required List<String> allowedFields,
  }) {
    final out = <String, dynamic>{};

    void put(String key, dynamic value) {
      if (allowedFields.contains(key)) out[key] = value;
    }

    put('full_name', contact.fullName);
    put('given_name', contact.givenName);
    put('family_name', contact.familyName);
    put('middle_name', contact.middleName);
    put('prefix', contact.prefix);
    put('suffix', contact.suffix);
    put('primary_mobile', contact.primaryMobile);
    put('primary_email', contact.primaryEmail);
    put('avatar_url', contact.avatarUrl);
    put('notes', contact.notes);
    put('custom_fields', contact.customFields);
    put('default_call_app', contact.defaultCallApp);
    put('default_msg_app', contact.defaultMsgApp);

    // Always include metadata
    out['id'] = contact.id;
    out['created_at'] = contact.createdAt.toIso8601String();
    out['updated_at'] = contact.updatedAt.toIso8601String();

    return out;
  }

  /// Bulk grant access to multiple contacts
  static Future<List<ContactShareModel>> bulkGrantContactAccess({
    required String ownerId,
    required String toUserId,
    required List<String> contactIds,
    required List<String> fieldMask,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final rows = contactIds
        .map((cid) => {
              'id': _uuid.v4(),
              'owner_id': ownerId,
              'to_user_id': toUserId,
              'contact_id': cid,
              'field_mask': fieldMask,
              'created_at': nowIso,
            })
        .toList();

    final inserted = await SupabaseClientService.client
        .from('contact_shares')
        .insert(rows)
        .select();

    return (inserted as List)
        .map((j) => ContactShareModel.fromJson(j))
        .toList();
  }

  // ---------- Private lookups ----------

  static Future<ShareRequestModel?> _getExistingRequest(
    String requesterId,
    String recipientId,
  ) async {
    try {
      final row = await SupabaseClientService.client
          .from('share_requests')
          .select()
          .eq('requester_id', requesterId)
          .eq('recipient_id', recipientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return row != null ? ShareRequestModel.fromJson(row) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<ContactShareModel?> _getExistingShare(
    String ownerId,
    String toUserId,
    String contactId,
  ) async {
    try {
      final row = await SupabaseClientService.client
          .from('contact_shares')
          .select()
          .eq('owner_id', ownerId)
          .eq('to_user_id', toUserId)
          .eq('contact_id', contactId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return row != null ? ContactShareModel.fromJson(row) : null;
    } catch (_) {
      return null;
    }
  }

  /// Realtime (filter client-side for compatibility across SDK builds)
  static Stream<List<ShareRequestModel>> subscribeToIncomingRequests(
    String userId,
  ) {
    return SupabaseClientService.client
        .from('share_requests')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .where((r) => r['recipient_id'] == userId)
            .map(ShareRequestModel.fromJson)
            .toList());
  }

  static Stream<List<ContactShareModel>> subscribeToContactShares(
    String ownerId,
  ) {
    return SupabaseClientService.client
        .from('contact_shares')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .where((r) => r['owner_id'] == ownerId)
            .map(ContactShareModel.fromJson)
            .toList());
  }
}
