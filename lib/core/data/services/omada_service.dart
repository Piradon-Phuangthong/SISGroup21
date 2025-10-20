import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';

/// Service for managing Omadas (Groups) in the database
class OmadaService {
  final SupabaseClient _client;

  OmadaService(this._client);

  /// Get the current user's ID
  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // =============================
  // Omada CRUD Operations
  // =============================

  /// Fetch all omadas for the current user
  Future<List<OmadaModel>> getOmadas({bool includeDeleted = false}) async {
    try {
      // Try to use the view first (if it exists)
      final query = _client
          .from('omadas_with_counts')
          .select()
          .eq('owner_id', _userId);

      if (!includeDeleted) {
        query.eq('is_deleted', false);
      }

      final response = await query.order('name');
      return (response as List)
          .map((json) => OmadaModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback to base table if view doesn't exist
      final query = _client.from('omadas').select().eq('owner_id', _userId);

      if (!includeDeleted) {
        query.eq('is_deleted', false);
      }

      final response = await query.order('name');
      final omadas = (response as List)
          .map((json) => OmadaModel.fromJson(json))
          .toList();

      // Manually fetch member counts
      for (var i = 0; i < omadas.length; i++) {
        final count = await _getMemberCount(omadas[i].id);
        omadas[i] = omadas[i].copyWith(memberCount: count);
      }

      return omadas;
    }
  }

  /// Get a single omada by ID
  Future<OmadaModel?> getOmadaById(String omadaId) async {
    try {
      // Try to use the view first (if it exists)
      final response = await _client
          .from('omadas_with_counts')
          .select()
          .eq('id', omadaId)
          .eq('owner_id', _userId)
          .maybeSingle();

      return response != null ? OmadaModel.fromJson(response) : null;
    } catch (e) {
      // Fallback to base table if view doesn't exist
      final response = await _client
          .from('omadas')
          .select()
          .eq('id', omadaId)
          .eq('owner_id', _userId)
          .maybeSingle();

      if (response == null) return null;

      final omada = OmadaModel.fromJson(response);
      final count = await _getMemberCount(omada.id);
      return omada.copyWith(memberCount: count);
    }
  }

  /// Create a new omada
  Future<OmadaModel> createOmada({
    required String name,
    String? description,
    String? color,
    String? icon,
  }) async {
    final response = await _client
        .from('omadas')
        .insert({
          'owner_id': _userId,
          'name': name,
          'description': description,
          'color': color,
          'icon': icon,
        })
        .select()
        .single();

    return OmadaModel.fromJson(response);
  }

  /// Update an existing omada
  Future<OmadaModel> updateOmada(
    String omadaId, {
    String? name,
    String? description,
    String? color,
    String? icon,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (color != null) updates['color'] = color;
    if (icon != null) updates['icon'] = icon;

    if (updates.isEmpty) {
      throw Exception('No updates provided');
    }

    final response = await _client
        .from('omadas')
        .update(updates)
        .eq('id', omadaId)
        .eq('owner_id', _userId)
        .select()
        .single();

    return OmadaModel.fromJson(response);
  }

  /// Soft delete an omada
  Future<void> softDeleteOmada(String omadaId) async {
    await _client
        .from('omadas')
        .update({'is_deleted': true})
        .eq('id', omadaId)
        .eq('owner_id', _userId);
  }

  /// Permanently delete an omada
  Future<void> permanentlyDeleteOmada(String omadaId) async {
    await _client
        .from('omadas')
        .delete()
        .eq('id', omadaId)
        .eq('owner_id', _userId);
  }

  // =============================
  // Omada Membership Operations
  // =============================

  /// Get all contact IDs that belong to an omada
  Future<List<String>> getOmadaMembers(String omadaId) async {
    final response = await _client
        .from('omada_members')
        .select('contact_id')
        .eq('omada_id', omadaId);

    return (response as List)
        .map((row) => row['contact_id'] as String)
        .toList();
  }

  /// Get all contacts in an omada (with full contact details)
  Future<List<ContactModel>> getOmadaContacts(String omadaId) async {
    final response = await _client
        .from('omada_members')
        .select('contact_id, contacts(*)')
        .eq('omada_id', omadaId);

    return (response as List)
        .map((row) => ContactModel.fromJson(row['contacts']))
        .toList();
  }

  /// Add a contact to an omada
  Future<void> addContactToOmada(String omadaId, String contactId) async {
    await _client.from('omada_members').insert({
      'omada_id': omadaId,
      'contact_id': contactId,
    });
  }

  /// Add multiple contacts to an omada
  Future<void> addContactsToOmada(
    String omadaId,
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) return;

    final rows = contactIds
        .map((contactId) => {'omada_id': omadaId, 'contact_id': contactId})
        .toList();

    await _client.from('omada_members').insert(rows);
  }

  /// Remove a contact from an omada
  Future<void> removeContactFromOmada(String omadaId, String contactId) async {
    await _client
        .from('omada_members')
        .delete()
        .eq('omada_id', omadaId)
        .eq('contact_id', contactId);
  }

  /// Remove multiple contacts from an omada
  Future<void> removeContactsFromOmada(
    String omadaId,
    List<String> contactIds,
  ) async {
    if (contactIds.isEmpty) return;

    await _client
        .from('omada_members')
        .delete()
        .eq('omada_id', omadaId)
        .inFilter('contact_id', contactIds);
  }

  /// Clear all members from an omada
  Future<void> clearOmadaMembers(String omadaId) async {
    await _client.from('omada_members').delete().eq('omada_id', omadaId);
  }

  /// Get all omadas that a specific contact belongs to
  Future<List<OmadaModel>> getContactOmadas(String contactId) async {
    final response = await _client
        .from('omada_members')
        .select('omada_id, omadas(*)')
        .eq('contact_id', contactId);

    return (response as List)
        .map((row) => OmadaModel.fromJson(row['omadas']))
        .where((omada) => !omada.isDeleted)
        .toList();
  }

  /// Check if a contact is a member of an omada
  Future<bool> isContactInOmada(String omadaId, String contactId) async {
    final response = await _client
        .from('omada_members')
        .select('omada_id')
        .eq('omada_id', omadaId)
        .eq('contact_id', contactId)
        .maybeSingle();

    return response != null;
  }

  // =============================
  // Batch Operations
  // =============================

  /// Get omada statistics
  Future<Map<String, dynamic>> getOmadaStats() async {
    final omadas = await getOmadas();

    int totalOmadas = omadas.length;
    int totalMembers = 0;
    int emptyOmadas = 0;

    for (final omada in omadas) {
      final count = omada.memberCount ?? 0;
      totalMembers += count;
      if (count == 0) emptyOmadas++;
    }

    return {
      'total_omadas': totalOmadas,
      'total_memberships': totalMembers,
      'empty_omadas': emptyOmadas,
      'avg_members_per_omada': totalOmadas > 0
          ? (totalMembers / totalOmadas).toStringAsFixed(1)
          : '0',
    };
  }

  // =============================
  // Helper Methods
  // =============================

  /// Get the member count for a specific omada
  Future<int> _getMemberCount(String omadaId) async {
    final response = await _client
        .from('omada_members')
        .select('contact_id')
        .eq('omada_id', omadaId);

    return response.length;
  }
}
