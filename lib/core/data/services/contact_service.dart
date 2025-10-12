import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../exceptions/exceptions.dart';

/// Service for contact management operations
class ContactService {
  final ContactRepository _contactRepository;
  final TagRepository _tagRepository;

  ContactService(SupabaseClient client)
    : _contactRepository = ContactRepository(client),
      _tagRepository = TagRepository(client);

  /// Gets all contacts with optional filtering and pagination
  Future<List<ContactModel>> getContacts({
    bool includeDeleted = false,
    String? searchTerm,
    List<String>? tagIds,
    int? limit,
    int? offset,
    ContactSortOrder sortOrder = ContactSortOrder.updatedDesc,
  }) async {
    return await _contactRepository.getContacts(
      includeDeleted: includeDeleted,
      searchTerm: searchTerm,
      tagIds: tagIds,
      limit: limit,
      offset: offset,
      orderBy: sortOrder.field,
      ascending: sortOrder.ascending,
    );
  }




  /// Gets only soft-deleted contacts (Trash)
  Future<List<ContactModel>> getDeletedContacts({
    String? searchTerm,
    int? limit,
    int? offset,
    ContactSortOrder sortOrder = ContactSortOrder.updatedDesc,
  }) async {
    // Reuse repository helper you added earlier
    return await _contactRepository.getDeletedContacts(
      searchTerm: searchTerm,
      limit: limit,
      offset: offset,
      orderBy: sortOrder.field,
      ascending: sortOrder.ascending,
    );
  }



  
  /// Gets a specific contact by ID
  Future<ContactModel?> getContact(String contactId) async {
    return await _contactRepository.getContact(contactId);
  }

