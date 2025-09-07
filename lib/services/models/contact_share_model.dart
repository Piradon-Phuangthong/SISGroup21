/// Contact share model for granular field-level permissions
class ContactShareModel {
  final String id;
  final String ownerId;
  final String toUserId;
  final String contactId;
  final List<String> fieldMask; // allowed fields
  final DateTime createdAt;
  final DateTime? revokedAt;

  ContactShareModel({
    required this.id,
    required this.ownerId,
    required this.toUserId,
    required this.contactId,
    this.fieldMask = const [],
    required this.createdAt,
    this.revokedAt,
  });

  /// Supported field mask tokens
  static const List<String> supportedFields = [
    'full_name',
    'given_name',
    'family_name',
    'middle_name',
    'prefix',
    'suffix',
    'primary_mobile',
    'primary_email',
    'avatar_url',
    'notes',
    'custom_fields',
    'default_call_app',
    'default_msg_app',
    'channels',
    'addresses',
  ];

  /// Common field mask presets
  static const List<String> basicInfo = [
    'full_name',
    'primary_mobile',
    'primary_email',
  ];

  static const List<String> fullContact = [
    'full_name',
    'given_name',
    'family_name',
    'primary_mobile',
    'primary_email',
    'channels',
  ];

  static const List<String> businessContact = [
    'full_name',
    'primary_mobile',
    'primary_email',
    'channels',
    'addresses',
  ];

  /// Create ContactShareModel from JSON response
  factory ContactShareModel.fromJson(Map<String, dynamic> json) {
    return ContactShareModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      toUserId: json['to_user_id'] as String,
      contactId: json['contact_id'] as String,
      fieldMask: List<String>.from(json['field_mask'] as List? ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
    );
  }

  /// Convert ContactShareModel to JSON for API requests
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

  /// Create insert JSON
  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'to_user_id': toUserId,
      'contact_id': contactId,
      'field_mask': fieldMask,
    };
  }

  /// Create revoke JSON
  Map<String, dynamic> toRevokeJson() {
    return {'revoked_at': DateTime.now().toIso8601String()};
  }

  /// Check if share is currently active
  bool get isActive => revokedAt == null;

  /// Check if share has been revoked
  bool get isRevoked => revokedAt != null;

  /// Check if field is allowed in this share
  bool canAccessField(String field) {
    return fieldMask.contains(field);
  }

  /// Check if channels are included
  bool get includesChannels => fieldMask.contains('channels');

  /// Check if addresses are included
  bool get includesAddresses => fieldMask.contains('addresses');

  /// Check if basic contact info is included
  bool get includesBasicInfo {
    return fieldMask.contains('full_name') ||
        fieldMask.contains('given_name') ||
        fieldMask.contains('family_name');
  }

  /// Check if contact methods are included
  bool get includesContactMethods {
    return fieldMask.contains('primary_mobile') ||
        fieldMask.contains('primary_email') ||
        fieldMask.contains('channels');
  }

  /// Get description of what's shared
  String get shareDescription {
    if (fieldMask.isEmpty) return 'No access';

    final List<String> descriptions = [];

    if (includesBasicInfo) descriptions.add('Name');
    if (fieldMask.contains('primary_mobile')) descriptions.add('Phone');
    if (fieldMask.contains('primary_email')) descriptions.add('Email');
    if (includesChannels) descriptions.add('Contact methods');
    if (includesAddresses) descriptions.add('Addresses');
    if (fieldMask.contains('notes')) descriptions.add('Notes');

    if (descriptions.isEmpty) return 'Custom fields only';
    if (descriptions.length > 3) return 'Full contact info';

    return descriptions.join(', ');
  }

  /// Create copy with updated fields
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
  String toString() {
    return 'ContactShareModel(id: $id, contact: $contactId, to: $toUserId, fields: ${fieldMask.length}, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactShareModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
