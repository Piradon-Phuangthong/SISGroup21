/// Contact channel model for phones, emails, socials, payments, etc.
class ContactChannelModel {
  final String id;
  final String ownerId;
  final String contactId;
  final String
  kind; // mobile|phone|email|whatsapp|telegram|imessage|signal|wechat|instagram|linkedin|github|x|facebook|tiktok|website|payid|beem|bank|other
  final String? label; // work|home|main|etc
  final String? value; // number, email, @handle, payment id, etc
  final String? url; // canonical URL if applicable
  final Map<String, dynamic>? extra; // structured extras like bank details
  final bool isPrimary;
  final DateTime updatedAt;

  ContactChannelModel({
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

  /// Supported channel kinds
  static const List<String> supportedKinds = [
    'mobile',
    'phone',
    'email',
    'whatsapp',
    'telegram',
    'imessage',
    'signal',
    'wechat',
    'instagram',
    'linkedin',
    'github',
    'x',
    'facebook',
    'tiktok',
    'website',
    'payid',
    'beem',
    'bank',
    'other',
  ];

  /// Create ContactChannelModel from JSON response
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

  /// Convert ContactChannelModel to JSON for API requests
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

  /// Create insert JSON
  Map<String, dynamic> toInsertJson() {
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
    };
  }

  /// Create update JSON
  Map<String, dynamic> toUpdateJson() {
    return {
      'kind': kind,
      'label': label,
      'value': value,
      'url': url,
      'extra': extra,
      'is_primary': isPrimary,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get display text for this channel
  String get displayText {
    if (value?.isNotEmpty == true) {
      if (label?.isNotEmpty == true) {
        return '$label: $value';
      }
      return value!;
    }
    if (url?.isNotEmpty == true) {
      return url!;
    }
    return kind;
  }

  /// Check if this is a phone-type channel
  bool get isPhoneType => kind == 'mobile' || kind == 'phone';

  /// Check if this is an email channel
  bool get isEmailType => kind == 'email';

  /// Check if this is a social media channel
  bool get isSocialType => [
    'whatsapp',
    'telegram',
    'imessage',
    'signal',
    'wechat',
    'instagram',
    'linkedin',
    'github',
    'x',
    'facebook',
    'tiktok',
  ].contains(kind);

  /// Check if this is a payment channel
  bool get isPaymentType => ['payid', 'beem', 'bank'].contains(kind);

  /// Check if this is a website/URL channel
  bool get isWebType => kind == 'website';

  /// Create copy with updated fields
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
  String toString() {
    return 'ContactChannelModel(id: $id, kind: $kind, value: $value, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactChannelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
