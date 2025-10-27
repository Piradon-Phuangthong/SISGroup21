import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omada/core/data/models/models.dart';
import 'package:omada/core/data/services/contact_service.dart';
import 'package:omada/core/data/repositories/profile_repository.dart';
import 'package:omada/core/data/repositories/contact_channel_repository.dart';

/// Aggregates data needed for the Profile page (pure non-UI logic)
class ProfileData {
  final ProfileModel? profile;
  final ContactModel contact;
  final List<ContactChannelModel> channels;
  const ProfileData({
    this.profile,
    required this.contact,
    required this.channels,
  });
}

class ProfileController {
  final SupabaseClient client;
  final ProfileRepository _profiles;
  final ContactService _contacts;
  final ContactChannelRepository _channelsRepo;

  ProfileController(this.client)
    : _profiles = ProfileRepository(client),
      _contacts = ContactService(client),
      _channelsRepo = ContactChannelRepository(client);

  /// Loads current profile, finds or creates the user's profile contact,
  /// and returns its channels.
  Future<ProfileData> load() async {
    print('ProfileController: Loading profile data...');
    final profile = await _profiles.getCurrentProfile();
    print('ProfileController: Profile loaded: ${profile?.username}');

    // Find or create the user's profile contact
    ContactModel contact;
    try {
      contact = await _getOrCreateProfileContact(profile?.username);
      print('ProfileController: Using profile contact: ${contact.fullName} (ID: ${contact.id})');
    } catch (e) {
      print('ProfileController: Error getting profile contact: $e');
      // Fallback: use the first available contact or create a generic one
      final candidates = await _contacts.getContacts(limit: 1);
      if (candidates.isNotEmpty) {
        contact = candidates.first;
        print('ProfileController: Using fallback contact: ${contact.fullName} (ID: ${contact.id})');
      } else {
        // Last resort: create a contact with a generic name
        contact = await _contacts.createContact(
          fullName: 'My Profile',
          customFields: {'is_profile_contact': true},
        );
        print('ProfileController: Created fallback contact: ${contact.fullName} (ID: ${contact.id})');
      }
    }

    // Load channels for the profile contact
    final channels = await _channelsRepo.getChannelsForContact(contact.id);
    print('ProfileController: Found ${channels.length} channels for profile contact');

    print('ProfileController: Returning ProfileData with ${channels.length} channels');
    return ProfileData(profile: profile, contact: contact, channels: channels);
  }

  /// Gets or creates the user's profile contact.
  /// This ensures we always use a dedicated contact for the user's profile.
  Future<ContactModel> _getOrCreateProfileContact(String? username) async {
    print('ProfileController: Looking for profile contact for current user');
    
    // Get the current user's profile ID
    final profile = await _profiles.getCurrentProfile();
    if (profile?.id == null) {
      print('ProfileController: ERROR - No profile found for current user!');
      throw Exception('User profile not found');
    }
    
    final userId = profile!.id;
    print('ProfileController: Current user ID: $userId');

    // First, try to find a contact marked as profile contact
    final markedProfileContact = await _findMarkedProfileContact();
    if (markedProfileContact != null) {
      print('ProfileController: Found marked profile contact: ${markedProfileContact.fullName} (ID: ${markedProfileContact.id})');
      return markedProfileContact;
    }

    // Look for existing contacts owned by this user
    final candidates = await _contacts.getContacts(limit: 100);
    print('ProfileController: Found ${candidates.length} total contacts');
    
    // Debug: Print all contacts with their owner IDs
    for (int i = 0; i < candidates.length && i < 5; i++) {
      final candidate = candidates[i];
      print('ProfileController: Contact $i: "${candidate.fullName}" (ID: ${profile.id}, Owner: ${candidate.ownerId})');
    }
    
    // Look for contacts owned by the current user
    final userContacts = candidates.where((contact) => contact.ownerId == userId).toList();
    print('ProfileController: Found ${userContacts.length} contacts owned by current user');
    
    if (userContacts.isNotEmpty) {
      // Strategy 1: Look for contacts with very few or no channels (likely profile contacts)
      final contactsWithChannelCount = <MapEntry<ContactModel, int>>[];
      for (final candidate in userContacts) {
        final channelCount = await _channelsRepo.getChannelsForContact(candidate.id).then((channels) => channels.length);
        contactsWithChannelCount.add(MapEntry(candidate, channelCount));
      }
      
      // Sort by channel count (ascending) and pick the one with least channels
      contactsWithChannelCount.sort((a, b) => a.value.compareTo(b.value));
      final contactWithLeastChannels = contactsWithChannelCount.first.key;
      print('ProfileController: Using contact with least channels as profile contact: ${contactWithLeastChannels.fullName} (ID: ${contactWithLeastChannels.id})');
      
      // Mark this contact as the profile contact for future reference
      await markAsProfileContact(contactWithLeastChannels.id);
      return contactWithLeastChannels;
    }

    // If no contacts found for this user, create a new profile contact
    print('ProfileController: No contacts found for user, creating new profile contact...');
    try {
      final contact = await _contacts.createContact(
        fullName: username ?? 'My Profile',
        customFields: {'is_profile_contact': true},
      );
      print('ProfileController: Successfully created new profile contact: ${contact.fullName} (ID: ${contact.id})');
      return contact;
    } catch (e) {
      print('ProfileController: ERROR creating profile contact: $e');
      rethrow;
    }
  }

  /// Verifies that the given contact ID belongs to the user's profile contact.
  /// This is a safety check to ensure channels are only added to the profile contact.
  Future<bool> isProfileContact(String contactId) async {
    final profile = await _profiles.getCurrentProfile();
    if (profile?.id == null) return false;
    
    final profileContact = await _getOrCreateProfileContact(profile!.username);
    return profileContact.id == contactId;
  }

  /// Marks a contact as the user's profile contact by updating its custom fields.
  /// This helps identify the profile contact in future loads.
  Future<void> markAsProfileContact(String contactId) async {
    try {
      await _contacts.updateContact(contactId, customFields: {'is_profile_contact': true});
      print('ProfileController: Marked contact $contactId as profile contact');
    } catch (e) {
      print('ProfileController: Error marking contact as profile contact: $e');
    }
  }

  /// Finds the contact marked as profile contact in custom fields.
  Future<ContactModel?> _findMarkedProfileContact() async {
    // Get the current user's profile ID
    final profile = await _profiles.getCurrentProfile();
    if (profile?.id == null) return null;
    
    final userId = profile!.id;
    final candidates = await _contacts.getContacts(limit: 100);
    
    // Only look for contacts owned by the current user
    for (final candidate in candidates) {
      if (candidate.ownerId == userId && candidate.customFields['is_profile_contact'] == true) {
        print('ProfileController: Found marked profile contact: ${candidate.fullName} (ID: ${candidate.id})');
        return candidate;
      }
    }
    
    return null;
  }
}
