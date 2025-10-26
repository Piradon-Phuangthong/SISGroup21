import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/services/tag_service.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';
import 'package:omada/core/data/utils/validation_utils.dart';

class ContactFormController {
  final SupabaseClient client;
  final ContactService _contacts;
  final TagService _tags;
  final ContactChannelRepository _channelsRepo;

  ContactFormController(this.client)
    : _contacts = ContactService(client),
      _tags = TagService(client),
      _channelsRepo = ContactChannelRepository(client);

  Future<List<TagModel>> getAllTags() => _tags.getTags();

  Future<List<TagModel>> getTagsForContact(String contactId) =>
      _tags.getTagsForContact(contactId);

  Future<List<ContactChannelModel>> getChannelsForContact(String contactId) =>
      _channelsRepo.getChannelsForContact(contactId);

  Future<ContactChannelModel> addChannel({
    required String contactId,
    required String kind,
    String? label,
    String? value,
    String? url,
    Map<String, dynamic>? extra,
    bool isPrimary = false,
  }) =>
      _channelsRepo.createChannel(
        contactId: contactId,
        kind: kind,
        label: label,
        value: value,
        url: url,
        extra: extra,
        isPrimary: isPrimary,
      );

  Future<void> deleteChannel(String channelId) =>
      _channelsRepo.deleteChannel(channelId);

  Future<TagModel?> createTag(String name) => _tags.createTag(name);
  Future<TagModel?> getTagByName(String name) => _tags.getTagByName(name);

  Future<ContactModel> createContact({
    String? fullName,
    String? givenName,
    String? familyName,
    String? primaryMobile,
    String? primaryEmail,
    List<String>? tagIds,
  }) async {
    final contact = await _contacts.createContact(
      fullName: fullName,
      givenName: givenName,
      familyName: familyName,
      primaryMobile: primaryMobile,
      primaryEmail: primaryEmail,
      tagIds: tagIds,
    );

    // Create channels for mobile and email if provided
    await _createContactChannels(contact.id, primaryMobile, primaryEmail);

    return contact;
  }

  Future<ContactModel> updateContact(
    String id, {
    String? fullName,
    String? givenName,
    String? familyName,
    String? primaryMobile,
    String? primaryEmail,
    List<String>? tagIds,
  }) async {
    final contact = await _contacts.updateContact(
      id,
      fullName: fullName,
      givenName: givenName,
      familyName: familyName,
      primaryMobile: primaryMobile,
      primaryEmail: primaryEmail,
      tagIds: tagIds,
    );

    // Update channels for mobile and email if provided
    await _updateContactChannels(id, primaryMobile, primaryEmail);

    return contact;
  }

  // Proxy to validation utils for UI
  String? validateNameTriplet({
    required String full,
    required String given,
    required String family,
  }) {
    if (full.isEmpty && given.isEmpty && family.isEmpty) {
      return 'Provide full name or given/family name';
    }
    if (full.isNotEmpty && !ValidationUtils.isValidContactName(full)) {
      return 'Invalid full name';
    }
    if (given.isNotEmpty && !ValidationUtils.isValidContactName(given)) {
      return 'Invalid given name';
    }
    if (family.isNotEmpty && !ValidationUtils.isValidContactName(family)) {
      return 'Invalid family name';
    }
    return null;
  }

  String? validateEmail(String value) {
    if (value.isEmpty) return null;
    if (!ValidationUtils.isValidEmail(value))
      return 'Enter a valid email address';
    return null;
  }

  /// Creates contact channels for mobile and email
  Future<void> _createContactChannels(
    String contactId,
    String? primaryMobile,
    String? primaryEmail,
  ) async {
    // Create mobile channel if provided
    if (primaryMobile?.isNotEmpty == true) {
      await _channelsRepo.createChannel(
        contactId: contactId,
        kind: 'mobile',
        label: 'Mobile',
        value: primaryMobile,
        url: 'tel:$primaryMobile',
        isPrimary: true,
      );
    }

    // Create email channel if provided
    if (primaryEmail?.isNotEmpty == true) {
      await _channelsRepo.createChannel(
        contactId: contactId,
        kind: 'email',
        label: 'Email',
        value: primaryEmail,
        url: 'mailto:$primaryEmail',
        isPrimary: true,
      );
    }
  }

  /// Updates contact channels for mobile and email
  Future<void> _updateContactChannels(
    String contactId,
    String? primaryMobile,
    String? primaryEmail,
  ) async {
    // Get existing channels
    final existingChannels = await _channelsRepo.getChannelsForContact(contactId);
    
    // Find existing mobile and email channels
    final existingMobileChannel = existingChannels
        .where((ch) => ch.kind == 'mobile')
        .firstOrNull;
    final existingEmailChannel = existingChannels
        .where((ch) => ch.kind == 'email')
        .firstOrNull;

    // Handle mobile channel
    if (primaryMobile?.isNotEmpty == true) {
      if (existingMobileChannel != null) {
        // Update existing mobile channel
        await _channelsRepo.updateChannel(
          existingMobileChannel.id,
          value: primaryMobile,
          url: 'tel:$primaryMobile',
        );
      } else {
        // Create new mobile channel
        await _channelsRepo.createChannel(
          contactId: contactId,
          kind: 'mobile',
          label: 'Mobile',
          value: primaryMobile,
          url: 'tel:$primaryMobile',
          isPrimary: true,
        );
      }
    } else if (existingMobileChannel != null) {
      // Remove mobile channel if no mobile number provided
      await _channelsRepo.deleteChannel(existingMobileChannel.id);
    }

    // Handle email channel
    if (primaryEmail?.isNotEmpty == true) {
      if (existingEmailChannel != null) {
        // Update existing email channel
        await _channelsRepo.updateChannel(
          existingEmailChannel.id,
          value: primaryEmail,
          url: 'mailto:$primaryEmail',
        );
      } else {
        // Create new email channel
        await _channelsRepo.createChannel(
          contactId: contactId,
          kind: 'email',
          label: 'Email',
          value: primaryEmail,
          url: 'mailto:$primaryEmail',
          isPrimary: true,
        );
      }
    } else if (existingEmailChannel != null) {
      // Remove email channel if no email provided
      await _channelsRepo.deleteChannel(existingEmailChannel.id);
    }
  }
}
