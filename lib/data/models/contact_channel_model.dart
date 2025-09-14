/// Represents a communication channel for a contact
/// Maps to the 'contact_channels' table in Supabase
class ContactChannelModel {
  final String id;
  final String ownerId;
  final String contactId;
  final String kind;
  final String? label;
  final String? value;
  final String? url;
  final Map<String, dynamic>? extra;
  final bool isPrimary;
  final DateTime updatedAt;

  const ContactChannelModel({
    required this.id,
    required this.ownerId,
    required this.contactId,
    required this.kind,
    this.label,
    this.value,
    this.url,
    this.extra,
    this.isPrimary = false,
    required this.updatedAt,
  });

  /// Creates a ContactChannelModel from a JSON map (from Supabase)
  factory ContactChannelModel.fromJson(Map<String, dynamic> json) {
    return ContactChannelModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      contactId: json['contact_id'] as String,
      kind: json['kind'] as String,
      label: json['label'] as String?,
      value: json['value'] as String?,
      url: json['url'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
      isPrimary: json['is_primary'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts the ContactChannelModel to a JSON map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'contact_id': contactId,
      'kind': kind,
      'label': label,
      'value': value,
      'url': url,
      'extra': extra,
      'is_primary': isPrimary,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converts to JSON for insertion (excludes read-only fields)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    json.remove('updated_at');
    return json;
  }

  /// Converts to JSON for updates (excludes read-only fields)
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('owner_id');
    json.remove('contact_id');
    json.remove('updated_at');
    return json;
  }

  /// Gets the display text for this channel
  String get displayText {
    if (label?.isNotEmpty == true) {
      return value?.isNotEmpty == true ? '$label: $value' : label!;
    }
    return value ?? url ?? kind;
  }

  /// Creates a copy of this ContactChannelModel with optionally updated fields
  ContactChannelModel copyWith({
    String? id,
    String? ownerId,
    String? contactId,
    String? kind,
    String? label,
    String? value,
    String? url,
    Map<String, dynamic>? extra,
    bool? isPrimary,
    DateTime? updatedAt,
  }) {
    return ContactChannelModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      contactId: contactId ?? this.contactId,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      value: value ?? this.value,
      url: url ?? this.url,
      extra: extra ?? this.extra,
      isPrimary: isPrimary ?? this.isPrimary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactChannelModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ContactChannelModel(id: $id, kind: $kind, value: $value, isPrimary: $isPrimary)';
  }
}

/// Common channel kinds
class ChannelKind {
  static const String phone = 'phone';
  static const String email = 'email';
  static const String whatsapp = 'whatsapp';
  static const String telegram = 'telegram';
  static const String instagram = 'instagram';
  static const String facebook = 'facebook';
  static const String linkedin = 'linkedin';
  static const String twitter = 'twitter';
  static const String github = 'github';
  static const String website = 'website';
  static const String address = 'address';
  static const String paypal = 'paypal';
  static const String venmo = 'venmo';
  static const String cashapp = 'cashapp';
  static const String other = 'other';

  static const List<String> all = [
    phone,
    email,
    whatsapp,
    telegram,
    instagram,
    facebook,
    linkedin,
    twitter,
    github,
    website,
    address,
    paypal,
    venmo,
    cashapp,
    other,
  ];
}
