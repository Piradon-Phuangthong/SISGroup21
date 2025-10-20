import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../exceptions/exceptions.dart';
import '../utils/utils.dart';
import 'base_repository.dart';

/// Repository for contact-related database operations
class ContactRepository extends BaseRepository {
  ContactRepository(SupabaseClient client) : super(client);

  /// Gets all contacts for the current user
  Future<List<ContactModel>> getContacts({
    bool includeDeleted = false,
    String? searchTerm,
    List<String>? tagIds,
    int? limit,
    int? offset,
    String orderBy = 'updated_at',
    bool ascending = false,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client.from('contacts').select().eq('owner_id', userId);

      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }

      if (searchTerm?.isNotEmpty == true) {
        final cleanTerm = searchTerm!.replaceAll("'", "''");
        query = query.or(
          'full_name.ilike.%$cleanTerm%,given_name.ilike.%$cleanTerm%,family_name.ilike.%$cleanTerm%,primary_email.ilike.%$cleanTerm%,primary_mobile.ilike.%$cleanTerm%',
        );
      }

      if (tagIds?.isNotEmpty == true) {
        // For tag filtering, we need to join with contact_tags
        final contactIds = await _getContactIdsByTags(tagIds!);
        if (contactIds.isNotEmpty) {
          // Use filter with 'in' operation instead of .in method
          query = query.filter('id', 'in', '(${contactIds.join(',')})');
        } else {
          // No contacts with these tags
          return <ContactModel>[];
        }
      }

      query = query.order(orderBy, ascending: ascending);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ContactModel>(
            (data) => ContactModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Gets contact IDs that have specific tags
  Future<List<String>> _getContactIdsByTags(List<String> tagIds) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contact_tags')
          .select('contact_id, tag_id')
          .filter('tag_id', 'in', '(${tagIds.join(',')})');

      // Build mapping of contact -> set of matched tagIds
      final Map<String, Set<String>> contactIdToMatchedTags = {};
      for (final row in response) {
        final contactId = row['contact_id'] as String;
        final tagId = row['tag_id'] as String;
        final set = contactIdToMatchedTags.putIfAbsent(
          contactId,
          () => <String>{},
        );
        set.add(tagId);
      }

      if (tagIds.length <= 1) {
        return contactIdToMatchedTags.keys.toList();
      }

      // Intersection: only contacts that have all selected tagIds
      final required = tagIds.toSet();
      return contactIdToMatchedTags.entries
          .where((e) => required.difference(e.value).isEmpty)
          .map((e) => e.key)
          .toList();
    });
  }

  /// Gets a specific contact by ID
  Future<ContactModel?> getContact(String contactId) async {
    final data = await executeSingleQuery(
      'contacts',
      idField: 'id',
      idValue: contactId,
    );

    if (data == null) return null;

    final contact = ContactModel.fromJson(data);
    validateOwnership(contact.ownerId);

    return contact;
  }

  /// Gets the user's own contact (profile contact)
  /// This is the contact where owner_id = current user's ID and represents their profile
  Future<ContactModel?> getMyOwnContact() async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contacts')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', false)
          .limit(1);

      if (response.isEmpty) return null;

      return ContactModel.fromJson(response.first);
    });
  }

  /// Gets only soft-deleted contacts (is_deleted = true)
  Future<List<ContactModel>> getDeletedContacts({
    String? searchTerm,
    int? limit,
    int? offset,
    String orderBy = 'updated_at',
    bool ascending = false,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('contacts')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', true); // only deleted

      if (searchTerm?.isNotEmpty == true) {
        final cleanTerm = searchTerm!.replaceAll("'", "''");
        query = query.or(
          'full_name.ilike.%$cleanTerm%,given_name.ilike.%$cleanTerm%,family_name.ilike.%$cleanTerm%,primary_email.ilike.%$cleanTerm%,primary_mobile.ilike.%$cleanTerm%',
        );
      }

      query = query.order(orderBy, ascending: ascending);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ContactModel>(
            (data) => ContactModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Creates a new contact
  Future<ContactModel> createContact({
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
    final userId = authenticatedUserId;

    // Validate contact data
    final validationErrors = ValidationUtils.validateContactData(
      fullName: fullName,
      givenName: givenName,
      familyName: familyName,
      primaryEmail: primaryEmail,
      primaryMobile: primaryMobile,
    );

    if (validationErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid contact data',
        fieldErrors: validationErrors,
      );
    }

    final contactData = {
      'owner_id': userId,
      'full_name': fullName?.trim(),
      'given_name': givenName?.trim(),
      'family_name': familyName?.trim(),
      'middle_name': middleName?.trim(),
      'prefix': prefix?.trim(),
      'suffix': suffix?.trim(),
      'primary_mobile': primaryMobile?.trim(),
      'primary_email': primaryEmail?.trim().isNotEmpty == true
          ? primaryEmail?.trim()
          : null,
      'avatar_url': avatarUrl?.trim(),
      'notes': notes?.trim(),
      'custom_fields': customFields ?? {},
      'default_call_app': defaultCallApp?.trim(),
      'default_msg_app': defaultMsgApp?.trim(),
    };

    final data = await executeInsertQuery('contacts', contactData);
    return ContactModel.fromJson(data);
  }

  /// Updates an existing contact
  Future<ContactModel> updateContact(
    String contactId, {
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
    bool? isDeleted,
  }) async {
    // Verify ownership
    final existingContact = await getContact(contactId);
    if (existingContact == null) {
      throw ExceptionFactory.contactNotFound(contactId);
    }

    // Validate updated data
    final validationErrors = ValidationUtils.validateContactData(
      fullName: fullName ?? existingContact.fullName,
      givenName: givenName ?? existingContact.givenName,
      familyName: familyName ?? existingContact.familyName,
      primaryEmail: primaryEmail ?? existingContact.primaryEmail,
      primaryMobile: primaryMobile ?? existingContact.primaryMobile,
    );

    if (validationErrors.isNotEmpty) {
      throw ValidationException(
        'Invalid contact data',
        fieldErrors: validationErrors,
      );
    }

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName.trim();
    if (givenName != null) updateData['given_name'] = givenName.trim();
    if (familyName != null) updateData['family_name'] = familyName.trim();
    if (middleName != null) updateData['middle_name'] = middleName.trim();
    if (prefix != null) updateData['prefix'] = prefix.trim();
    if (suffix != null) updateData['suffix'] = suffix.trim();
    if (primaryMobile != null)
      updateData['primary_mobile'] = primaryMobile.trim();
    if (primaryEmail != null) {
      updateData['primary_email'] = primaryEmail.trim().isNotEmpty
          ? primaryEmail.trim()
          : null;
    }
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl.trim();
    if (notes != null) updateData['notes'] = notes.trim();
    if (customFields != null) updateData['custom_fields'] = customFields;
    if (defaultCallApp != null)
      updateData['default_call_app'] = defaultCallApp.trim();
    if (defaultMsgApp != null)
      updateData['default_msg_app'] = defaultMsgApp.trim();
    if (isDeleted != null) updateData['is_deleted'] = isDeleted;

    if (updateData.isEmpty) {
      throw ValidationException('No fields to update');
    }

    final data = await executeUpdateQuery(
      'contacts',
      updateData,
      idField: 'id',
      idValue: contactId,
    );

    return ContactModel.fromJson(data);
  }

  /// Soft deletes a contact
  Future<void> deleteContact(String contactId) async {
    await updateContact(contactId, isDeleted: true);
  }

  /// Permanently deletes a contact
  Future<void> permanentlyDeleteContact(String contactId) async {
    // Verify ownership
    final contact = await getContact(contactId);
    if (contact == null) {
      throw ExceptionFactory.contactNotFound(contactId);
    }

    await executeDeleteQuery('contacts', idField: 'id', idValue: contactId);
  }

  /// Restores a soft-deleted contact
  Future<ContactModel> restoreContact(String contactId) async {
    return await updateContact(contactId, isDeleted: false);
  }

  /// Gets recently updated contacts
  Future<List<ContactModel>> getRecentlyUpdatedContacts({
    int limit = 10,
    int? daysBack,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('contacts')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', false);

      if (daysBack != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
        query = query.gte('updated_at', cutoffDate.toIso8601String());
      }

      query = query.order('updated_at', ascending: false).limit(limit);

      final response = await query;
      return response
          .map<ContactModel>(
            (data) => ContactModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Cleans up contacts with empty string emails (sets them to null)
  Future<void> cleanupEmptyEmails() async {
    final userId = authenticatedUserId;

    await handleSupabaseExceptionAsync(() async {
      // Clean up empty string emails
      await client
          .from('contacts')
          .update({'primary_email': null})
          .eq('owner_id', userId)
          .eq('primary_email', '');

      // Also clean up any contacts that might have the user's email incorrectly assigned
      // Get the current user's email from auth
      final user = client.auth.currentUser;
      if (user?.email != null) {
        await client
            .from('contacts')
            .update({'primary_email': null})
            .eq('owner_id', userId)
            .eq('primary_email', user!.email!)
            .neq(
              'full_name',
              user.email!.split('@')[0],
            ) // Don't clean up if contact name matches email prefix
            .neq('given_name', user.email!.split('@')[0]);
      }
    });
  }

  /// Gets contacts with no tags
  Future<List<ContactModel>> getUntaggedContacts({
    int? limit,
    int? offset,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      // Get contact IDs that have tags
      final taggedContactIds = await client
          .from('contact_tags')
          .select('contact_id');

      final taggedIds = taggedContactIds
          .map((data) => data['contact_id'] as String)
          .toSet();

      // Get all contacts and filter out tagged ones
      dynamic query = client
          .from('contacts')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', false);

      if (taggedIds.isNotEmpty) {
        query = query.not('id', 'in', '(${taggedIds.join(',')})');
      }

      query = query.order('updated_at', ascending: false);

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
      }

      final response = await query;
      return response
          .map<ContactModel>(
            (data) => ContactModel.fromJson(data as Map<String, dynamic>),
          )
          .toList();
    });
  }

  /// Gets contact count by various filters (simplified)
  Future<Map<String, int>> getContactCounts() async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      // Simplified implementation without FetchOptions
      final activeContacts = await client
          .from('contacts')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', false);

      final deletedContacts = await client
          .from('contacts')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', true);

      final totalContacts = await client
          .from('contacts')
          .select()
          .eq('owner_id', userId);

      return {
        'active': activeContacts.length,
        'deleted': deletedContacts.length,
        'total': totalContacts.length,
      };
    });
  }

  /// Gets contacts that have been shared with the current user
  /// Returns a list of SharedContactData containing the contact, share permissions, and owner profile
  Future<List<SharedContactData>> getSharedContacts({
    bool includeRevoked = false,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client
          .from('contact_shares')
          .select('''
            *,
            contact:contacts(*),
            owner_profile:profiles!contact_shares_owner_id_fkey(*)
          ''')
          .eq('to_user_id', userId);

      if (!includeRevoked) {
        query = query.is_('revoked_at', null);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      return response
          .map<SharedContactData>((row) {
            final shareData = Map<String, dynamic>.from(row);
            final contactData = shareData['contact'] as Map<String, dynamic>;
            final profileData =
                shareData['owner_profile'] as Map<String, dynamic>;

            // Remove nested objects before parsing share
            shareData.remove('contact');
            shareData.remove('owner_profile');

            return SharedContactData(
              contact: ContactModel.fromJson(contactData),
              share: ContactShareModel.fromJson(shareData),
              ownerProfile: ProfileModel.fromJson(profileData),
            );
          })
          .toList();
    });
  }
}
