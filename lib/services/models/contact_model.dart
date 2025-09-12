/// Enhanced Contact model matching cloud database schema
class ContactModel {
  final String id;
  final String ownerId;
  final String? fullName;
  final String? givenName;
  final String? familyName;
  final String? middleName;
  final String? prefix;
  final String? suffix;
  final String? primaryMobile;
  final String? primaryEmail;
  final String? avatarUrl;
  final String? notes;
  final Map<String, dynamic> customFields;
  final String? defaultCallApp;
  final String? defaultMsgApp;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactModel({
    required this.id,
    required this.ownerId,
    this.fullName,
    this.givenName,
    this.familyName,
    this.middleName,
    this.prefix,
    this.suffix,
    this.primaryMobile,
    this.primaryEmail,
    this.avatarUrl,
    this.notes,
    this.customFields = const {},
    this.defaultCallApp,
    this.defaultMsgApp,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ContactModel from JSON response
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      fullName: json['full_name'] as String?,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      middleName: json['middle_name'] as String?,
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
      primaryMobile: json['primary_mobile'] as String?,
      primaryEmail: json['primary_email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      notes: json['notes'] as String?,
      customFields: (json['custom_fields'] as Map<String, dynamic>?) ?? {},
      defaultCallApp: json['default_call_app'] as String?,
      defaultMsgApp: json['default_msg_app'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert ContactModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': fullName,
      'given_name': givenName,
      'family_name': familyName,
      'middle_name': middleName,
      'prefix': prefix,
      'suffix': suffix,
      'primary_mobile': primaryMobile,
      'primary_email': primaryEmail,
      'avatar_url': avatarUrl,
      'notes': notes,
      'custom_fields': customFields,
      'default_call_app': defaultCallApp,
      'default_msg_app': defaultMsgApp,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create insert JSON (excludes computed fields)
  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': fullName,
      'given_name': givenName,
      'family_name': familyName,
      'middle_name': middleName,
      'prefix': prefix,
      'suffix': suffix,
      'primary_mobile': primaryMobile,
      'primary_email': primaryEmail,
      'avatar_url': avatarUrl,
      'notes': notes,
      'custom_fields': customFields,
      'default_call_app': defaultCallApp,
      'default_msg_app': defaultMsgApp,
      'is_deleted': isDeleted,
    };
  }

  /// Create update JSON (excludes id and created_at)
  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'given_name': givenName,
      'family_name': familyName,
      'middle_name': middleName,
      'prefix': prefix,
      'suffix': suffix,
      'primary_mobile': primaryMobile,
      'primary_email': primaryEmail,
      'avatar_url': avatarUrl,
      'notes': notes,
      'custom_fields': customFields,
      'default_call_app': defaultCallApp,
      'default_msg_app': defaultMsgApp,
      'is_deleted': isDeleted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get display name with fallback logic
  String get displayName {
    if (fullName?.isNotEmpty == true) return fullName!;
    if (givenName?.isNotEmpty == true && familyName?.isNotEmpty == true) {
      return '${givenName!} ${familyName!}';
    }
    if (givenName?.isNotEmpty == true) return givenName!;
    if (familyName?.isNotEmpty == true) return familyName!;
    if (primaryEmail?.isNotEmpty == true) return primaryEmail!;
    if (primaryMobile?.isNotEmpty == true) return primaryMobile!;
    return 'Unknown Contact';
  }

  /// Generate initials for display
  String get initials {
    if (givenName?.isNotEmpty == true && familyName?.isNotEmpty == true) {
      return '${givenName![0].toUpperCase()}${familyName![0].toUpperCase()}';
    }
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      }
      return fullName![0].toUpperCase();
    }
    return '?';
  }

  /// Create copy with updated fields
  ContactModel copyWith({
    String? id,
    String? ownerId,
    String? fullName,
    String? givenName,
    String? familyName,
    String? middleName,
    String? prefix,
    String? suffix,
    String? primaryMobile,
    String? primaryEmail,
    String? avatarUrl,
    String? notes,
    Map<String, dynamic>? customFields,
    String? defaultCallApp,
    String? defaultMsgApp,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      fullName: fullName ?? this.fullName,
      givenName: givenName ?? this.givenName,
      familyName: familyName ?? this.familyName,
      middleName: middleName ?? this.middleName,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      primaryMobile: primaryMobile ?? this.primaryMobile,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notes: notes ?? this.notes,
      customFields: customFields ?? this.customFields,
      defaultCallApp: defaultCallApp ?? this.defaultCallApp,
      defaultMsgApp: defaultMsgApp ?? this.defaultMsgApp,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, displayName: $displayName, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
