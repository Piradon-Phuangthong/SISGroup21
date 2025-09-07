import 'package:uuid/uuid.dart';
import 'supabase_client.dart';
import 'models/contact_channel_model.dart';

/// Contact channel management service for phones, emails, socials, payments, etc.
class ContactChannelService {
  static const _uuid = Uuid();

  /// Add new channel to contact
  /// TODO: Implement channel creation
  static Future<ContactChannelModel> addContactChannel({
    required String ownerId,
    required String contactId,
    required String kind,
    String? label,
    String? value,
    String? url,
    Map<String, dynamic>? extra,
    bool isPrimary = false,
  }) async {
    try {
      // TODO: Validate channel kind
      if (!ContactChannelModel.supportedKinds.contains(kind)) {
        throw Exception('Unsupported channel kind: $kind');
      }

      // TODO: If setting as primary, unset other primary channels of same kind
      if (isPrimary) {
        await _unsetPrimaryChannels(contactId, kind);
      }

      final channelId = _uuid.v4();
      final now = DateTime.now();

      final channel = ContactChannelModel(
        id: channelId,
        ownerId: ownerId,
        contactId: contactId,
        kind: kind,
        label: label,
        value: value,
        url: url,
        extra: extra,
        isPrimary: isPrimary,
        updatedAt: now,
      );

      // TODO: Insert channel into database
      final response = await SupabaseClientService.client
          .from('contact_channels')
          .insert(channel.toInsertJson())
          .select()
          .single();

      return ContactChannelModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get all channels for a contact
  /// TODO: Implement channel retrieval
  static Future<List<ContactChannelModel>> getContactChannels({
    required String contactId,
    String? kind,
  }) async {
    try {
      var query = SupabaseClientService.client
          .from('contact_channels')
          .select()
          .eq('contact_id', contactId)
          .order('is_primary', ascending: false)
          .order('updated_at', ascending: false);

      // TODO: Filter by channel kind if specified
      if (kind != null) {
        query = query.eq('kind', kind);
      }

      final response = await query;
      return response
          .map((json) => ContactChannelModel.fromJson(json))
          .toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get specific channel by ID
  /// TODO: Implement single channel retrieval
  static Future<ContactChannelModel?> getChannelById(String channelId) async {
    try {
      // TODO: Query single channel
      final response = await SupabaseClientService.client
          .from('contact_channels')
          .select()
          .eq('id', channelId)
          .maybeSingle();

      if (response != null) {
        return ContactChannelModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Update existing channel
  /// TODO: Implement channel updates
  static Future<ContactChannelModel> updateContactChannel({
    required String channelId,
    String? kind,
    String? label,
    String? value,
    String? url,
    Map<String, dynamic>? extra,
    bool? isPrimary,
  }) async {
    try {
      // TODO: Build update data
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (kind != null) {
        if (!ContactChannelModel.supportedKinds.contains(kind)) {
          throw Exception('Unsupported channel kind: $kind');
        }
        updateData['kind'] = kind;
      }
      if (label != null) updateData['label'] = label;
      if (value != null) updateData['value'] = value;
      if (url != null) updateData['url'] = url;
      if (extra != null) updateData['extra'] = extra;
      if (isPrimary != null) updateData['is_primary'] = isPrimary;

      // TODO: If setting as primary, unset other primary channels of same kind
      if (isPrimary == true) {
        final channel = await getChannelById(channelId);
        if (channel != null) {
          await _unsetPrimaryChannels(channel.contactId, kind ?? channel.kind);
        }
      }

      // TODO: Update channel in database
      final response = await SupabaseClientService.client
          .from('contact_channels')
          .update(updateData)
          .eq('id', channelId)
          .select()
          .single();

      return ContactChannelModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Delete channel
  /// TODO: Implement channel deletion
  static Future<void> deleteContactChannel(String channelId) async {
    try {
      // TODO: Delete channel from database
      await SupabaseClientService.client
          .from('contact_channels')
          .delete()
          .eq('id', channelId);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Set channel as primary for its kind
  /// TODO: Implement primary channel setting
  static Future<ContactChannelModel> setPrimaryChannel({
    required String channelId,
    required String contactId,
    required String kind,
  }) async {
    try {
      // TODO: First unset other primary channels of same kind
      await _unsetPrimaryChannels(contactId, kind);

      // TODO: Set this channel as primary
      final response = await SupabaseClientService.client
          .from('contact_channels')
          .update({
            'is_primary': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', channelId)
          .select()
          .single();

      return ContactChannelModel.fromJson(response);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Get primary channel for a specific kind
  /// TODO: Implement primary channel retrieval
  static Future<ContactChannelModel?> getPrimaryChannel({
    required String contactId,
    required String kind,
  }) async {
    try {
      // TODO: Query primary channel of specific kind
      final response = await SupabaseClientService.client
          .from('contact_channels')
          .select()
          .eq('contact_id', contactId)
          .eq('kind', kind)
          .eq('is_primary', true)
          .maybeSingle();

      if (response != null) {
        return ContactChannelModel.fromJson(response);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Get channels by type (phone, email, social, etc.)
  /// TODO: Implement channel type filtering
  static Future<List<ContactChannelModel>> getChannelsByType({
    required String contactId,
    required ChannelType type,
  }) async {
    try {
      List<String> kinds;

      switch (type) {
        case ChannelType.phone:
          kinds = ['mobile', 'phone'];
          break;
        case ChannelType.email:
          kinds = ['email'];
          break;
        case ChannelType.social:
          kinds = [
            'whatsapp',
            'telegram',
            'imessage',
            'signal',
            'wechat',
            'instagram',
            'linkedin',
            'github',
            'x',
            'facebook',
            'tiktok',
          ];
          break;
        case ChannelType.payment:
          kinds = ['payid', 'beem', 'bank'];
          break;
        case ChannelType.web:
          kinds = ['website'];
          break;
        case ChannelType.other:
          kinds = ['other'];
          break;
      }

      // TODO: Query channels by kinds
      final response = await SupabaseClientService.client
          .from('contact_channels')
          .select()
          .eq('contact_id', contactId)
          .inFilter('kind', kinds)
          .order('is_primary', ascending: false);

      return response
          .map((json) => ContactChannelModel.fromJson(json))
          .toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Search channels by value
  /// TODO: Implement channel search
  static Future<List<ContactChannelModel>> searchChannels({
    required String ownerId,
    required String query,
    String? kind,
  }) async {
    try {
      var queryBuilder = SupabaseClientService.client
          .from('contact_channels')
          .select()
          .eq('owner_id', ownerId)
          .or('value.ilike.%$query%,url.ilike.%$query%');

      // TODO: Filter by kind if specified
      if (kind != null) {
        queryBuilder = queryBuilder.eq('kind', kind);
      }

      final response = await queryBuilder;
      return response
          .map((json) => ContactChannelModel.fromJson(json))
          .toList();
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Unset primary flag for other channels of the same kind
  /// TODO: Implement primary flag management
  static Future<void> _unsetPrimaryChannels(
    String contactId,
    String kind,
  ) async {
    try {
      // TODO: Set all other channels of same kind to non-primary
      await SupabaseClientService.client
          .from('contact_channels')
          .update({
            'is_primary': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('contact_id', contactId)
          .eq('kind', kind);
    } catch (e) {
      // TODO: Add proper error handling and logging
      rethrow;
    }
  }

  /// Subscribe to channel changes for real-time updates
  /// TODO: Implement real-time subscriptions
  static Stream<List<ContactChannelModel>> subscribeToContactChannels(
    String contactId,
  ) {
    // TODO: Set up real-time subscription for channel changes
    return SupabaseClientService.client
        .from('contact_channels')
        .stream(primaryKey: ['id'])
        .eq('contact_id', contactId)
        .map(
          (data) =>
              data.map((json) => ContactChannelModel.fromJson(json)).toList(),
        );
  }
}

/// Channel type enumeration for filtering
enum ChannelType { phone, email, social, payment, web, other }
