/// Represents a contact in the system
/// Maps to the 'contacts' table in Supabase
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

  const ContactModel({
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

  /// Creates a ContactModel from a JSON map (from Supabase)
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
      customFields: json['custom_fields'] as Map<String, dynamic>? ?? {},
      defaultCallApp: json['default_call_app'] as String?,
      defaultMsgApp: json['default_msg_app'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the ContactModel to a JSON map (for Supabase)
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

  /// Converts to JSON for insertion (excludes read-only fields)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  /// Converts to JSON for updates (excludes read-only fields)
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('owner_id');
    json.remove('created_at');
    json.remove('updated_at');
    return json;
  }

  /// Gets the display name for this contact
  String get displayName {
    if (fullName?.isNotEmpty == true) return fullName!;

    final parts = <String>[];
    if (prefix?.isNotEmpty == true) parts.add(prefix!);
    if (givenName?.isNotEmpty == true) parts.add(givenName!);
    if (middleName?.isNotEmpty == true) parts.add(middleName!);
    if (familyName?.isNotEmpty == true) parts.add(familyName!);
    if (suffix?.isNotEmpty == true) parts.add(suffix!);

    if (parts.isNotEmpty) return parts.join(' ');

    // Fallback to email or phone
    return primaryEmail ?? primaryMobile ?? 'Unknown Contact';
  }

  /// Gets the initials for this contact
  String get initials {
    final name = displayName;
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();

    if (words.isEmpty) return '??';
    if (words.length == 1) {
      return words.first.length >= 2
          ? words.first.substring(0, 2).toUpperCase()
          : words.first.toUpperCase();
    }

    return words
        .take(2)
        .map((word) => word.substring(0, 1).toUpperCase())
        .join();
  }

  /// Creates a copy of this ContactModel with optionally updated fields
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContactModel(id: $id, displayName: $displayName, primaryMobile: $primaryMobile)';
  }
}
