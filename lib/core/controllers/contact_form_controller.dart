import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/services/tag_service.dart';
import 'package:omada/core/data/utils/validation_utils.dart';

class ContactFormController {
  final SupabaseClient client;
  final ContactService _contacts;
  final TagService _tags;

  ContactFormController(this.client)
    : _contacts = ContactService(client),
      _tags = TagService(client);

  Future<List<TagModel>> getAllTags() => _tags.getTags();

  Future<List<TagModel>> getTagsForContact(String contactId) =>
      _tags.getTagsForContact(contactId);

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
    return _contacts.createContact(
      fullName: fullName,
      givenName: givenName,
      familyName: familyName,
      primaryMobile: primaryMobile,
      primaryEmail: primaryEmail,
      tagIds: tagIds,
    );
  }

  Future<ContactModel> updateContact(
    String id, {
    String? fullName,
    String? givenName,
    String? familyName,
    String? primaryMobile,
    String? primaryEmail,
    List<String>? tagIds,
  }) {
    return _contacts.updateContact(
      id,
      fullName: fullName,
      givenName: givenName,
      familyName: familyName,
      primaryMobile: primaryMobile,
      primaryEmail: primaryEmail,
      tagIds: tagIds,
    );
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
}
