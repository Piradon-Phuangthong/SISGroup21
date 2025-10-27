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
            'owner_id.eq.$_userId,id.in.(select omada_id from omada_members where user_id=$_userId)',
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
              'owner_id.eq.$_userId,id.in.(select omada_id from omada_members where user_id=$_userId)',
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
  /// Excludes omadas that the current user is already a member of or owns
  Future<List<OmadaModel>> getPublicOmadas({int limit = 50}) async {
    print('🔍 Fetching public omadas for user: $_userId');

    try {
      print('📊 Trying omadas_with_counts view...');
      List<dynamic> response;
      try {
        response = await _client
            .from('omadas_with_counts')
            .select()
            .eq('visibility', 'public')
            .eq('is_deleted', false)
            .neq('owner_id', _userId)
            .not(
              'id',
              'in',
              // Use memberships (user-based) to exclude groups I'm already in
              '(select omada_id from omada_members where user_id=$_userId)',
            )
            .order('member_count', ascending: false)
            .limit(limit);
      } catch (subqError) {
        // If memberships table doesn't exist or RLS blocks it, run without membership exclusion
        print('ℹ️ Membership subquery not available in view path: $subqError');
        response = await _client
            .from('omadas_with_counts')
            .select()
            .eq('visibility', 'public')
            .eq('is_deleted', false)
            .neq('owner_id', _userId)
            .order('member_count', ascending: false)
            .limit(limit);
      }

      final omadas = response.map((json) => OmadaModel.fromJson(json)).toList();

      print('✅ Loaded ${omadas.length} public omadas from omadas_with_counts');
      return omadas;
    } catch (e) {
      print('⚠️ omadas_with_counts failed: $e');
      print('📊 Falling back to base omadas table...');

      // Fallback: base table with visibility filter
      try {
        List<dynamic> response;
        try {
          response = await _client
              .from('omadas')
              .select()
              .eq('visibility', 'public')
              .eq('is_deleted', false)
              .neq('owner_id', _userId)
              .not(
                'id',
                'in',
                // Use memberships (user-based) to exclude groups I'm already in
                '(select omada_id from omada_members where user_id=$_userId)',
              )
              .order('name')
              .limit(limit);
        } catch (subqError) {
          print(
            'ℹ️ Membership subquery not available in base path: $subqError',
          );
          response = await _client
              .from('omadas')
              .select()
              .eq('visibility', 'public')
              .eq('is_deleted', false)
              .neq('owner_id', _userId)
              .order('name')
              .limit(limit);
        }

        final omadas = response
            .map((json) => OmadaModel.fromJson(json))
            .toList();

        print('✅ Loaded ${omadas.length} public omadas from base table');
        final enriched = await _enrichWithCounts(omadas);
        print('✅ Enriched with member counts');
        return enriched;
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        // Return empty list rather than throwing
        return [];
      }
    }
  }

  /// DEBUG: Fetch all public omadas visible via RLS without excluding owner or membership
  /// This helps verify data presence when discovery returns 0.
  Future<List<OmadaModel>> getDebugPublicOmadasAll({int limit = 50}) async {
    try {
      // Prefer the view if present
      final response = await _client
          .from('omadas_with_counts')
          .select()
          .eq('visibility', 'public')
          .eq('is_deleted', false)
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => OmadaModel.fromJson(json))
          .toList();
    } catch (e) {
      // Fallback to base table
      try {
        final response = await _client
            .from('omadas')
            .select()
            .eq('visibility', 'public')
            .eq('is_deleted', false)
            .order('name')
            .limit(limit);

        final omadas = (response as List)
            .map((json) => OmadaModel.fromJson(json))
            .toList();
        return await _enrichWithCounts(omadas);
      } catch (_) {
        return [];
      }
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
      // Try inserting with visibility field first
      Map<String, dynamic> baseResponse;
      try {
        baseResponse = await _client
            .from('omadas')
            .insert({
              'owner_id': _userId,
              'name': name,
              if (description != null) 'description': description,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
              // Include visibility in initial insert to avoid database defaults
              'visibility': isPublic ? 'public' : 'private',
            })
            .select()
            .single();
      } catch (e) {
        // Fallback: try without visibility field for older schemas
        baseResponse = await _client
            .from('omadas')
            .insert({
              'owner_id': _userId,
              'name': name,
              if (description != null) 'description': description,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
            })
            .select()
            .single();
      }

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
      // Set is_public field for newer schemas (visibility already set in initial insert if possible)
      advanced['is_public'] = isPublic;
      // Also try to set visibility if it wasn't set in the initial insert
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
        } catch (e) {
          // Log the error for debugging but don't fail the creation
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
      // Preferred: use consolidated view if available (simpler RLS surface)
      try {
        final viewRes = await _client
            .from('omada_memberships_view')
            .select()
            .eq('omada_id', omadaId)
            .order('joined_at');

        final list = (viewRes as List).map((row) {
          final json = Map<String, dynamic>.from(row as Map);
          // Adapt view shape to model expectations
          json['profiles'] = {
            'name': json['user_name'],
            'avatar_url': json['user_avatar'],
          };
          // Ensure required fields exist
          json['id'] = json['id'] ?? '${json['omada_id']}-${json['user_id']}';
          json['role_name'] = json['role_name'] ?? 'member';
          json['updated_at'] = json['updated_at'] ?? json['joined_at'];
          return OmadaMembershipModel.fromJson(json);
        }).toList();

        return list;
      } catch (_) {
        // Fall through to table-based path
      }

      final response = await _client
          .from('omada_members')
          .select('*, profiles(name, avatar_url), omada_roles!role_id(key)')
          .eq('omada_id', omadaId)
          .eq('status', 'active')
          .order('joined_at');

      final memberships = (response as List).map((json) {
        // Extract role key from the joined omada_roles table
        final roleData = json['omada_roles'] as Map<String, dynamic>?;
        final roleKey = roleData?['key'] as String? ?? 'member';

        // Add role_name to json for the model to parse
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['role_name'] = roleKey;

        // Generate an id if not present (since omada_members doesn't have id column)
        if (!modifiedJson.containsKey('id')) {
          modifiedJson['id'] = '${json['omada_id']}-${json['user_id']}';
        }

        // Add joined_at as updated_at if updated_at is missing
        if (!modifiedJson.containsKey('updated_at')) {
          modifiedJson['updated_at'] = json['joined_at'];
        }

        return OmadaMembershipModel.fromJson(modifiedJson);
      }).toList();

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
        .select('id, username, avatar_url')
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
              userName: (() {
                final n = ownerProfile?['name'] as String?; // some schemas
                final u = ownerProfile?['username'] as String?;
                final val = (n != null && n.trim().isNotEmpty) ? n : u;
                return (val != null && val.trim().isNotEmpty) ? val : 'Owner';
              })(),
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
      // Joined select may fail due to RLS or missing FK relationships.
      // Fallback path: fetch memberships first without joins, then enrich.
      try {
        // 1) Base memberships from omada_members (no joins)
        final baseRes = await _client
            .from('omada_members')
            .select('omada_id, user_id, role_id, joined_at, updated_at, status')
            .eq('omada_id', omadaId)
            .eq('status', 'active')
            .order('joined_at');

        final baseList = (baseRes as List).cast<Map<String, dynamic>>();
        if (baseList.isEmpty) {
          // If no rows visible, at least return owner membership as a last resort
          final omada = await getOmadaById(omadaId);
          if (omada == null) return [];

          // Try to fetch owner profile (best-effort)
          Map<String, dynamic>? ownerProfile;
          try {
      ownerProfile = await _client
        .from('profiles')
        .select('id, username, avatar_url')
        .eq('id', omada.ownerId)
        .maybeSingle();
          } catch (_) {}

          return [
            OmadaMembershipModel(
              id: 'owner-${omada.ownerId}',
              omadaId: omadaId,
              userId: omada.ownerId,
              role: OmadaRole.owner,
              joinedAt: omada.createdAt,
              updatedAt: omada.createdAt,
              userName: (() {
                final n = ownerProfile?['name'] as String?;
                final u = ownerProfile?['username'] as String?;
                final val = (n != null && n.trim().isNotEmpty) ? n : u;
                return (val != null && val.trim().isNotEmpty) ? val : 'Owner';
              })(),
              userAvatar: ownerProfile?['avatar_url'] as String?,
            ),
          ];
        }

        // 2) Build roleId -> key map (best-effort)
        final roleKeyById = <String, String>{};
        try {
          final rolesRes = await _client
              .from('omada_roles')
              .select('id, key');
          for (final row in (rolesRes as List)) {
            final m = row as Map<String, dynamic>;
            final id = (m['id'] as String?) ?? (m['id']?.toString() ?? '');
            final key = m['key'] as String?;
            if (id.isNotEmpty && key != null) roleKeyById[id] = key;
          }
        } catch (_) {
          // ignore – we'll default to 'member' later
        }

        // 3) Collect user IDs and fetch profiles in bulk (best-effort)
        final userIds = baseList
            .map((m) => m['user_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();

        final profilesById = <String, Map<String, dynamic>>{};
        if (userIds.isNotEmpty) {
          try {
      final profRes = await _client
        .from('profiles')
        .select('id, username, avatar_url')
        .filter('id', 'in', '(${userIds.join(',')})');
            for (final row in (profRes as List)) {
              final m = row as Map<String, dynamic>;
              final id = m['id'] as String?;
              if (id != null) profilesById[id] = m;
            }
          } catch (_) {
            // ignore – profiles remain null
          }
        }

        // 4) Map into OmadaMembershipModel instances
        final memberships = baseList.map((m) {
          final userId = m['user_id'] as String;
          final roleIdRaw = m['role_id'];
          final roleId = roleIdRaw == null ? null : roleIdRaw.toString();
          final roleKey = roleId != null ? roleKeyById[roleId] : null;
          final role = roleKey != null
              ? OmadaRole.fromString(roleKey)
              : OmadaRole.member;

          final profile = profilesById[userId];

          return OmadaMembershipModel(
            id: '${m['omada_id']}-${userId}',
            omadaId: m['omada_id'] as String,
            userId: userId,
            role: role,
            joinedAt: DateTime.parse(m['joined_at'] as String),
            updatedAt: DateTime.parse(
              (m['updated_at'] as String?) ?? (m['joined_at'] as String),
            ),
            userName: (() {
              final n = profile?['name'] as String?;
              final u = profile?['username'] as String?;
              final val = (n != null && n.trim().isNotEmpty) ? n : u;
              return val;
            })(),
            userAvatar: profile?['avatar_url'] as String?,
          );
        }).toList();

        // 5) Ensure owner appears at least once
        final omada = await getOmadaById(omadaId);
        if (omada != null &&
            !memberships.any((m) => m.userId == omada.ownerId)) {
          Map<String, dynamic>? ownerProfile;
          try {
      ownerProfile = await _client
        .from('profiles')
        .select('id, username, avatar_url')
        .eq('id', omada.ownerId)
        .maybeSingle();
          } catch (_) {}

          memberships.insert(
            0,
            OmadaMembershipModel(
              id: 'owner-${omada.ownerId}',
              omadaId: omadaId,
              userId: omada.ownerId,
              role: OmadaRole.owner,
              joinedAt: omada.createdAt,
              updatedAt: omada.createdAt,
              userName:
                  (ownerProfile?['name'] as String?)?.trim().isNotEmpty == true
                      ? (ownerProfile?['name'] as String)
                      : 'Owner',
              userAvatar: ownerProfile?['avatar_url'] as String?,
            ),
          );
        }

        return memberships;
      } catch (_) {
        // As a last resort, return only owner membership if possible
        try {
          final omada = await getOmadaById(omadaId);
          if (omada != null) {
            Map<String, dynamic>? ownerProfile;
            try {
              ownerProfile = await _client
                  .from('profiles')
                  .select('name, avatar_url')
                  .eq('id', omada.ownerId)
                  .maybeSingle();
            } catch (_) {}

            return [
              OmadaMembershipModel(
                id: 'owner-${omada.ownerId}',
                omadaId: omadaId,
                userId: omada.ownerId,
                role: OmadaRole.owner,
                joinedAt: omada.createdAt,
                updatedAt: omada.createdAt,
                userName: (() {
                  final n = ownerProfile?['name'] as String?;
                  final u = ownerProfile?['username'] as String?;
                  final val = (n != null && n.trim().isNotEmpty) ? n : u;
                  return (val != null && val.trim().isNotEmpty) ? val : 'Owner';
                })(),
                userAvatar: ownerProfile?['avatar_url'] as String?,
              ),
            ];
          }
        } catch (_) {}
        return [];
      }
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
            .from('omada_members')
            .select('omada_roles!role_id(key)')
            .eq('omada_id', omadaId)
            .eq('user_id', targetUserId)
            .eq('status', 'active')
            .maybeSingle();

        if (response == null) return null;

        final roleData = response['omada_roles'] as Map<String, dynamic>?;
        final roleKey = roleData?['key'] as String?;

        if (roleKey == null) return null;

        return OmadaRole.fromString(roleKey);
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
      // Get role_id from role key
      final roleData = await _client
          .from('omada_roles')
          .select('id')
          .eq('key', role.toDbString())
          .maybeSingle();

      if (roleData == null) {
        throw Exception(
          'Role ${role.toDbString()} not found in omada_roles table',
        );
      }

      final response = await _client
          .from('omada_members')
          .insert({
            'omada_id': omadaId,
            'user_id': userId,
            'role_id': roleData['id'],
            'invited_by': _userId,
            'status': 'active',
          })
          .select('*, profiles(name, avatar_url), omada_roles!role_id(key)')
          .single();

      // Transform response to match model expectations
      final modifiedResponse = Map<String, dynamic>.from(response);
      final roleInfo = response['omada_roles'] as Map<String, dynamic>?;
      modifiedResponse['role_name'] = roleInfo?['key'] ?? role.toDbString();
      modifiedResponse['id'] = '${response['omada_id']}-${response['user_id']}';
      if (!modifiedResponse.containsKey('updated_at')) {
        modifiedResponse['updated_at'] = response['joined_at'];
      }

      return OmadaMembershipModel.fromJson(modifiedResponse);
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
      // Get role_id from role key
      final roleData = await _client
          .from('omada_roles')
          .select('id')
          .eq('key', newRole.toDbString())
          .maybeSingle();

      if (roleData == null) {
        throw Exception(
          'Role ${newRole.toDbString()} not found in omada_roles table',
        );
      }

      final response = await _client
          .from('omada_members')
          .update({'role_id': roleData['id']})
          .eq('omada_id', omadaId)
          .eq('user_id', userId)
          .select('*, profiles(name, avatar_url), omada_roles!role_id(key)')
          .single();

      // Transform response to match model expectations
      final modifiedResponse = Map<String, dynamic>.from(response);
      final roleInfo = response['omada_roles'] as Map<String, dynamic>?;
      modifiedResponse['role_name'] = roleInfo?['key'] ?? newRole.toDbString();
      modifiedResponse['id'] = '${response['omada_id']}-${response['user_id']}';
      if (!modifiedResponse.containsKey('updated_at')) {
        modifiedResponse['updated_at'] = response['joined_at'];
      }

      return OmadaMembershipModel.fromJson(modifiedResponse);
    } catch (e) {
      throw Exception('Error updating member role: $e');
    }
  }

  /// Remove a member from an omada
  Future<void> removeMember(String omadaId, String userId) async {
    try {
      await _client
          .from('omada_members')
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

      // Create pending request (new schema: public.omada_requests)
      // For join requests, we set:
      // - requester_id: the current user
      // - target_user_id: the omada owner
      // - type: 'join'
      final response = await _client
          .from('omada_requests')
          .insert({
            'omada_id': omadaId,
            'requester_id': _userId,
            'target_user_id': omada.ownerId,
            'type': 'join',
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
          .from('omada_requests')
          .select('*')
          .eq('omada_id', omadaId)
          .eq('status', 'pending')
          .eq('type', 'join')
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
          .from('omada_requests')
          .select('*')
          .eq('requester_id', _userId)
          .eq('type', 'join')
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
          .from('omada_requests')
          .update({
            'status': 'approved',
            // No separate response_message in new schema
            'decided_by': _userId,
            'decided_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('type', 'join')
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
          .from('omada_requests')
          .update({
            'status': 'rejected',
            // No separate response_message in new schema
            'decided_by': _userId,
            'decided_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('type', 'join')
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
          .from('omada_requests')
          .delete()
          .eq('omada_id', omadaId)
          .eq('requester_id', _userId)
          .eq('status', 'pending')
          .eq('type', 'join');
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
          .from('omada_members')
          .select('user_id')
          .eq('omada_id', omadaId)
          .eq('status', 'active');

      return (res as List).length;
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
    // Prefer new schema table; fall back to legacy if present
    try {
      final res = await _client
          .from('omada_requests')
          .select('id')
          .eq('omada_id', omadaId)
          .eq('status', 'pending')
          .eq('type', 'join');
      return (res as List).length;
    } catch (_) {
      try {
        final resLegacy = await _client
            .from('omada_join_requests')
            .select('id')
            .eq('omada_id', omadaId)
            .eq('status', 'pending');
        return (resLegacy as List).length;
      } catch (_) {
        return 0;
      }
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
