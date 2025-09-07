import 'package:uuid/uuid.dart';
import 'supabase_client.dart';
import 'models/contact_channel_model.dart';

/// Contact channel management service for phones, emails, socials, payments, etc.
class ContactChannelService {
  static const _uuid = Uuid();

  /// Add new channel to contact
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
      if (!ContactChannelModel.supportedKinds.contains(kind)) {
        throw Exception('Unsupported channel kind: $kind');
      }

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

      final response = await SupabaseClientService.client
          .from('contact_channels')
          .insert(channel.toInsertJson())
          .select()
          .single();

      return ContactChannelModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all channels for a contact
  static Future<List<ContactChannelModel>> getContactChannels({
    required String contactId,
    String? kind,
  }) async {
    try {
      final table = SupabaseClientService.client.from('contact_channels');

      // Keep it as PostgrestFilterBuilder while adding filters
      var query =
          table.select().eq('contact_id', contactId);

      if (kind != null) {
        query = query.eq('kind', kind);
      }

      // Transform (order) only after filters
      final response = await query
          .order('is_primary', ascending: false)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => ContactChannelModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get specific channel by ID
  static Future<ContactChannelModel?> getChannelById(String channelId) async {
    try {
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
      return null;
    }
  }

  /// Update existing channel
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

      if (isPrimary == true) {
        final channel = await getChannelById(channelId);
        if (channel != null) {
          await _unsetPrimaryChannels(channel.contactId, kind ?? channel.kind);
        }
      }

      final response = await SupabaseClientService.client
          .from('contact_channels')
          .update(updateData)
          .eq('id', channelId)
          .select()
          .single();

      return ContactChannelModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete channel
  static Future<void> deleteContactChannel(String channelId) async {
    try {
      await SupabaseClientService.client
          .from('contact_channels')
          .delete()
          .eq('id', channelId);
    } catch (e) {
      rethrow;
    }
  }

  /// Set channel as primary for its kind
  static Future<ContactChannelModel> setPrimaryChannel({
    required String channelId,
    required String contactId,
    required String kind,
  }) async {
    try {
      await _unsetPrimaryChannels(contactId, kind);

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
      rethrow;
    }
  }

  /// Get primary channel for a specific kind
  static Future<ContactChannelModel?> getPrimaryChannel({
    required String contactId,
    required String kind,
  }) async {
    try {
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
      return null;
    }
  }

  /// Get channels by type (phone, email, social, etc.)
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

      final table = SupabaseClientService.client.from('contact_channels');

      final query = table
          .select()
          .eq('contact_id', contactId)
          .inFilter('kind', kinds);

      final response = await query.order('is_primary', ascending: false);

      return (response as List)
          .map((json) => ContactChannelModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search channels by value/url (case-insensitive)
  static Future<List<ContactChannelModel>> searchChannels({
    required String ownerId,
    required String query,
    String? kind,
  }) async {
    try {
      final table = SupabaseClientService.client.from('contact_channels');

      // keep as PostgrestFilterBuilder while filtering
      var qb = table
          .select()
          .eq('owner_id', ownerId)
          .or('value.ilike.%$query%,url.ilike.%$query%');

      if (kind != null) {
        qb = qb.eq('kind', kind);
      }

      final response = await qb; // No transform needed; add .order if you want
      return (response as List)
          .map((json) => ContactChannelModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Unset primary flag for other channels of the same kind
  static Future<void> _unsetPrimaryChannels(
    String contactId,
    String kind,
  ) async {
    try {
      await SupabaseClientService.client
          .from('contact_channels')
          .update({
            'is_primary': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('contact_id', contactId)
          .eq('kind', kind);
    } catch (e) {
      rethrow;
    }
  }

  /// Subscribe to channel changes for real-time updates
  static Stream<List<ContactChannelModel>> subscribeToContactChannels(
    String contactId,
  ) {
    return SupabaseClientService.client
        .from('contact_channels')
        .stream(primaryKey: ['id'])
        .eq('contact_id', contactId)
        .map((data) =>
            data.map((json) => ContactChannelModel.fromJson(json)).toList());
  }
}

/// Channel type enumeration for filtering
enum ChannelType { phone, email, social, payment, web, other }
