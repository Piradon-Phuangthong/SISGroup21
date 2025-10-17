import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../exceptions/exceptions.dart';

/// Service for contact sharing operations
class SharingService {
  final SharingRepository _sharingRepository;
  final ContactRepository _contactRepository;
  final ProfileRepository _profileRepository;

  SharingService(SupabaseClient client)
    : _sharingRepository = SharingRepository(client),
      _contactRepository = ContactRepository(client),
      _profileRepository = ProfileRepository(client);

  /// Creates a share request to another user
  Future<ShareRequestModel> sendShareRequest({
    required String recipientUsername,
    String? message,
  }) async {
    return await _sharingRepository.createShareRequest(
      recipientUsername: recipientUsername,
      message: message,
    );
  }




  Future<ContactModel?> _createLocalContactFromSharedContact(String otherUserId) async {
  final supa = Supabase.instance.client;
  final myUid = supa.auth.currentUser!.id;

  // 1) Find a share the OTHER user has given to ME
  final share = await supa
      .from('contact_shares')
      .select('contact_id')
      .eq('owner_id', otherUserId)
      .eq('to_user_id', myUid)
      .isFilter('revoked_at', null)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  final String? contactId = share?['contact_id'] as String?;
  if (contactId == null) return null;

  // 2) Now fetch that contact by id (RLS policy on contacts must allow this)
  final contactRow = await supa
      .from('contacts')
      .select('id, full_name, primary_email, primary_mobile, avatar_url')
      .eq('id', contactId)
      .maybeSingle();

  if (contactRow == null) return null;

  final String? email = (contactRow['primary_email'] as String?)?.trim();
  final String? phone = (contactRow['primary_mobile'] as String?)?.trim();

  // If you still require reachability, enforce it here:
  if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
    return null;
  }

  // Create MY local contact (owner_id = auth.uid())
  return await _contactRepository.createContact(
    fullName: (contactRow['full_name'] as String?) ?? 'Unknown',
    primaryEmail: email,
    primaryMobile: phone,
    avatarUrl: contactRow['avatar_url'] as String?,
    notes: 'Imported from shared contact',
  );
}

Future<ContactModel?> _createLocalContactFromUser(String otherUserId) async {
  final profiles = await _profileRepository.getProfilesByIds([otherUserId]);
  if (profiles.isEmpty) return null;
  final p = profiles.first;

  return await _contactRepository.createContact(
    fullName: p.username,
    notes: 'Created from accepted share request with @${p.username}',
    allowNameOnly: true, // ensure validator uses this (see below)
  );
}



  Future<void> createContactShareNow({
  required String toUserId,
  required String contactId,
  required List<String> fieldMask,
}) async {
  // validate fields the same way you already do in the repository
  await _sharingRepository.createContactShare(
    toUserId: toUserId,
    contactId: contactId,
    fieldMask: validateAndFilterFieldMask(fieldMask),
  );
}




  /// Gets incoming share requests (requests to me)
  Future<List<ShareRequestWithProfile>> getIncomingShareRequests({
    ShareRequestStatus? status,
    int? limit,
    int? offset,
  }) async {
    final requests = await _sharingRepository.getIncomingShareRequests(
      status: status,
      limit: limit,
      offset: offset,
    );

    return await _enrichRequestsWithProfiles(requests);
  }

  /// Gets outgoing share requests (requests from me)
  Future<List<ShareRequestWithProfile>> getOutgoingShareRequests({
    ShareRequestStatus? status,
    int? limit,
    int? offset,
  }) async {
    final requests = await _sharingRepository.getOutgoingShareRequests(
      status: status,
      limit: limit,
      offset: offset,
    );

    return await _enrichRequestsWithProfiles(requests);
  }

  /// Enriches share requests with profile information
  Future<List<ShareRequestWithProfile>> _enrichRequestsWithProfiles(
    List<ShareRequestModel> requests,
  ) async {
    if (requests.isEmpty) return [];

    final userIds = <String>{
      ...requests.map((r) => r.requesterId),
      ...requests.map((r) => r.recipientId),
    }.toList();

    final profiles = await _profileRepository.getProfilesByIds(userIds);
    final profileMap = {for (final p in profiles) p.id: p};

    return requests.map((request) {
      final requesterProfile = profileMap[request.requesterId];
      final recipientProfile = profileMap[request.recipientId];

      return ShareRequestWithProfile(
        request: request,
        requesterProfile: requesterProfile,
        recipientProfile: recipientProfile,
      );
    }).toList();
  }

  /// Gets a specific share request
  Future<ShareRequestWithProfile?> getShareRequest(String requestId) async {
    final request = await _sharingRepository.getShareRequest(requestId);
    if (request == null) return null;

    final profiles = await _profileRepository.getProfilesByIds([
      request.requesterId,
      request.recipientId,
    ]);

    final profileMap = {for (final p in profiles) p.id: p};

    return ShareRequestWithProfile(
      request: request,
      requesterProfile: profileMap[request.requesterId],
      recipientProfile: profileMap[request.recipientId],
    );
  }

  /// Accepts a share request, creates the configured shares,
  /// and ensures the requester shows up in my local contacts.

