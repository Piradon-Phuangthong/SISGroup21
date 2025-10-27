import 'contact_model.dart';
import 'contact_share_model.dart';
import 'profile_model.dart';

/// Wrapper class for shared contact information
/// Contains the contact data, share permissions, and owner profile
class SharedContactData {
  final ContactModel contact;
  final ContactShareModel share;
  final ProfileModel ownerProfile;

  const SharedContactData({
    required this.contact,
    required this.share,
    required this.ownerProfile,
  });

  /// Returns true since this is a shared contact
  bool get isShared => true;

  /// Gets the username of the person who shared this contact
  String get sharedBy => ownerProfile.username;

  /// Checks if the share is currently active
  bool get isActive => share.isActive;

  /// Checks if a specific field is included in the share permissions
  bool includesField(String fieldName) => share.includesField(fieldName);

  /// Gets the list of channel IDs that are shared
  /// Parses field_mask entries that start with "channel:"
  List<String> get sharedChannelIds {
    return share.fieldMask
        .where((field) => field.startsWith('channel:'))
        .map((field) => field.substring(8)) // Remove "channel:" prefix
        .toList();
  }

  /// Checks if a specific channel is shared
  bool isChannelShared(String channelId) {
    return sharedChannelIds.contains(channelId);
  }

  @override
  String toString() {
    return 'SharedContactData(contact: ${contact.displayName}, sharedBy: $sharedBy, active: $isActive)';
  }
}