  /// Gets a contact with its associated tags
  Future<ContactWithTags?> getContactWithTags(String contactId) async {
    final contact = await getContact(contactId);
    if (contact == null) return null;

    final tags = await _tagRepository.getTagsForContact(contactId);
    return ContactWithTags(contact: contact, tags: tags);
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
    List<String>? tagIds,
  }) async {
    final contact = await _contactRepository.createContact(
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
      customFields: customFields,
      defaultCallApp: defaultCallApp,
      defaultMsgApp: defaultMsgApp,
    );

    // Add tags if provided
    if (tagIds?.isNotEmpty == true) {
      await _tagRepository.setTagsForContact(contact.id, tagIds!);
    }

    return contact;
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
    List<String>? tagIds,
  }) async {
    final contact = await _contactRepository.updateContact(
      contactId,
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
      customFields: customFields,
      defaultCallApp: defaultCallApp,
      defaultMsgApp: defaultMsgApp,
    );

    // Update tags if provided
    if (tagIds != null) {
      await _tagRepository.setTagsForContact(contactId, tagIds);
    }

    return contact;
  }

  /// Soft deletes a contact
  Future<void> deleteContact(String contactId) async {
    await _contactRepository.deleteContact(contactId);
  }

  
  /// Permanently deletes a contact
  Future<void> permanentlyDeleteContact(String contactId) async {
    await _contactRepository.permanentlyDeleteContact(contactId);
  }

  /// Restores a soft-deleted contact
  Future<ContactModel> restoreContact(String contactId) async {
    return await _contactRepository.restoreContact(contactId);
  }

  /// Gets recently updated contacts
  Future<List<ContactModel>> getRecentlyUpdatedContacts({
    int limit = 10,
    int? daysBack,
  }) async {
    return await _contactRepository.getRecentlyUpdatedContacts(
      limit: limit,
      daysBack: daysBack,
    );
  }

  /// Gets contacts with no tags
  Future<List<ContactModel>> getUntaggedContacts({
    int? limit,
    int? offset,
  }) async {
    return await _contactRepository.getUntaggedContacts(
      limit: limit,
      offset: offset,
    );
  }

  /// Gets contact counts by various filters
  Future<ContactCounts> getContactCounts() async {
    final counts = await _contactRepository.getContactCounts();
    return ContactCounts(
      active: counts['active'] ?? 0,
      deleted: counts['deleted'] ?? 0,
      total: counts['total'] ?? 0,
    );
  }

  /// Searches contacts across multiple fields
  Future<List<ContactModel>> searchContacts(
    String searchTerm, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (searchTerm.trim().isEmpty) return [];

    return await getContacts(
      searchTerm: searchTerm.trim(),
      limit: limit,
      offset: offset,
      sortOrder: ContactSortOrder.relevance,
    );
  }

  /// Gets contacts by tag
  Future<List<ContactModel>> getContactsByTag(
    String tagId, {
    int? limit,
    int? offset,
  }) async {
    return await getContacts(tagIds: [tagId], limit: limit, offset: offset);
  }

  /// Gets contacts by multiple tags (intersection)
  Future<List<ContactModel>> getContactsByTags(
    List<String> tagIds, {
    int? limit,
    int? offset,
  }) async {
    if (tagIds.isEmpty) return [];

    return await getContacts(tagIds: tagIds, limit: limit, offset: offset);
  }

  /// Duplicates a contact
  Future<ContactModel> duplicateContact(String contactId) async {
    final original = await getContact(contactId);
    if (original == null) {
      throw ExceptionFactory.contactNotFound(contactId);
    }

    // Create a copy with modified name to indicate it's a duplicate
    final duplicateName = original.fullName != null
        ? '${original.fullName} (Copy)'
        : null;

    final duplicate = await createContact(
      fullName: duplicateName,
      givenName: original.givenName,
      familyName: original.familyName,
      middleName: original.middleName,
      prefix: original.prefix,
      suffix: original.suffix,
      primaryMobile: original.primaryMobile,
      primaryEmail: original.primaryEmail,
      avatarUrl: original.avatarUrl,
      notes: original.notes,
      customFields: Map<String, dynamic>.from(original.customFields),
      defaultCallApp: original.defaultCallApp,
      defaultMsgApp: original.defaultMsgApp,
    );

    // Copy tags
    final originalTags = await _tagRepository.getTagsForContact(contactId);
    if (originalTags.isNotEmpty) {
      await _tagRepository.setTagsForContact(
        duplicate.id,
        originalTags.map((tag) => tag.id).toList(),
      );
    }

    return duplicate;
  }

  /// Merges two contacts (moves all data from source to target, then deletes source)
  Future<ContactModel> mergeContacts(
    String targetContactId,
    String sourceContactId,
  ) async {
    if (targetContactId == sourceContactId) {
      throw ValidationException('Cannot merge a contact with itself');
    }

    final target = await getContact(targetContactId);
    final source = await getContact(sourceContactId);

    if (target == null) {
      throw ExceptionFactory.contactNotFound(targetContactId);
    }
    if (source == null) {
      throw ExceptionFactory.contactNotFound(sourceContactId);
    }

    // Merge data - prefer non-empty values from source
    final mergedContact = await updateContact(
      targetContactId,
      fullName: source.fullName ?? target.fullName,
      givenName: source.givenName ?? target.givenName,
      familyName: source.familyName ?? target.familyName,
      middleName: source.middleName ?? target.middleName,
      prefix: source.prefix ?? target.prefix,
      suffix: source.suffix ?? target.suffix,
      primaryMobile: source.primaryMobile ?? target.primaryMobile,
      primaryEmail: source.primaryEmail ?? target.primaryEmail,
      avatarUrl: source.avatarUrl ?? target.avatarUrl,
      notes: _mergeNotes(target.notes, source.notes),
      customFields: _mergeCustomFields(
        target.customFields,
        source.customFields,
      ),
      defaultCallApp: source.defaultCallApp ?? target.defaultCallApp,
      defaultMsgApp: source.defaultMsgApp ?? target.defaultMsgApp,
    );

    // Merge tags
    final targetTags = await _tagRepository.getTagsForContact(targetContactId);
    final sourceTags = await _tagRepository.getTagsForContact(sourceContactId);

    final allTagIds = <String>{
      ...targetTags.map((tag) => tag.id),
      ...sourceTags.map((tag) => tag.id),
    }.toList();

    await _tagRepository.setTagsForContact(targetContactId, allTagIds);

    // Delete source contact
    await permanentlyDeleteContact(sourceContactId);

    return mergedContact;
  }

  /// Merges notes from two contacts
  String? _mergeNotes(String? targetNotes, String? sourceNotes) {
    if (targetNotes?.isNotEmpty == true && sourceNotes?.isNotEmpty == true) {
      return '$targetNotes\n\n--- Merged from another contact ---\n$sourceNotes';
    }
    return sourceNotes ?? targetNotes;
  }

  /// Merges custom fields from two contacts
  Map<String, dynamic> _mergeCustomFields(
    Map<String, dynamic> targetFields,
    Map<String, dynamic> sourceFields,
  ) {
    final merged = Map<String, dynamic>.from(targetFields);

    for (final entry in sourceFields.entries) {
      if (!merged.containsKey(entry.key) || merged[entry.key] == null) {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }
}

/// Enum for contact sorting options
enum ContactSortOrder {
  nameAsc('full_name', true),
  nameDesc('full_name', false),
  updatedAsc('updated_at', true),
  updatedDesc('updated_at', false),
  createdAsc('created_at', true),
  createdDesc('created_at', false),
  relevance('updated_at', false); // For search results

  const ContactSortOrder(this.field, this.ascending);

  final String field;
  final bool ascending;
}

/// Helper class for contact with tags
class ContactWithTags {
  final ContactModel contact;
  final List<TagModel> tags;

  const ContactWithTags({required this.contact, required this.tags});
}

/// Helper class for contact counts
class ContactCounts {
  final int active;
  final int deleted;
  final int total;

  const ContactCounts({
    required this.active,
    required this.deleted,
    required this.total,
  });

  int get visible => active;
}