/// Accepts a request and imports a contact the requester already shared *with me*.
/// If nothing usable was shared, we fall back to a name-only stub.
Future<void> acceptShareRequest(
  String requestId, {
  required List<ContactShareConfig> shareConfigs, // <- keep signature to avoid refactors; unused now
}) async {
  final request = await _sharingRepository.getShareRequest(requestId);
  if (request == null) {
    throw ExceptionFactory.shareRequestNotFound(requestId);
  }

  // 1) mark accepted
  await _sharingRepository.respondToShareRequest(
    requestId,
    ShareRequestStatus.accepted,
  );

  // 2) try to import a contact the requester has already shared with me
  final imported = await _createLocalContactFromSharedContact(request.requesterId);

  // 3) fallback: stub contact from profile if nothing with email/phone
  if (imported == null) {
    await _createLocalContactFromUser(request.requesterId);
  }
}





  Future<void> declineShareRequest(String requestId) async {
  final req = await _sharingRepository.getShareRequest(requestId);
  if (req != null) {
    // revoke all active shares from requester -> me
    final incoming = await _sharingRepository.getSharesWithMe();
    final fromThisUser = incoming.where((s) => s.ownerId == req.requesterId);
    for (final s in fromThisUser) {
      if (s.revokedAt == null) {
        await _sharingRepository.revokeContactShare(s.id);
      }
    }
  }

  await _sharingRepository.respondToShareRequest(
    requestId,
    ShareRequestStatus.declined,
  );
}


  /// Responds to a share request without creating shares
  Future<void> respondToShareRequestSimple(
    String requestId,
    ShareRequestStatus response,
  ) async {
    await _sharingRepository.respondToShareRequest(requestId, response);
  }

  /// Cancels a share request (by requester)
  Future<void> cancelShareRequest(String requestId) async {
    await _sharingRepository.cancelShareRequest(requestId);
  }

  /// Gets contacts shared by me
  Future<List<ContactShareWithDetails>> getMyShares({
    bool includeRevoked = false,
    int? limit,
    int? offset,
  }) async {
    final shares = await _sharingRepository.getMyShares(
      includeRevoked: includeRevoked,
      limit: limit,
      offset: offset,
    );

    return await _enrichSharesWithDetails(shares);
  }

  /// Gets contacts shared with me
  Future<List<ContactShareWithDetails>> getSharesWithMe({
    bool includeRevoked = false,
    int? limit,
    int? offset,
  }) async {
    final shares = await _sharingRepository.getSharesWithMe(
      includeRevoked: includeRevoked,
      limit: limit,
      offset: offset,
    );

    return await _enrichSharesWithDetails(shares, allowSharedContacts: true);
  }





