import 'package:flutter/foundation.dart';
import 'omada_role.dart';

/// Represents an Omada (Group) of contacts
@immutable
class OmadaModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final String? avatarUrl;
  final JoinPolicy joinPolicy;
  final bool isPublic;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? memberCount; // Optional, populated from view
  final int? pendingRequestsCount; // Optional, populated from view

  const OmadaModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.avatarUrl,
    this.joinPolicy = JoinPolicy.approval,
    this.isPublic = true,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
    this.pendingRequestsCount,
  });

  factory OmadaModel.fromJson(Map<String, dynamic> json) {
    return OmadaModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      joinPolicy: json['join_policy'] != null
          ? JoinPolicy.fromString(json['join_policy'] as String)
          : JoinPolicy.approval,
      isPublic: json['is_public'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberCount: json['member_count'] as int?,
      pendingRequestsCount: json['pending_requests_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'avatar_url': avatarUrl,
      'join_policy': joinPolicy.dbValue,
      'is_public': isPublic,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (memberCount != null) 'member_count': memberCount,
      if (pendingRequestsCount != null)
        'pending_requests_count': pendingRequestsCount,
    };
  }

  OmadaModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? color,
    String? icon,
    String? avatarUrl,
    JoinPolicy? joinPolicy,
    bool? isPublic,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    int? pendingRequestsCount,
  }) {
    return OmadaModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinPolicy: joinPolicy ?? this.joinPolicy,
      isPublic: isPublic ?? this.isPublic,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
    );
  }

  @override
  String toString() {
    return 'OmadaModel(id: $id, name: $name, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OmadaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
