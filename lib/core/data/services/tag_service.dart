import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../exceptions/exceptions.dart';

/// Service for tag management operations
class TagService {
  final TagRepository _tagRepository;
  final ContactRepository _contactRepository;

  TagService(SupabaseClient client)
    : _tagRepository = TagRepository(client),
      _contactRepository = ContactRepository(client);

  /// Gets all tags with optional filtering and pagination
  Future<List<TagModel>> getTags({
    String? searchTerm,
    int? limit,
    int? offset,
    TagSortOrder sortOrder = TagSortOrder.nameAsc,
  }) async {
    return await _tagRepository.getTags(
      searchTerm: searchTerm,
      limit: limit,
      offset: offset,
      orderBy: sortOrder.field,
      ascending: sortOrder.ascending,
    );
  }

  /// Gets a specific tag by ID
  Future<TagModel?> getTag(String tagId) async {
    return await _tagRepository.getTag(tagId);
  }

  /// Gets a tag by name
  Future<TagModel?> getTagByName(String tagName) async {
    return await _tagRepository.getTagByName(tagName);
  }

  /// Creates a new tag
  Future<TagModel> createTag(String tagName) async {
    return await _tagRepository.createTag(tagName);
  }

  /// Updates an existing tag
  Future<TagModel> updateTag(String tagId, String newName) async {
    return await _tagRepository.updateTag(tagId, newName);
  }

  /// Deletes a tag and removes all associations
  Future<void> deleteTag(String tagId) async {
    await _tagRepository.deleteTag(tagId);
  }

  /// Gets tags for a specific contact
  Future<List<TagModel>> getTagsForContact(String contactId) async {
    return await _tagRepository.getTagsForContact(contactId);
  }

  /// Gets contacts for a specific tag
  Future<List<ContactModel>> getContactsForTag(String tagId) async {
    final contactIds = await _tagRepository.getContactIdsForTag(tagId);
    if (contactIds.isEmpty) return [];

    // Get contact details
    final contacts = <ContactModel>[];
    for (final contactId in contactIds) {
      final contact = await _contactRepository.getContact(contactId);
      if (contact != null && !contact.isDeleted) {
        contacts.add(contact);
      }
    }

    return contacts;
  }

  /// Adds a tag to a contact
  Future<void> addTagToContact(String contactId, String tagId) async {
    // Verify contact exists and user owns it
    final contact = await _contactRepository.getContact(contactId);
    if (contact == null) {
      throw ExceptionFactory.contactNotFound(contactId);
    }

    await _tagRepository.addTagToContact(contactId, tagId);
  }

  /// Removes a tag from a contact
  Future<void> removeTagFromContact(String contactId, String tagId) async {
    await _tagRepository.removeTagFromContact(contactId, tagId);
  }

  /// Sets tags for a contact (replaces all existing tags)
  Future<void> setTagsForContact(String contactId, List<String> tagIds) async {
    // Verify contact exists and user owns it
    final contact = await _contactRepository.getContact(contactId);
    if (contact == null) {
      throw ExceptionFactory.contactNotFound(contactId);
    }

    await _tagRepository.setTagsForContact(contactId, tagIds);
  }

  /// Adds a tag to a contact by tag name (creates tag if it doesn't exist)
  Future<TagModel> addTagToContactByName(
    String contactId,
    String tagName,
  ) async {
    // Try to get existing tag first
    TagModel? tag = await getTagByName(tagName);

    // Create tag if it doesn't exist
    if (tag == null) {
      tag = await createTag(tagName);
    }

    // Add tag to contact
    await addTagToContact(contactId, tag.id);

    return tag;
  }

  /// Gets tag usage statistics
  Future<List<TagUsageStats>> getTagUsageStats() async {
    final stats = await _tagRepository.getTagUsageStats();
    return stats
        .map(
          (data) => TagUsageStats(
            id: data['id'] as String,
            name: data['name'] as String,
            contactCount: data['contactCount'] as int,
          ),
        )
        .toList();
  }

  /// Gets unused tags (tags with no contacts)
  Future<List<TagModel>> getUnusedTags() async {
    return await _tagRepository.getUnusedTags();
  }

  /// Gets the most recently used tags
  Future<List<TagModel>> getRecentlyUsedTags({int limit = 10}) async {
    return await _tagRepository.getRecentlyUsedTags(limit: limit);
  }

  /// Merges two tags (moves all contacts from source to target, then deletes source)
  Future<void> mergeTags(String targetTagId, String sourceTagId) async {
    await _tagRepository.mergeTags(sourceTagId, targetTagId);
  }