Future<List<ContactShareWithDetails>> _enrichSharesWithDetails(
  List<ContactShareModel> shares, {
  bool allowSharedContacts = false, // NEW
}) async {
  if (shares.isEmpty) return [];

  final contactIds = shares.map((s) => s.contactId).toSet().toList();
  final userIds = <String>{
    ...shares.map((s) => s.ownerId),
    ...shares.map((s) => s.toUserId),
  }.toList();

  // 1) Try owned contacts first (fast path, existing behavior)
  final ownedMap = <String, ContactModel>{};
  for (final id in contactIds) {
    try {
      final c = await _contactRepository.getContact(id); // validates ownership
      if (c != null) ownedMap[id] = c;
    } catch (_) {
      // not owned by me; skip
    }
  }

  // 2) For any ids we still don't have, fetch as "shared with me"
  Map<String, ContactModel> sharedMap = {};
  if (allowSharedContacts) {
    final missing = contactIds.where((id) => !ownedMap.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      sharedMap = await _contactRepository.getContactsSharedWithMeByIds(missing);
    }
  }

  final profiles = await _profileRepository.getProfilesByIds(userIds);
  final profilesMap = {for (final p in profiles) p.id: p};

  return shares.map((share) {
    final contact = ownedMap[share.contactId] ?? sharedMap[share.contactId];
    return ContactShareWithDetails(
      share: share,
      contact: contact,
      ownerProfile: profilesMap[share.ownerId],
      recipientProfile: profilesMap[share.toUserId],
    );
  }).toList();
}




  /// Gets contacts map by IDs
  Future<Map<String, ContactModel>> _getContactsMap(
    List<String> contactIds,
  ) async {
    final contactsMap = <String, ContactModel>{};

    for (final contactId in contactIds) {
      try {
        final contact = await _contactRepository.getContact(contactId);
        if (contact != null) {
          contactsMap[contactId] = contact;
        }
      } catch (e) {
        // Skip contacts that user doesn't have access to
        continue;
      }
    }

    return contactsMap;
  }

  /// Updates a contact share's field mask
  Future<ContactShareModel> updateContactShare(
    String shareId,
    List<String> newFieldMask,
  ) async {
    return await _sharingRepository.updateContactShare(shareId, newFieldMask);
  }

  /// Revokes a contact share
  Future<void> revokeContactShare(String shareId) async {
    await _sharingRepository.revokeContactShare(shareId);
  }

  /// Gets sharing statistics
  Future<SharingStats> getSharingStats() async {
    final stats = await _sharingRepository.getSharingStats();
    return SharingStats(
      pendingRequestsToMe: stats['pendingRequestsToMe'] ?? 0,
      pendingRequestsFromMe: stats['pendingRequestsFromMe'] ?? 0,
      activeSharesByMe: stats['activeSharesByMe'] ?? 0,
      activeSharesWithMe: stats['activeSharesWithMe'] ?? 0,
    );
  }

  /// Gets my contacts that I can share
  Future<List<ContactModel>> getShareableContacts() async {
    return await _contactRepository.getContacts(includeDeleted: false);
  }

  /// Validates field mask for sharing
  List<String> validateAndFilterFieldMask(List<String> requestedFields) {
    return requestedFields
        .where((field) => ContactFields.all.contains(field))
        .toList();
  }

  /// Gets pre-defined field mask templates
  Map<String, List<String>> getFieldMaskTemplates() {
    return {
      'Essential': ContactFields.essential,
      'Basic': ContactFields.basic,
      'Full': ContactFields.all,
      'Contact Only': [ContactFields.primaryMobile, ContactFields.primaryEmail],
      'Name Only': [
        ContactFields.fullName,
        ContactFields.givenName,
        ContactFields.familyName,
      ],
    };
  }

  /// Bulk operations: revoke multiple shares
  Future<void> revokeMultipleShares(List<String> shareIds) async {
    for (final shareId in shareIds) {
      try {
        await revokeContactShare(shareId);
      } catch (e) {
        // Continue with other shares even if one fails
        continue;
      }
    }
  }

  /// Gets contacts that have been shared with a specific user
  Future<List<ContactShareWithDetails>> getContactsSharedWithUser(
    String userId,
  ) async {
    final shares = await _sharingRepository.getMyShares();
    final userShares = shares
        .where((share) => share.toUserId == userId && share.isActive)
        .toList();

    return await _enrichSharesWithDetails(userShares);
  }

  /// Searches for users to send share requests to
  Future<List<ProfileModel>> searchUsersForSharing(String searchTerm) async {
    return await _profileRepository.searchProfiles(searchTerm);
  }

  /// Gets recent sharing activity
  Future<List<SharingActivity>> getRecentSharingActivity({
    int limit = 10,
  }) async {
    final futures = await Future.wait([
      getIncomingShareRequests(limit: limit),
      getOutgoingShareRequests(limit: limit),
      getMyShares(limit: limit),
      getSharesWithMe(limit: limit),
    ]);

    final activities = <SharingActivity>[];

    // Add request activities
    for (final request in futures[0] as List<ShareRequestWithProfile>) {
      activities.add(
        SharingActivity(
          type: SharingActivityType.incomingRequest,
          timestamp: request.request.createdAt,
          description:
              'Received share request from ${request.requesterProfile?.username ?? 'Unknown'}',
          relatedId: request.request.id,
        ),
      );
    }

    for (final request in futures[1] as List<ShareRequestWithProfile>) {
      activities.add(
        SharingActivity(
          type: SharingActivityType.outgoingRequest,
          timestamp: request.request.createdAt,
          description:
              'Sent share request to ${request.recipientProfile?.username ?? 'Unknown'}',
          relatedId: request.request.id,
        ),
      );
    }

    // Add share activities
    for (final share in futures[2] as List<ContactShareWithDetails>) {
      activities.add(
        SharingActivity(
          type: SharingActivityType.sharedContact,
          timestamp: share.share.createdAt,
          description:
              'Shared ${share.contact?.displayName ?? 'contact'} with ${share.recipientProfile?.username ?? 'Unknown'}',
          relatedId: share.share.id,
        ),
      );
    }

    for (final share in futures[3] as List<ContactShareWithDetails>) {
      activities.add(
        SharingActivity(
          type: SharingActivityType.receivedContact,
          timestamp: share.share.createdAt,
          description:
              'Received ${share.contact?.displayName ?? 'contact'} from ${share.ownerProfile?.username ?? 'Unknown'}',
          relatedId: share.share.id,
        ),
      );
    }

    // Sort by timestamp and limit
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(limit).toList();
  }
}

