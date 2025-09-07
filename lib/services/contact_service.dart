import 'package:uuid/uuid.dart';
import 'supabase_client.dart';
import 'models/contact_model.dart';

/// Contact management service for CRUD operations
class ContactService {
  static const _uuid = Uuid();

  /// Create new contact
  static Future<ContactModel> createContact({
    required String ownerId,
    String? fullName,
    String? givenName,
    String? familyName,
    String? middleName,
    String? prefix,
    String? suffix,
    String? primaryMobile,
    String? primaryEmail,
    String? avatarUrl,
    String? notes,
    Map<String, dynamic>? customFields,
    String? defaultCallApp,
    String? defaultMsgApp,
  }) async {
    try {
      final now = DateTime.now();

      final contact = ContactModel(
        // Let DB generate UUID if your table has default uuid_generate_v4()
        // If you really need client IDs, uncomment the next line:
        // id: _uuid.v4(),
        id: _uuid.v4(),
        ownerId: ownerId,
        fullName: fullName,
        givenName: givenName,
        familyName: familyName,
        middleName: middleName,
        prefix: prefix,
        suffix: suffix,
        primaryMobile: primaryMobile,
        primaryEmail: primaryEmail,
        avatarUrl: avatarUrl,
        notes: notes,
        customFields: customFields ?? {},
        defaultCallApp: defaultCallApp,
        defaultMsgApp: defaultMsgApp,
        createdAt: now,
        updatedAt: now,
      );

      final response = await SupabaseClientService.client
          .from('contacts')
          .insert(contact.toInsertJson())
          .select()
          .single();

      return ContactModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all contacts for a user, with optional search
  static Future<List<ContactModel>> getContacts({
    required String ownerId,
    bool includeDeleted = false,
    String? searchQuery,
    List<String>? tagIds, // not implemented (join needed)
  }) async {
    try {
      final table = SupabaseClientService.client.from('contacts');

      // Keep it as a filterable builder while we add filters
      var qb = table.select().eq('owner_id', ownerId);

      if (!includeDeleted) {
        qb = qb.eq('is_deleted', false);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.trim();
        qb = qb.or(
          'full_name.ilike.%$q%,'
          'given_name.ilike.%$q%,'
          'family_name.ilike.%$q%,'
          'primary_mobile.ilike.%$q%,'
          'primary_email.ilike.%$q%',
        );
      }

      // Only transform AFTER filters
      final response = await qb
          .order('updated_at', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get specific contact by ID
  static Future<ContactModel?> getContactById(String contactId) async {
    try {
      final response = await SupabaseClientService.client
          .from('contacts')
          .select()
          .eq('id', contactId)
          .maybeSingle();

      return response != null ? ContactModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  /// Update existing contact
  static Future<ContactModel> updateContact({
    required String contactId,
    String? fullName,
    String? givenName,
    String? familyName,
    String? middleName,
    String? prefix,
    String? suffix,
    String? primaryMobile,
    String? primaryEmail,
    String? avatarUrl,
    String? notes,
    Map<String, dynamic>? customFields,
    String? defaultCallApp,
    String? defaultMsgApp,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (givenName != null) updateData['given_name'] = givenName;
      if (familyName != null) updateData['family_name'] = familyName;
      if (middleName != null) updateData['middle_name'] = middleName;
      if (prefix != null) updateData['prefix'] = prefix;
      if (suffix != null) updateData['suffix'] = suffix;
      if (primaryMobile != null) updateData['primary_mobile'] = primaryMobile;
      if (primaryEmail != null) updateData['primary_email'] = primaryEmail;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (notes != null) updateData['notes'] = notes;
      if (customFields != null) updateData['custom_fields'] = customFields;
      if (defaultCallApp != null) updateData['default_call_app'] = defaultCallApp;
      if (defaultMsgApp != null) updateData['default_msg_app'] = defaultMsgApp;

      final response = await SupabaseClientService.client
          .from('contacts')
          .update(updateData)
          .eq('id', contactId)
          .select()
          .single();

      return ContactModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Soft delete contact
  static Future<void> deleteContact(String contactId) async {
    try {
      await SupabaseClientService.client
          .from('contacts')
          .update({
            'is_deleted': false == true, // leave explicit boolean
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contactId);
    } catch (e) {
      rethrow;
    }
  }

  /// Hard delete contact (cascade in DB if configured)
  static Future<void> hardDeleteContact(String contactId) async {
    try {
      await SupabaseClientService.client
          .from('contacts')
          .delete()
          .eq('id', contactId);
    } catch (e) {
      rethrow;
    }
  }

  /// Restore soft-deleted contact
  static Future<ContactModel> restoreContact(String contactId) async {
    try {
      final response = await SupabaseClientService.client
          .from('contacts')
          .update({
            'is_deleted': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contactId)
          .select()
          .single();

      return ContactModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Search contacts across multiple fields (quick search)
  static Future<List<ContactModel>> searchContacts({
    required String ownerId,
    required String query,
    int limit = 50,
  }) async {
    try {
      final q = query.trim();

      var qb = SupabaseClientService.client
          .from('contacts')
          .select()
          .eq('owner_id', ownerId)
          .eq('is_deleted', false)
          .or(
            'full_name.ilike.%$q%,'
            'given_name.ilike.%$q%,'
            'family_name.ilike.%$q%,'
            'primary_mobile.ilike.%$q%,'
            'primary_email.ilike.%$q%',
          );

      final response = await qb.limit(limit);
      return (response as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Count contacts (simple, SDK-agnostic)
  static Future<int> getContactsCount({
    required String ownerId,
    bool includeDeleted = false,
  }) async {
    try {
      var qb = SupabaseClientService.client
          .from('contacts')
          .select('id')
          .eq('owner_id', ownerId);

      if (!includeDeleted) {
        qb = qb.eq('is_deleted', false);
      }

      final list = await qb; // returns List
      return (list as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Realtime: subscribe to user’s contacts (filter in Dart to avoid SDK diffs)
  static Stream<List<ContactModel>> subscribeToContacts(String ownerId) {
    return SupabaseClientService.client
        .from('contacts')
        .stream(primaryKey: ['id'])
        // Some SDK versions don’t expose `.eq` on the stream builder;
        // so we filter client-side for compatibility.
        .map((rows) {
          final filtered = rows.where((r) =>
              r['owner_id'] == ownerId && (r['is_deleted'] == false || r['is_deleted'] == null));
          return filtered.map((json) => ContactModel.fromJson(json)).toList();
        });
  }
}
