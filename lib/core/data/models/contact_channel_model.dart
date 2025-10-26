import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Represents a communication channel for a contact
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

  Map<String, dynamic> toJson() => {
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

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id');
    json.remove('updated_at');
    return json;
  }

  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('owner_id');
    json.remove('contact_id');
    json.remove('updated_at');
    return json;
  }

  String get displayText {
    if (label?.isNotEmpty == true) {
      return value?.isNotEmpty == true ? '$label: $value' : label!;
    }
    return value ?? url ?? kind;
  }

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
  String toString() =>
      'ContactChannelModel(id: $id, kind: $kind, value: $value, isPrimary: $isPrimary)';

  /// Get an icon for the channel, with optional style.
  Icon getIcon({Color? color, double? size, String? semanticLabel}) {
    return ChannelKind.getIcon(
      kind,
      color: color,
      size: size,
      semanticLabel: semanticLabel,
    );
  }
}

/// Common channel kinds and icons
class ChannelKind {
  static const String mobile = 'mobile';
  static const String email = 'email';
  static const String messenger = 'messenger';
  static const String whatsapp = 'whatsapp';
  static const String instagram = 'instagram';
  static const String facebook = 'facebook';
  static const String linkedin = 'linkedin';
  static const String website = 'website';
  static const String address = 'address';
  static const String other = 'other';

  static const List<String> all = [
    mobile,
    email,
    messenger,
    whatsapp,
    messenger,
    instagram,
    facebook,
    linkedin,
    website,
    address,
    other,
  ];

  /// Returns an icon for the given channel kind with optional styling
  static Icon getIcon(
    String kind, {
    Color? color,
    double? size,
    String? semanticLabel,
  }) {
    switch (kind) {
      case mobile:
        return Icon(
          Icons.phone,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      case email:
        return Icon(
          Icons.email,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      case messenger:
        return FaIcon(
          FontAwesomeIcons.facebookMessenger,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      case whatsapp:
        return FaIcon(
          FontAwesomeIcons.whatsapp,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );

      case instagram:
        return FaIcon(
          FontAwesomeIcons.instagram,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      case facebook:
        return FaIcon(
          FontAwesomeIcons.facebook,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      case linkedin:
        return FaIcon(
          FontAwesomeIcons.linkedin,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
     
      case website:
        return FaIcon(
          FontAwesomeIcons.link,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      case address:
        return FaIcon(
          FontAwesomeIcons.locationDot,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );

      case other:
        return Icon(
          Icons.more_horiz,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
      default:
        return Icon(
          Icons.help_outline,
          color: color,
          size: size,
          semanticLabel: semanticLabel,
        );
    }
  }
}
