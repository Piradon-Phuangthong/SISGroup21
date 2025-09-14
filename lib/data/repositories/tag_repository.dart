import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../exceptions/exceptions.dart';
import '../utils/utils.dart';
import 'base_repository.dart';

/// Repository for tag-related database operations
class TagRepository extends BaseRepository {
  TagRepository(SupabaseClient client) : super(client);

  /// Gets all tags for the current user
  Future<List<TagModel>> getTags({
    String? searchTerm,
    int? limit,
    int? offset,
    String orderBy = 'name',
    bool ascending = true,
  }) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      dynamic query = client.from('tags').select().eq('owner_id', userId);

      if (searchTerm?.isNotEmpty == true) {
        final cleanTerm = searchTerm!.replaceAll("'", "''");
        query = query.ilike('name', '%$cleanTerm%');
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
      return response.map((data) => TagModel.fromJson(data)).toList();
    });
  }

  /// Gets a specific tag by ID
  Future<TagModel?> getTag(String tagId) async {
    final data = await executeSingleQuery(
      'tags',
      idField: 'id',
      idValue: tagId,
    );

    if (data == null) return null;

    final tag = TagModel.fromJson(data);
    validateOwnership(tag.ownerId);

    return tag;
  }

  /// Gets a tag by name for the current user
  Future<TagModel?> getTagByName(String tagName) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('tags')
          .select()
          .eq('owner_id', userId)
          .eq('name', tagName.trim())
          .maybeSingle();

      return response != null ? TagModel.fromJson(response) : null;
    });
  }

  /// Creates a new tag
  Future<TagModel> createTag(String tagName) async {
    final userId = authenticatedUserId;
    final cleanName = tagName.trim();

    ValidationUtils.validateTag(cleanName);

    // Check if tag already exists
    final existingTag = await getTagByName(cleanName);
    if (existingTag != null) {
      throw ExceptionFactory.tagAlreadyExists(cleanName);
    }

    final tagData = {'owner_id': userId, 'name': cleanName};

    final data = await executeInsertQuery('tags', tagData);
    return TagModel.fromJson(data);
  }

  /// Updates an existing tag
  Future<TagModel> updateTag(String tagId, String newName) async {
    final cleanName = newName.trim();
    ValidationUtils.validateTag(cleanName);

    // Verify ownership
    final existingTag = await getTag(tagId);
    if (existingTag == null) {
      throw ExceptionFactory.tagNotFound(tagId);
    }

    // Check if new name conflicts with existing tag
    if (existingTag.name != cleanName) {
      final conflictingTag = await getTagByName(cleanName);
      if (conflictingTag != null) {
        throw ExceptionFactory.tagAlreadyExists(cleanName);
      }
    }

    final updateData = {'name': cleanName};

    final data = await executeUpdateQuery(
      'tags',
      updateData,
      idField: 'id',
      idValue: tagId,
    );

    return TagModel.fromJson(data);
  }

  /// Deletes a tag and removes all associations
  Future<void> deleteTag(String tagId) async {
    // Verify ownership
    final tag = await getTag(tagId);
    if (tag == null) {
      throw ExceptionFactory.tagNotFound(tagId);
    }

    await executeDeleteQuery('tags', idField: 'id', idValue: tagId);
  }

  /// Gets tags for a specific contact
  Future<List<TagModel>> getTagsForContact(String contactId) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contact_tags')
          .select('tags(*)')
          .eq('contact_id', contactId);

      return response
          .map((data) => TagModel.fromJson(data['tags']))
          .where((tag) => tag.ownerId == userId) // Additional security check
          .toList();
    });
  }

  /// Gets contacts for a specific tag
  Future<List<String>> getContactIdsForTag(String tagId) async {
    // Verify ownership
    final tag = await getTag(tagId);
    if (tag == null) {
      throw ExceptionFactory.tagNotFound(tagId);
    }

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contact_tags')
          .select('contact_id')
          .eq('tag_id', tagId);

      return response.map((data) => data['contact_id'] as String).toList();
    });
  }

  /// Adds a tag to a contact
  Future<void> addTagToContact(String contactId, String tagId) async {
    // Verify tag ownership
    final tag = await getTag(tagId);
    if (tag == null) {
      throw ExceptionFactory.tagNotFound(tagId);
    }

    // Check if association already exists
    final exists = await _contactTagExists(contactId, tagId);
    if (exists) {
      return; // Already exists, no need to add again
    }

    await executeInsertQuery('contact_tags', {
      'contact_id': contactId,
      'tag_id': tagId,
    });
  }

  /// Removes a tag from a contact
  Future<void> removeTagFromContact(String contactId, String tagId) async {
    // Verify tag ownership
    final tag = await getTag(tagId);
    if (tag == null) {
      throw ExceptionFactory.tagNotFound(tagId);
    }

    await handleSupabaseExceptionAsync(() async {
      await client
          .from('contact_tags')
          .delete()
          .eq('contact_id', contactId)
          .eq('tag_id', tagId);
    });
  }

  /// Checks if a contact-tag association exists
  Future<bool> _contactTagExists(String contactId, String tagId) async {
    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contact_tags')
          .select('contact_id')
          .eq('contact_id', contactId)
          .eq('tag_id', tagId)
          .maybeSingle();

      return response != null;
    });
  }

  /// Sets tags for a contact (replaces all existing tags)
  Future<void> setTagsForContact(String contactId, List<String> tagIds) async {
    // Verify all tag ownership
    for (final tagId in tagIds) {
      final tag = await getTag(tagId);
      if (tag == null) {
        throw ExceptionFactory.tagNotFound(tagId);
      }
    }

    await handleSupabaseExceptionAsync(() async {
      // Remove existing associations
      await client.from('contact_tags').delete().eq('contact_id', contactId);

      // Add new associations
      if (tagIds.isNotEmpty) {
        final associations = tagIds
            .map((tagId) => {'contact_id': contactId, 'tag_id': tagId})
            .toList();

        await client.from('contact_tags').insert(associations);
      }
    });
  }

  /// Gets tag usage statistics (simplified)
  Future<List<Map<String, dynamic>>> getTagUsageStats() async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('tags')
          .select('id, name')
          .eq('owner_id', userId);

      return response.map((data) {
        return {
          'id': data['id'],
          'name': data['name'],
          'contactCount': 0, // Simplified for now
        };
      }).toList();
    });
  }

  /// Gets unused tags (simplified)
  Future<List<TagModel>> getUnusedTags() async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('tags')
          .select()
          .eq('owner_id', userId)
          .order('name');

      return response.map((data) => TagModel.fromJson(data)).toList();
    });
  }

  /// Merges two tags
  Future<void> mergeTags(String sourceTagId, String targetTagId) async {
    if (sourceTagId == targetTagId) {
      throw ValidationException('Cannot merge a tag with itself');
    }

    // Verify ownership of both tags
    final sourceTag = await getTag(sourceTagId);
    final targetTag = await getTag(targetTagId);

    if (sourceTag == null) {
      throw ExceptionFactory.tagNotFound(sourceTagId);
    }
    if (targetTag == null) {
      throw ExceptionFactory.tagNotFound(targetTagId);
    }

    await handleSupabaseExceptionAsync(() async {
      // Get contacts associated with source tag
      final sourceContacts = await getContactIdsForTag(sourceTagId);

      // For each contact, ensure it has the target tag
      for (final contactId in sourceContacts) {
        try {
          await addTagToContact(contactId, targetTagId);
        } catch (e) {
          // Ignore if already exists
        }
      }

      // Delete the source tag
      await deleteTag(sourceTagId);
    });
  }

  /// Gets recently used tags (simplified)
  Future<List<TagModel>> getRecentlyUsedTags({int limit = 10}) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('tags')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((data) => TagModel.fromJson(data)).toList();
    });
  }
}
