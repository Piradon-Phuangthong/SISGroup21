import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/services/tag_service.dart';
import 'package:omada/core/data/services/sharing_service.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/repositories/contact_repository.dart';

/// High-level orchestrator for Contacts page logic
class ContactsController {
  final SupabaseClient client;
  final ContactService _contacts;
  final TagService _tags;
  final SharingService _sharing;
  final ContactChannelRepository _channelsRepo;
  final ContactRepository _contactRepo;

  ContactsController(this.client)
    : _contacts = ContactService(client),
      _tags = TagService(client),
      _sharing = SharingService(client),
      _channelsRepo = ContactChannelRepository(client),
      _contactRepo = ContactRepository(client);

  // Expose services and repositories to UI widgets that specifically require them
  TagService get tagService => _tags;
  SharingService get sharingService => _sharing;
  ContactRepository get contactRepository => _contactRepo;
  ContactChannelRepository get contactChannelRepository => _channelsRepo;

  Future<List<ContactModel>> getContacts({
    bool includeDeleted = false,
    String? searchTerm,
    List<String>? tagIds,
  }) async {
    return _contacts.getContacts(
      includeDeleted: includeDeleted,
      searchTerm: searchTerm,
      tagIds: tagIds,
    );
  }

  Future<void> deleteContact(String id) => _contacts.deleteContact(id);
  Future<ContactModel> restoreContact(String id) =>
      _contacts.restoreContact(id);

  Future<List<TagModel>> getTags() => _tags.getTags();
  Future<List<TagModel>> getTagsForContact(String contactId) =>
      _tags.getTagsForContact(contactId);
  Future<TagModel?> getTagByName(String name) => _tags.getTagByName(name);
  Future<TagModel?> createTag(String name) => _tags.createTag(name);
  Future<void> deleteTag(String id) => _tags.deleteTag(id);

  /// Cleans up contacts with empty string emails
  Future<void> cleanupEmptyEmails() => _contacts.cleanupEmptyEmails();

  Future<Map<String, List<TagModel>>> getTagsForContacts(
    List<ContactModel> contacts,
  ) async {
    final entries = await Future.wait(
      contacts.map((c) async {
        try {
          final t = await _tags.getTagsForContact(c.id);
          return MapEntry(c.id, t);
        } catch (_) {
          return MapEntry(c.id, <TagModel>[]);
        }
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<Map<String, List<ContactChannelModel>>> getChannelsForContacts(
    List<ContactModel> contacts,
  ) async {
    final entries = await Future.wait(
      contacts.map((c) async {
        try {
          final channels = await _channelsRepo.getChannelsForContact(c.id);
          return MapEntry(c.id, channels);
        } catch (_) {
          return MapEntry(c.id, <ContactChannelModel>[]);
        }
      }),
    );
    return Map.fromEntries(entries);
  }

  Future<List<ProfileModel>> searchUsersForSharing(String query) =>
      _sharing.searchUsersForSharing(query);
  Future<void> sendShareRequest({
    required String recipientUsername,
    String? message,
  }) => _sharing.sendShareRequest(
    recipientUsername: recipientUsername,
    message: message,
  );
  Future<List<ShareRequestWithProfile>> getIncomingShareRequests({
    ShareRequestStatus? status,
  }) => _sharing.getIncomingShareRequests(status: status);
  Future<void> respondToShareRequestSimple(
    String id,
    ShareRequestStatus response,
  ) => _sharing.respondToShareRequestSimple(id, response);

  Future<List<ContactModel>> getDeletedContacts({String? searchTerm}) =>
      _contacts.getDeletedContacts(searchTerm: searchTerm);

  Future<void> permanentlyDeleteContact(String id) =>
      _contacts.permanentlyDeleteContact(id);
}
