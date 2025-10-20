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

  /// Accepts a share request and creates contact shares
  Future<void> acceptShareRequest(
    String requestId, {
    required List<ContactShareConfig> shareConfigs,
  }) async {
    if (shareConfigs.isEmpty) {
      throw ValidationException('At least one contact must be shared');
    }

    final request = await _sharingRepository.getShareRequest(requestId);
    if (request == null) {
      throw ExceptionFactory.shareRequestNotFound(requestId);
    }

    // Accept the request
    await _sharingRepository.respondToShareRequest(
      requestId,
      ShareRequestStatus.accepted,
    );

    // Create contact shares
    for (final config in shareConfigs) {
      await _sharingRepository.createContactShare(
        toUserId: request.requesterId,
        contactId: config.contactId,
        fieldMask: config.fieldMask,
      );
    }
  }

  /// Accepts a share request with channel-specific sharing
  Future<void> acceptShareRequestWithChannels(
    String requestId, {
    required String contactId,
    required List<String> channelIds,
  }) async {
    if (channelIds.isEmpty) {
      throw ValidationException('At least one channel must be selected');
    }

    final request = await _sharingRepository.getShareRequest(requestId);
    if (request == null) {
      throw ExceptionFactory.shareRequestNotFound(requestId);
    }

    // Validate request status
    if (request.status != ShareRequestStatus.pending) {
      throw ValidationException(
        'This request has already been ${request.status.value}',
      );
    }

    // Build field mask with channel-specific entries
    // Always include basic name fields
    final List<String> fieldMask = [
      ContactFields.fullName,
      ContactFields.givenName,
      ContactFields.familyName,
      // Add channel references using "channel:" prefix
      ...channelIds.map((id) => 'channel:$id'),
    ];

    // Accept the request with channel-specific sharing
    await acceptShareRequest(
      requestId,
      shareConfigs: [
        ContactShareConfig(contactId: contactId, fieldMask: fieldMask),
      ],
    );
  }

  /// Declines a share request
  Future<void> declineShareRequest(String requestId) async {
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

    return await _enrichSharesWithDetails(shares);
  }

  /// Enriches contact shares with contact and profile details
  Future<List<ContactShareWithDetails>> _enrichSharesWithDetails(
    List<ContactShareModel> shares,
  ) async {
    if (shares.isEmpty) return [];

    // Get all unique contact and user IDs
    final contactIds = shares.map((s) => s.contactId).toSet().toList();
    final userIds = <String>{
      ...shares.map((s) => s.ownerId),
      ...shares.map((s) => s.toUserId),
    }.toList();

    // Fetch contacts and profiles in parallel
    final futures = await Future.wait([
      _getContactsMap(contactIds),
      _profileRepository.getProfilesByIds(userIds),
    ]);

    final contactsMap = futures[0] as Map<String, ContactModel>;
    final profiles = futures[1] as List<ProfileModel>;
    final profilesMap = {for (final p in profiles) p.id: p};

    return shares.map((share) {
      return ContactShareWithDetails(
        share: share,
        contact: contactsMap[share.contactId],
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
