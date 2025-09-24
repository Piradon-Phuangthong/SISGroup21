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

  /// Loads current profile, picks the user's primary contact (prefer one with channels),
  /// and returns its channels.
  Future<ProfileData> load() async {
    final profile = await _profiles.getCurrentProfile();

    // Fetch a batch of contacts and prefer one that already has channels
    final candidates = await _contacts.getContacts(limit: 25);

    ContactModel contact;
    List<ContactChannelModel> channels = const [];

    if (candidates.isNotEmpty) {
      // Load channels for each contact in parallel and pick the first with any channels
      final results = await Future.wait(
        candidates.map(
          (c) async =>
              MapEntry(c, await _channelsRepo.getChannelsForContact(c.id)),
        ),
      );

      MapEntry<ContactModel, List<ContactChannelModel>>? withChannels;
      for (final entry in results) {
        if (entry.value.isNotEmpty) {
          withChannels = entry;
          break;
        }
      }

      if (withChannels != null) {
        contact = withChannels.key;
        channels = withChannels.value;
      } else {
        // No channels on any contact yet; use the most recently updated
        contact = candidates.first;
        channels = await _channelsRepo.getChannelsForContact(contact.id);
      }
    } else {
      // No contact exists; create a starter card named after username
      contact = await _contacts.createContact(fullName: profile?.username);
      channels = const [];
    }

    return ProfileData(profile: profile, contact: contact, channels: channels);
  }
}