  /// Gets popular tags (most used tags)
  Future<List<TagWithCount>> getPopularTags({int limit = 10}) async {
    final stats = await getTagUsageStats();

    // Sort by contact count descending
    stats.sort((a, b) => b.contactCount.compareTo(a.contactCount));

    return stats
        .take(limit)
        .map(
          (stat) => TagWithCount(
            tag: TagModel(
              id: stat.id,
              ownerId: '', // Will be filled by the repository
              name: stat.name,
              createdAt: DateTime.now(), // Will be filled by the repository
            ),
            contactCount: stat.contactCount,
          ),
        )
        .toList();
  }

  /// Searches tags by name
  Future<List<TagModel>> searchTags(
    String searchTerm, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (searchTerm.trim().isEmpty) return [];

    return await getTags(
      searchTerm: searchTerm.trim(),
      limit: limit,
      offset: offset,
    );
  }

  /// Creates multiple tags at once
  Future<List<TagModel>> createTags(List<String> tagNames) async {
    final tags = <TagModel>[];

    for (final tagName in tagNames) {
      try {
        final tag = await createTag(tagName);
        tags.add(tag);
      } catch (e) {
        if (e is ConflictException) {
          // Tag already exists, get it instead
          final existingTag = await getTagByName(tagName);
          if (existingTag != null) {
            tags.add(existingTag);
          }
        } else {
          rethrow;
        }
      }
    }

    return tags;
  }

  /// Deletes multiple tags at once
  Future<void> deleteTags(List<String> tagIds) async {
    for (final tagId in tagIds) {
      await deleteTag(tagId);
    }
  }

  /// Renames a tag
  Future<TagModel> renameTag(String tagId, String newName) async {
    return await updateTag(tagId, newName);
  }

  /// Gets tag suggestions based on contact name or other fields
  Future<List<String>> getTagSuggestions(ContactModel contact) async {
    final suggestions = <String>[];

    // Suggest based on name
    if (contact.familyName?.isNotEmpty == true) {
      suggestions.add('Family');
    }

    // Suggest based on email domain
    if (contact.primaryEmail?.isNotEmpty == true) {
      final domain = contact.primaryEmail!.split('@').last.toLowerCase();
      if (domain.contains('gmail') ||
          domain.contains('yahoo') ||
          domain.contains('hotmail')) {
        suggestions.add('Personal');
      } else {
        suggestions.add('Work');
      }
    }

    // Common tag suggestions
    suggestions.addAll([
      'Friends',
      'Colleagues',
      'Business',
      'School',
      'University',
    ]);

    return suggestions.take(5).toList();
  }

  /// Bulk tag operations: add a tag to multiple contacts
  Future<void> addTagToMultipleContacts(
    String tagId,
    List<String> contactIds,
  ) async {
    for (final contactId in contactIds) {
      try {
        await addTagToContact(contactId, tagId);
      } catch (e) {
        // Continue with other contacts even if one fails
        continue;
      }
    }
  }

  /// Bulk tag operations: remove a tag from multiple contacts
  Future<void> removeTagFromMultipleContacts(
    String tagId,
    List<String> contactIds,
  ) async {
    for (final contactId in contactIds) {
      try {
        await removeTagFromContact(contactId, tagId);
      } catch (e) {
        // Continue with other contacts even if one fails
        continue;
      }
    }
  }

  /// Gets tag hierarchy suggestions (if implementing hierarchical tags in the future)
  Future<List<String>> getTagHierarchy(String tagName) async {
    // This is a placeholder for future hierarchical tag implementation
    // For now, return empty list
    return [];
  }

  /// Archives unused tags (soft delete for tags that might be needed later)
  Future<void> archiveUnusedTags() async {
    final unusedTags = await getUnusedTags();

    // For now, just delete them. In a future version, you might want to implement
    // a soft delete mechanism for tags as well
    for (final tag in unusedTags) {
      await deleteTag(tag.id);
    }
  }
}

/// Enum for tag sorting options
enum TagSortOrder {
  nameAsc('name', true),
  nameDesc('name', false),
  createdAsc('created_at', true),
  createdDesc('created_at', false),
  usageDesc('usage', false), // Custom sort by usage count
  usageAsc('usage', true); // Custom sort by usage count

  const TagSortOrder(this.field, this.ascending);

  final String field;
  final bool ascending;
}

/// Helper class for tag usage statistics
class TagUsageStats {
  final String id;
  final String name;
  final int contactCount;

  const TagUsageStats({
    required this.id,
    required this.name,
    required this.contactCount,
  });
}

/// Helper class for tag with contact count
class TagWithCount {
  final TagModel tag;
  final int contactCount;

  const TagWithCount({required this.tag, required this.contactCount});
}
