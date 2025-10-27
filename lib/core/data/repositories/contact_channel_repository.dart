import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../exceptions/exceptions.dart';
import 'base_repository.dart';

/// Repository for contact channel CRUD
class ContactChannelRepository extends BaseRepository {
  ContactChannelRepository(SupabaseClient client) : super(client);

  /// List channels for a contact
  Future<List<ContactChannelModel>> getChannelsForContact(
    String contactId,
  ) async {
    final userId = authenticatedUserId;

    return await handleSupabaseExceptionAsync(() async {
      final response = await client
          .from('contact_channels')
          .select()
          .eq('contact_id', contactId)
          .eq('owner_id', userId)
          .order('updated_at', ascending: false);

      return response
          .map<ContactChannelModel>(
            (row) =>
                ContactChannelModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    });
  }

  /// Create a channel
  Future<ContactChannelModel> createChannel({
    required String contactId,
    required String kind,
    String? label,
    String? value,
    String? url,
    Map<String, dynamic>? extra,
    bool isPrimary = false,
  }) async {
    final userId = authenticatedUserId;

    final data = await executeInsertQuery('contact_channels', {
      'owner_id': userId,
      'contact_id': contactId,
      'kind': kind,
      'label': label,
      'value': value,
      'url': url,
      'extra': extra,
      'is_primary': isPrimary,
    });

    return ContactChannelModel.fromJson(data);
  }

  /// Update a channel
  Future<ContactChannelModel> updateChannel(
    String channelId, {
    String? label,
    String? value,
    String? url,
    Map<String, dynamic>? extra,
    bool? isPrimary,
  }) async {
    final update = <String, dynamic>{};
    if (label != null) update['label'] = label;
    if (value != null) update['value'] = value;
    if (url != null) update['url'] = url;
    if (extra != null) update['extra'] = extra;
    if (isPrimary != null) update['is_primary'] = isPrimary;

    if (update.isEmpty) {
      throw ValidationException('No fields to update');
    }

    final data = await executeUpdateQuery(
      'contact_channels',
      update,
      idField: 'id',
      idValue: channelId,
    );
    return ContactChannelModel.fromJson(data);
  }

  /// Delete a channel
  Future<void> deleteChannel(String channelId) async {
    await executeDeleteQuery(
      'contact_channels',
      idField: 'id',
      idValue: channelId,
    );
  }

  /// Set the primary flag for a specific kind and unset others of same kind
  Future<void> setPrimaryForKind({
    required String contactId,
    required String kind,
    required String channelId,
  }) async {
    final userId = authenticatedUserId;

    await handleSupabaseExceptionAsync(() async {
      // Unset all existing primaries for this kind
      await client
          .from('contact_channels')
          .update({'is_primary': false})
          .eq('owner_id', userId)
          .eq('contact_id', contactId)
          .eq('kind', kind);

      // Set selected as primary
      await client
          .from('contact_channels')
          .update({'is_primary': true})
          .eq('id', channelId);
    });
  }

  /// Gets channels for a shared contact, filtered by share permissions
  /// Only returns channels that are included in the field_mask of the share
  Future<List<ContactChannelModel>> getSharedChannelsForContact({
    required String contactId,
    required ContactShareModel share,
  }) async {
    return await handleSupabaseExceptionAsync(() async {
      // Get all channels for the contact (owner's perspective)
      final response = await client
          .from('contact_channels')
          .select()
          .eq('contact_id', contactId)
          .eq('owner_id', share.ownerId)
          .order('updated_at', ascending: false);

      final allChannels = response
          .map<ContactChannelModel>(
            (row) =>
                ContactChannelModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();

      // Filter channels based on field_mask
      // Include only channels whose IDs appear in field_mask with "channel:" prefix
      final sharedChannelIds = share.fieldMask
          .where((field) => field.startsWith('channel:'))
          .map((field) => field.substring(8)) // Remove "channel:" prefix
          .toSet();

      // If field_mask contains generic "channels" without prefix, share all channels
      if (share.fieldMask.contains('channels')) {
        return allChannels;
      }

      // Otherwise filter to only shared channels
      return allChannels
          .where((channel) => sharedChannelIds.contains(channel.id))
          .toList();
    });
  }
}