/// Helper classes for rich data objects

class ShareRequestWithProfile {
  final ShareRequestModel request;
  final ProfileModel? requesterProfile;
  final ProfileModel? recipientProfile;

  const ShareRequestWithProfile({
    required this.request,
    this.requesterProfile,
    this.recipientProfile,
  });
}

class ContactShareWithDetails {
  final ContactShareModel share;
  final ContactModel? contact;
  final ProfileModel? ownerProfile;
  final ProfileModel? recipientProfile;

  const ContactShareWithDetails({
    required this.share,
    this.contact,
    this.ownerProfile,
    this.recipientProfile,
  });
}

class ContactShareConfig {
  final String contactId;
  final List<String> fieldMask;

  const ContactShareConfig({required this.contactId, required this.fieldMask});
}

class SharingStats {
  final int pendingRequestsToMe;
  final int pendingRequestsFromMe;
  final int activeSharesByMe;
  final int activeSharesWithMe;

  const SharingStats({
    required this.pendingRequestsToMe,
    required this.pendingRequestsFromMe,
    required this.activeSharesByMe,
    required this.activeSharesWithMe,
  });

  int get totalPendingRequests => pendingRequestsToMe + pendingRequestsFromMe;
  int get totalActiveShares => activeSharesByMe + activeSharesWithMe;
}

enum SharingActivityType {
  incomingRequest,
  outgoingRequest,
  sharedContact,
  receivedContact,
}

class SharingActivity {
  final SharingActivityType type;
  final DateTime timestamp;
  final String description;
  final String relatedId;

  const SharingActivity({
    required this.type,
    required this.timestamp,
    required this.description,
    required this.relatedId,
  });
}
