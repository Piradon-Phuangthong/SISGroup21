/// Represents a granted contact share with field-level permissions
/// Maps to the 'contact_shares' table in Supabase
class ContactShareModel {
  final String id;
  final String ownerId;
  final String toUserId;
  final String contactId;
  final List<String> fieldMask;
  final DateTime createdAt;
  final DateTime? revokedAt;

  const ContactShareModel({
    required this.id,
    required this.ownerId,
    required this.toUserId,
    required this.contactId,
    required this.fieldMask,
    required this.createdAt,
    this.revokedAt,
  });

  /// Creates a ContactShareModel from a JSON map (from Supabase)
  factory ContactShareModel.fromJson(Map<String, dynamic> json) {
    return ContactShareModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      toUserId: json['to_user_id'] as String,
      contactId: json['contact_id'] as String,
      fieldMask: (json['field_mask'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
    );
  }

  /// Converts the ContactShareModel to a JSON map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'to_user_id': toUserId,
      'contact_id': contactId,
      'field_mask': fieldMask,
      'created_at': createdAt.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
    };
  }

  /// Converts to JSON for insertion (excludes read-only fields)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    json.remove('created_at');
    return json;
  }

  /// Converts to JSON for updates (excludes read-only fields)
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('owner_id');
    json.remove('to_user_id');
    json.remove('contact_id');
    json.remove('created_at');
    return json;
  }

  /// Checks if this share is currently active (not revoked)
  bool get isActive => revokedAt == null;

  /// Checks if a specific field is included in the share
  bool includesField(String fieldName) {
    return fieldMask.contains(fieldName);
  }

  /// Channel-level field mask support
  ///
  /// Convention: each shared channel appears in field_mask as
  ///   "channel:{channel-uuid}"
  /// Backward compatibility: if field_mask contains plain "channels",
  /// all channels are considered shared.
  static const String channelPrefix = 'channel:';

  /// True if the share indicates that all channels are shared
  bool get sharesAllChannels => fieldMask.contains('channels');

  /// Returns the list of channel IDs present in the field mask using the
  /// "channel:{uuid}" pattern. If plain "channels" is present, returns an
  /// empty list to indicate caller should treat as "all channels".
  List<String> get sharedChannelIds {
    if (sharesAllChannels) return const [];
    return fieldMask
        .where((f) => f.startsWith(channelPrefix))
        .map((f) => f.substring(channelPrefix.length))
        .toList();
  }

  /// Checks whether a specific channel ID is included in this share.
  /// If plain "channels" is present, returns true for any channel.
  bool includesChannel(String channelId) {
    if (sharesAllChannels) return true;
    return fieldMask.contains('$channelPrefix$channelId');
  }

  /// Creates a copy of this ContactShareModel with optionally updated fields
  ContactShareModel copyWith({
    String? id,
    String? ownerId,
    String? toUserId,
    String? contactId,
    List<String>? fieldMask,
    DateTime? createdAt,
    DateTime? revokedAt,
  }) {
    return ContactShareModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      toUserId: toUserId ?? this.toUserId,
      contactId: contactId ?? this.contactId,
      fieldMask: fieldMask ?? this.fieldMask,
      createdAt: createdAt ?? this.createdAt,
      revokedAt: revokedAt ?? this.revokedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactShareModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContactShareModel(id: $id, ownerId: $ownerId, toUserId: $toUserId, contactId: $contactId, isActive: $isActive)';
  }
}

/// Common field names for contact shares
class ContactFields {
  static const String fullName = 'full_name';
  static const String givenName = 'given_name';
  static const String familyName = 'family_name';
  static const String middleName = 'middle_name';
  static const String prefix = 'prefix';
  static const String suffix = 'suffix';
  static const String primaryMobile = 'primary_mobile';
  static const String primaryEmail = 'primary_email';
  static const String avatarUrl = 'avatar_url';
  static const String notes = 'notes';
  static const String customFields = 'custom_fields';
  static const String defaultCallApp = 'default_call_app';
  static const String defaultMsgApp = 'default_msg_app';

  static const List<String> all = [
    fullName,
    givenName,
    familyName,
    middleName,
    prefix,
    suffix,
    primaryMobile,
    primaryEmail,
    avatarUrl,
    notes,
    customFields,
    defaultCallApp,
    defaultMsgApp,
  ];

  static const List<String> essential = [fullName, primaryMobile, primaryEmail];

  static const List<String> basic = [
    fullName,
    givenName,
    familyName,
    primaryMobile,
    primaryEmail,
  ];
}
