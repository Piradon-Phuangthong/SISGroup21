import 'package:uuid/uuid.dart';
import 'supabase_client.dart';
import 'models/tag_model.dart';

/// Tag management service for creating, applying, and filtering by tags
class TagService {
  static const _uuid = Uuid();

  /// Create new tag
  /// TODO: Implement tag creation
  static Future<TagModel> createTag({
    required String ownerId,
    required String name,
  }) async {
    try {
      // TODO: Check if tag name already exists for this user
      final existingTag = await getTagByName(ownerId: ownerId, name: name);
      if (existingTag != null) {
        throw Exception('Tag with name "$name" already exists');
      }

      final tagId = _uuid.v4();
      final now = DateTime.now();

      final tag = TagModel(
        id: tagId,
        ownerId: ownerId,
        name: name.trim(),
        createdAt: now,
      );

      // TODO: Insert tag into database
      final response = await SupabaseClientService.client
          .from('tags')
          .insert(tag.toInsertJson())
          .select()
          .single();

      return TagModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get all tags for a user
  /// TODO: Implement tag retrieval
  static Future<List<TagModel>> getTags({required String ownerId}) async {
    try {
      // TODO: Query user's tags ordered by name
      final response = await SupabaseClientService.client
          .from('tags')
          .select()
          .eq('owner_id', ownerId)
          .order('name', ascending: true);

      return response.map((json) => TagModel.fromJson(json)).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get specific tag by ID
  /// TODO: Implement single tag retrieval
  static Future<TagModel?> getTagById(String tagId) async {
    try {
      // TODO: Query single tag
      final response = await SupabaseClientService.client
          .from('tags')
          .select()
          .eq('id', tagId)
          .maybeSingle();

      if (response != null) {
        return TagModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Get tag by name for a user
  /// TODO: Implement tag lookup by name
  static Future<TagModel?> getTagByName({
    required String ownerId,
    required String name,
  }) async {
    try {
      // TODO: Query tag by name (case insensitive)
      final response = await SupabaseClientService.client
          .from('tags')
          .select()
          .eq('owner_id', ownerId)
          .eq('name', name.trim())
          .maybeSingle();

      if (response != null) {
        return TagModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Update tag name
  /// TODO: Implement tag updates
  static Future<TagModel> updateTag({
    required String tagId,
    required String name,
  }) async {
    try {
      // TODO: Update tag name
      final response = await SupabaseClientService.client
          .from('tags')
          .update({'name': name.trim()})
          .eq('id', tagId)
          .select()
          .single();

      return TagModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Delete tag and remove from all contacts
  /// TODO: Implement tag deletion
  static Future<void> deleteTag(String tagId) async {
    try {
      // TODO: First remove tag from all contacts
      await SupabaseClientService.client
          .from('contact_tags')
          .delete()
          .eq('tag_id', tagId);

      // TODO: Then delete the tag itself
      await SupabaseClientService.client.from('tags').delete().eq('id', tagId);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Apply tag to contact
  /// TODO: Implement tag application
  static Future<ContactTagModel> addTagToContact({
    required String contactId,
    required String tagId,
  }) async {
    try {
      // TODO: Check if tag is already applied to contact
      final existing = await getContactTag(contactId: contactId, tagId: tagId);
      if (existing != null) {
        return existing; // Already exists, return existing relationship
      }

      final now = DateTime.now();

      final contactTag = ContactTagModel(
        contactId: contactId,
        tagId: tagId,
        createdAt: now,
      );

      // TODO: Insert contact-tag relationship
      final response = await SupabaseClientService.client
          .from('contact_tags')
          .insert(contactTag.toInsertJson())
          .select()
          .single();

      return ContactTagModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Remove tag from contact
  /// TODO: Implement tag removal
  static Future<void> removeTagFromContact({
    required String contactId,
    required String tagId,
  }) async {
    try {
      // TODO: Delete contact-tag relationship
      await SupabaseClientService.client
          .from('contact_tags')
          .delete()
          .eq('contact_id', contactId)
          .eq('tag_id', tagId);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get all tags for a specific contact
  /// TODO: Implement contact tag retrieval
  static Future<List<TagModel>> getContactTags(String contactId) async {
    try {
      // TODO: Join contact_tags with tags to get tag details
      final response = await SupabaseClientService.client
          .from('contact_tags')
          .select('tag_id, tags(*)')
          .eq('contact_id', contactId);

      return response.map((row) => TagModel.fromJson(row['tags'])).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get all contacts with a specific tag
  /// TODO: Implement tag-based contact filtering
  static Future<List<String>> getContactsByTag(String tagId) async {
    try {
      // TODO: Get contact IDs that have this tag
      final response = await SupabaseClientService.client
          .from('contact_tags')
          .select('contact_id')
          .eq('tag_id', tagId);

      return response.map((row) => row['contact_id'] as String).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get contacts filtered by multiple tags
  /// TODO: Implement multi-tag filtering
  static Future<List<String>> getContactsByTags({
    required List<String> tagIds,
    bool matchAll = false, // true = AND logic, false = OR logic
  }) async {
    try {
      if (tagIds.isEmpty) return [];

      if (matchAll) {
        // TODO: Implement AND logic - contacts must have ALL tags
        // This requires a more complex query or multiple queries
        final contactCounts = <String, int>{};

        for (final tagId in tagIds) {
          final contacts = await getContactsByTag(tagId);
          for (final contactId in contacts) {
            contactCounts[contactId] = (contactCounts[contactId] ?? 0) + 1;
          }
        }

        // Return contacts that have all tags
        return contactCounts.entries
            .where((entry) => entry.value == tagIds.length)
            .map((entry) => entry.key)
            .toList();
      } else {
        // TODO: Implement OR logic - contacts with ANY of the tags
        final response = await SupabaseClientService.client
            .from('contact_tags')
            .select('contact_id')
            .inFilter('tag_id', tagIds);

        return response
            .map((row) => row['contact_id'] as String)
            .toSet() // Remove duplicates
            .toList();
      }
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get contact-tag relationship
  /// TODO: Implement relationship check
  static Future<ContactTagModel?> getContactTag({
    required String contactId,
    required String tagId,
  }) async {
    try {
      // TODO: Check if relationship exists
      final response = await SupabaseClientService.client
          .from('contact_tags')
          .select()
          .eq('contact_id', contactId)
          .eq('tag_id', tagId)
          .maybeSingle();

      if (response != null) {
        return ContactTagModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Get tag usage statistics
  /// TODO: Implement tag analytics
  static Future<Map<String, int>> getTagUsageStats(String ownerId) async {
    try {
      // TODO: Get count of contacts for each tag
      // Note: This would require a custom RPC function in Supabase
      // For now, we'll implement client-side aggregation
      final tags = await getTags(ownerId: ownerId);
      final stats = <String, int>{};

      for (final tag in tags) {
        final contacts = await getContactsByTag(tag.id);
        stats[tag.name] = contacts.length;
      }

      return stats;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return {};
    }
  }

  /// Search tags by name
  /// TODO: Implement tag search
  static Future<List<TagModel>> searchTags({
    required String ownerId,
    required String query,
  }) async {
    try {
      // TODO: Search tags by name (case insensitive)
      final response = await SupabaseClientService.client
          .from('tags')
          .select()
          .eq('owner_id', ownerId)
          .ilike('name', '%$query%')
          .order('name', ascending: true);

      return response.map((json) => TagModel.fromJson(json)).toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Bulk apply tags to multiple contacts
  /// TODO: Implement bulk tag operations
  static Future<void> bulkAddTagsToContacts({
    required List<String> contactIds,
    required List<String> tagIds,
  }) async {
    try {
      final now = DateTime.now();
      final relationships = <Map<String, dynamic>>[];

      // TODO: Create all contact-tag relationships
      for (final contactId in contactIds) {
        for (final tagId in tagIds) {
          relationships.add({
            'contact_id': contactId,
            'tag_id': tagId,
            'created_at': now.toIso8601String(),
          });
        }
      }

      if (relationships.isNotEmpty) {
        await SupabaseClientService.client
            .from('contact_tags')
            .upsert(relationships);
      }
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Bulk remove tags from multiple contacts
  /// TODO: Implement bulk tag removal
  static Future<void> bulkRemoveTagsFromContacts({
    required List<String> contactIds,
    required List<String> tagIds,
  }) async {
    try {
      // TODO: Remove tag relationships for specified contacts and tags
      await SupabaseClientService.client
          .from('contact_tags')
          .delete()
          .inFilter('contact_id', contactIds)
          .inFilter('tag_id', tagIds);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }
}
