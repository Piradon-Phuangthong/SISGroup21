import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';

/// Extended service for managing Omadas with role-based membership and join requests
class OmadaServiceExtended {
  final SupabaseClient _client;

  OmadaServiceExtended(this._client);

  /// Get the current user's ID
  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // =============================
  // Omada CRUD Operations
  // =============================

  /// Fetch all omadas for the current user (owned + member of)
  Future<List<OmadaModel>> getMyOmadas({bool includeDeleted = false}) async {
    try {
      final query = _client
          .from('omadas_with_counts')
          .select()
          .or(
            'owner_id.eq.$_userId,id.in.(select omada_id from omada_memberships where user_id=$_userId)',
          );

      if (!includeDeleted) {
        query.eq('is_deleted', false);
      }

      final response = await query.order('name');
      return (response as List)
          .map((json) => OmadaModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback 1: base table with memberships subquery (if table exists)
      try {
        final query = _client
            .from('omadas')
            .select()
            .or(
              'owner_id.eq.$_userId,id.in.(select omada_id from omada_memberships where user_id=$_userId)',
            );

        if (!includeDeleted) {
          query.eq('is_deleted', false);
        }

        final response = await query.order('name');
        final omadas = (response as List)
            .map((json) => OmadaModel.fromJson(json))
            .toList();

        return await _enrichWithCounts(omadas);
      } catch (_) {
        // Fallback 2: only owned omadas
        final query = _client.from('omadas').select().eq('owner_id', _userId);

        if (!includeDeleted) {
          query.eq('is_deleted', false);
        }

        final response = await query.order('name');
        final omadas = (response as List)
            .map((json) => OmadaModel.fromJson(json))
            .toList();

        return await _enrichWithCounts(omadas);
      }
    }
  }

  /// Fetch public omadas (for discovery)
  Future<List<OmadaModel>> getPublicOmadas({int limit = 50}) async {
    try {
      final response = await _client
          .from('omadas_with_counts')
          .select()
          .eq('is_public', true)
          .eq('is_deleted', false)
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => OmadaModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback: base table only has basic columns, no is_public filter available
      // Return empty list for discovery when advanced schema not applied
      return [];
    }
  }

  /// Get a single omada by ID
  Future<OmadaModel?> getOmadaById(String omadaId) async {
    try {
      final response = await _client
          .from('omadas_with_counts')
          .select()
          .eq('id', omadaId)
          .maybeSingle();

      return response != null ? OmadaModel.fromJson(response) : null;
    } catch (e) {
      // Fallback: base table + compute counts
      final response = await _client
          .from('omadas')
          .select()
          .eq('id', omadaId)
          .maybeSingle();

      if (response == null) return null;

      final omada = OmadaModel.fromJson(response);
      final memberCount = await _getMemberCountSafe(omada.id);
      final pending = await _getPendingRequestsCountSafe(omada.id);
      return omada.copyWith(
        memberCount: memberCount,
        pendingRequestsCount: pending,
      );
    }
  }

  /// Helper: Add creator as owner-member in omada_members (schema with roles table)
  Future<void> _addCreatorAsOwnerMember(String omadaId) async {
    try {
      // 1) Check if the owner is already a member (idempotent)
      final existing = await _client
          .from('omada_members')
          .select('omada_id')
          .eq('omada_id', omadaId)
          .eq('user_id', _userId)
          .maybeSingle();

      if (existing != null) {
        return; // already a member
      }

      // 2) Find the role_id for key 'owner'
      final ownerRole = await _client
          .from('omada_roles')
          .select('id')
          .eq('key', 'owner')
          .maybeSingle();

      if (ownerRole == null || ownerRole['id'] == null) {
        // If roles table or owner role doesn't exist, let DB trigger (if any) handle it, else skip silently
        return;
      }

      // 3) Insert membership row as owner
      await _client.from('omada_members').insert({
        'omada_id': omadaId,
        'user_id': _userId,
        'role_id': ownerRole['id'],
        'invited_by': _userId,
        'status': 'active',
      });
    } catch (_) {
      // Table or columns may not exist in a legacy schema; ignore to keep create flow working
    }
  }

  /// Create a new omada (user becomes owner)
  Future<OmadaModel> createOmada({
    required String name,
    String? description,
    String? color,
    String? icon,
    String? avatarUrl,
    JoinPolicy joinPolicy = JoinPolicy.approval,
    bool isPublic = true,
  }) async {
    // Strategy: insert minimal supported columns first (more portable), then best-effort update extras.
    try {
      final baseResponse = await _client
          .from('omadas')
          .insert({
            'owner_id': _userId,
            'name': name,
            if (description != null) 'description': description,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          })
          .select()
          .single();

      var omada = OmadaModel.fromJson(baseResponse);

      // Best-effort update for advanced columns (ignore if columns not present)
      final advanced = <String, dynamic>{};
      if (color != null) advanced['color'] = color;
      if (icon != null) advanced['icon'] = icon;
      if (joinPolicy != JoinPolicy.approval) {
        // only set if different from default to reduce failures on legacy schema
        advanced['join_policy'] = joinPolicy.dbValue;
      }
      // Handle both is_public and visibility fields for different schema versions
      // Set is_public field for newer schemas
      advanced['is_public'] = isPublic;
      // Set visibility field for schemas that use this field instead
      advanced['visibility'] = isPublic ? 'public' : 'private';

      if (advanced.isNotEmpty) {
        try {
          final updateRes = await _client
              .from('omadas')
              .update(advanced)
              .eq('id', omada.id)
              .select()
              .maybeSingle();
          if (updateRes != null) {
            omada = OmadaModel.fromJson(updateRes);
          }
        } catch (_) {
          // Ignore if columns don't exist or RLS prevents update; base insert already succeeded
        }
      }

      // Ensure membership as owner
      await _addCreatorAsOwnerMember(omada.id);
      return omada;
    } catch (e) {
      throw Exception('Error creating omada: $e');
    }
  }

  /// Update an existing omada (requires owner or admin)
  Future<OmadaModel> updateOmada(
    String omadaId, {
    String? name,
    String? description,
    String? color,
    String? icon,
    String? avatarUrl,
    JoinPolicy? joinPolicy,
    bool? isPublic,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (color != null) updates['color'] = color;
      if (icon != null) updates['icon'] = icon;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (joinPolicy != null) updates['join_policy'] = joinPolicy.dbValue;
      if (isPublic != null) {
        updates['is_public'] = isPublic;
        updates['visibility'] = isPublic ? 'public' : 'private';
      }

      if (updates.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await _client
          .from('omadas')
          .update(updates)
          .eq('id', omadaId)
          .select()
          .single();

      return OmadaModel.fromJson(response);
    } catch (e) {
      // If advanced columns fail, retry with only base columns
      final baseUpdates = <String, dynamic>{};
      if (name != null) baseUpdates['name'] = name;
      if (description != null) baseUpdates['description'] = description;
      if (color != null) baseUpdates['color'] = color;
      if (icon != null) baseUpdates['icon'] = icon;

      if (baseUpdates.isEmpty) {
        throw Exception('No supported updates provided for base schema');
      }

      try {
        final response = await _client
            .from('omadas')
            .update(baseUpdates)
            .eq('id', omadaId)
            .select()
            .single();

        return OmadaModel.fromJson(response);
      } catch (fallbackError) {
        throw Exception('Error updating omada: $fallbackError');
      }
    }
  }

  /// Soft delete an omada (owner only)
  Future<void> softDeleteOmada(String omadaId) async {
    try {
      await _client
          .from('omadas')
          .update({'is_deleted': true})
          .eq('id', omadaId)
          .eq('owner_id', _userId);
    } catch (e) {
      throw Exception('Error soft deleting omada: $e');
    }
  }

  /// Permanently delete an omada (owner only)
  Future<void> permanentlyDeleteOmada(String omadaId) async {
    try {
      await _client
          .from('omadas')
          .delete()
          .eq('id', omadaId)
          .eq('owner_id', _userId);
    } catch (e) {
      throw Exception('Error permanently deleting omada: $e');
    }
  }

  // =============================
  // Role-Based Membership Operations
  // =============================

  /// Get all memberships for an omada (with user details)
  Future<List<OmadaMembershipModel>> getOmadaMemberships(String omadaId) async {
    try {
      final response = await _client
          .from('omada_memberships')
          .select('*, profiles(name, avatar_url)')
          .eq('omada_id', omadaId)
          .order('joined_at');

      final memberships = (response as List)
          .map((json) => OmadaMembershipModel.fromJson(json))
          .toList();

      // Check if owner is already in the memberships
      final hasOwner = memberships.any((m) => m.role == OmadaRole.owner);

      if (!hasOwner) {
        // Get the Omada to find the owner
        final omada = await getOmadaById(omadaId);
        if (omada != null) {
          // Get owner profile info
          try {
            final ownerProfile = await _client
                .from('profiles')
                .select('name, avatar_url')
                .eq('id', omada.ownerId)
                .maybeSingle();

            // Create a synthetic membership for the owner
            final ownerMembership = OmadaMembershipModel(
              id: 'owner-${omada.ownerId}', // Synthetic ID
              omadaId: omadaId,
              userId: omada.ownerId,
              role: OmadaRole.owner,
              joinedAt: omada.createdAt, // Use omada creation date
              updatedAt: omada.createdAt,
              userName:
                  (ownerProfile?['name'] as String?)?.trim().isNotEmpty == true
                  ? (ownerProfile?['name'] as String)
                  : 'Owner',
              userAvatar: ownerProfile?['avatar_url'] as String?,
            );

            // Add owner at the beginning of the list
            memberships.insert(0, ownerMembership);
          } catch (_) {
            // If we can't get owner profile, still add basic owner membership
            final ownerMembership = OmadaMembershipModel(
              id: 'owner-${omada.ownerId}', // Synthetic ID
              omadaId: omadaId,
              userId: omada.ownerId,
              role: OmadaRole.owner,
              joinedAt: omada.createdAt,
              updatedAt: omada.createdAt,
              userName: 'Owner',
              userAvatar: null,
            );
            memberships.insert(0, ownerMembership);
          }
        }
      }

      return memberships;
    } catch (e) {
      // Advanced table may be missing in legacy schema
      // Still try to return the owner as a member
      try {
        final omada = await getOmadaById(omadaId);
        if (omada != null) {
          // Get owner profile info
          try {
            final ownerProfile = await _client
                .from('profiles')
                .select('name, avatar_url')
                .eq('id', omada.ownerId)
                .maybeSingle();

            return [
              OmadaMembershipModel(
                id: 'owner-${omada.ownerId}',
                omadaId: omadaId,
                userId: omada.ownerId,
                role: OmadaRole.owner,
                joinedAt: omada.createdAt,
                updatedAt: omada.createdAt,
                userName:
                    (ownerProfile?['name'] as String?)?.trim().isNotEmpty ==
                        true
                    ? (ownerProfile?['name'] as String)
                    : 'Owner',
                userAvatar: ownerProfile?['avatar_url'] as String?,
              ),
            ];
          } catch (_) {
            return [
              OmadaMembershipModel(
                id: 'owner-${omada.ownerId}',
                omadaId: omadaId,
                userId: omada.ownerId,
                role: OmadaRole.owner,
                joinedAt: omada.createdAt,
                updatedAt: omada.createdAt,
                userName: 'Owner',
                userAvatar: null,
              ),
            ];
          }
        }
      } catch (_) {
        // If everything fails, return empty list
      }
      return [];
    }
  }

  /// Get user's role in an omada
  Future<OmadaRole?> getUserRole(String omadaId, {String? userId}) async {
    try {
      final targetUserId = userId ?? _userId;

      // Check if user is owner
      final omada = await getOmadaById(omadaId);
      if (omada?.ownerId == targetUserId) {
        return OmadaRole.owner;
      }

      // Check membership role
      try {
        final response = await _client
            .from('omada_memberships')
            .select('role_name')
            .eq('omada_id', omadaId)
            .eq('user_id', targetUserId)
            .maybeSingle();

        if (response == null) return null;

        return OmadaRole.fromString(response['role_name'] as String);
      } catch (_) {
        // Advanced memberships table missing; cannot infer role
        return null;
      }
    } catch (e) {
      throw Exception('Error getting user role: $e');
    }
  }

  /// Check if user has required permission level
  Future<bool> hasPermission(
    String omadaId,
    OmadaRole requiredRole, {
    String? userId,
  }) async {
    try {
      final userRole = await getUserRole(omadaId, userId: userId);
      if (userRole == null) return false;
      return userRole.hasPermission(requiredRole);
    } catch (e) {
      return false;
    }
  }

  /// Add a member to an omada with a specific role
  Future<OmadaMembershipModel> addMember(
    String omadaId,
    String userId, {
    OmadaRole role = OmadaRole.member,
  }) async {
    try {
      final response = await _client
          .from('omada_memberships')
          .insert({
            'omada_id': omadaId,
            'user_id': userId,
            'role_name': role.toDbString(),
          })
          .select()
          .single();

      return OmadaMembershipModel.fromJson(response);
    } catch (e) {
      throw Exception('Error adding member: $e');
    }
  }

  /// Update a member's role (requires higher role than target)
  Future<OmadaMembershipModel> updateMemberRole(
    String omadaId,
    String userId,
    OmadaRole newRole,
  ) async {
    try {
      final response = await _client
          .from('omada_memberships')
          .update({'role_name': newRole.toDbString()})
          .eq('omada_id', omadaId)
          .eq('user_id', userId)
          .select()
          .single();

      return OmadaMembershipModel.fromJson(response);
    } catch (e) {
      throw Exception('Error updating member role: $e');
    }
  }

  /// Remove a member from an omada
  Future<void> removeMember(String omadaId, String userId) async {
    try {
      await _client
          .from('omada_memberships')
          .delete()
          .eq('omada_id', omadaId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error removing member: $e');
    }
  }

  /// Leave an omada (remove self)
  Future<void> leaveOmada(String omadaId) async {
    try {
      final omada = await getOmadaById(omadaId);
      if (omada?.ownerId == _userId) {
        throw Exception(
          'Owner cannot leave. Transfer ownership or delete the omada.',
        );
      }

      await removeMember(omadaId, _userId);
    } catch (e) {
      throw Exception('Error leaving omada: $e');
    }
  }

  // =============================
  // Join Request Operations
  // =============================

  /// Request to join an omada
  Future<JoinRequestModel> requestToJoin(
    String omadaId, {
    String? message,
  }) async {
    try {
      // Check if already a member
      final role = await getUserRole(omadaId);
      if (role != null) {
        throw Exception('Already a member of this omada');
      }

      // Check join policy
      final omada = await getOmadaById(omadaId);
      if (omada == null) {
        throw Exception('Omada not found');
      }

      if (omada.joinPolicy == JoinPolicy.closed) {
        throw Exception('This omada is closed to new members');
      }

      if (omada.joinPolicy == JoinPolicy.open) {
        // Directly add as member
        await addMember(omadaId, _userId, role: OmadaRole.member);
        // Return a fake approved request
        return JoinRequestModel(
          id: 'auto-approved',
          omadaId: omadaId,
          userId: _userId,
          status: JoinRequestStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Create pending request
      final response = await _client
          .from('omada_join_requests')
          .insert({
            'omada_id': omadaId,
            'user_id': _userId,
            'message': message,
            'status': 'pending',
          })
          .select()
          .single();

      return JoinRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error requesting to join: $e');
    }
  }

  /// Get pending join requests for an omada (moderator+)
  Future<List<JoinRequestModel>> getPendingRequests(String omadaId) async {
    try {
      final response = await _client
          .from('omada_join_requests')
          .select('*, profiles(name, avatar_url)')
          .eq('omada_id', omadaId)
          .eq('status', 'pending')
          .order('created_at');

      return (response as List)
          .map((json) => JoinRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      // Table may be missing in legacy schema – return empty list gracefully
      return [];
    }
  }

  /// Get user's join requests (pending, approved, rejected)
  Future<List<JoinRequestModel>> getMyJoinRequests() async {
    try {
      final response = await _client
          .from('omada_join_requests')
          .select('*, omadas(name, avatar_url)')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => JoinRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      // Table may be missing in legacy schema – return empty list gracefully
      return [];
    }
  }

  /// Approve a join request (moderator+)
  Future<JoinRequestModel> approveJoinRequest(
    String requestId, {
    String? responseMessage,
  }) async {
    try {
      final response = await _client
          .from('omada_join_requests')
          .update({
            'status': 'approved',
            'response_message': responseMessage,
            'reviewed_by': _userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return JoinRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error approving request: $e');
    }
  }

  /// Reject a join request (moderator+)
  Future<JoinRequestModel> rejectJoinRequest(
    String requestId, {
    String? responseMessage,
  }) async {
    try {
      final response = await _client
          .from('omada_join_requests')
          .update({
            'status': 'rejected',
            'response_message': responseMessage,
            'reviewed_by': _userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return JoinRequestModel.fromJson(response);
    } catch (e) {
      throw Exception('Error rejecting request: $e');
    }
  }

  /// Cancel own pending join request
  Future<void> cancelJoinRequest(String omadaId) async {
    try {
      await _client
          .from('omada_join_requests')
          .delete()
          .eq('omada_id', omadaId)
          .eq('user_id', _userId)
          .eq('status', 'pending');
    } catch (e) {
      // If table missing, nothing to cancel – ignore
      return;
    }
  }

  // =============================
  // Statistics and Analytics
  // =============================

  /// Get omada statistics
  Future<Map<String, dynamic>> getOmadaStats() async {
    try {
      final omadas = await getMyOmadas();

      int totalOmadas = omadas.length;
      int ownedOmadas = omadas.where((o) => o.ownerId == _userId).length;
      int totalMembers = 0;

      for (final omada in omadas) {
        totalMembers += omada.memberCount ?? 0;
      }

      return {
        'total_omadas': totalOmadas,
        'owned_omadas': ownedOmadas,
        'member_of': totalOmadas - ownedOmadas,
        'total_members': totalMembers,
        'avg_members': totalOmadas > 0
            ? (totalMembers / totalOmadas).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      return {};
    }
  }

  // =============================
  // Helpers: Safe fallbacks for counts
  // =============================

  /// Compute member count trying new memberships table first then legacy members table
  Future<int> _getMemberCountSafe(String omadaId) async {
    try {
      final res = await _client
          .from('omada_memberships')
          .select('id')
          .eq('omada_id', omadaId);

      // Always add 1 for the owner (if owner not already in memberships)
      final membershipCount = (res as List).length;

      // Check if owner is already in memberships
      final ownerInMemberships = await _client
          .from('omada_memberships')
          .select('id')
          .eq('omada_id', omadaId)
          .eq('role_name', 'owner')
          .maybeSingle();

      // If owner not in memberships, add 1 to count
      return ownerInMemberships == null ? membershipCount + 1 : membershipCount;
    } catch (_) {
      try {
        final resLegacy = await _client
            .from('omada_members')
            .select('contact_id')
            .eq('omada_id', omadaId);
        // Legacy table + 1 for owner
        return (resLegacy as List).length + 1;
      } catch (_) {
        // No tables available, assume just the owner
        return 1;
      }
    }
  }

  /// Compute pending requests count; if table missing, return 0
  Future<int> _getPendingRequestsCountSafe(String omadaId) async {
    try {
      final res = await _client
          .from('omada_join_requests')
          .select('id')
          .eq('omada_id', omadaId)
          .eq('status', 'pending');
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Enrich a list of omadas with computed counts
  Future<List<OmadaModel>> _enrichWithCounts(List<OmadaModel> omadas) async {
    final futures = omadas.map((o) async {
      final memberCount = await _getMemberCountSafe(o.id);
      final pending = await _getPendingRequestsCountSafe(o.id);
      return o.copyWith(
        memberCount: memberCount,
        pendingRequestsCount: pending,
      );
    }).toList();
    return Future.wait(futures);
  }
}
