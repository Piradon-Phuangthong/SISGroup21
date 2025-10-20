import 'package:flutter/foundation.dart';
import 'omada_role.dart';

/// Represents a user's membership in an Omada with their role
@immutable
class OmadaMembershipModel {
  final String id;
  final String omadaId;
  final String userId;
  final OmadaRole role;
  final DateTime joinedAt;
  final DateTime updatedAt;

  // Optional: Populated with join
  final String? userName;
  final String? userAvatar;

  const OmadaMembershipModel({
    required this.id,
    required this.omadaId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
  });

  factory OmadaMembershipModel.fromJson(Map<String, dynamic> json) {
    // Handle nested profiles data if present
    final profiles = json['profiles'] as Map<String, dynamic>?;

    return OmadaMembershipModel(
      id: json['id'] as String,
      omadaId: json['omada_id'] as String,
      userId: json['user_id'] as String,
      role: OmadaRole.fromString(json['role_name'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: profiles?['name'] as String?,
      userAvatar: profiles?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'omada_id': omadaId,
      'user_id': userId,
      'role_name': role.toDbString(),
      'joined_at': joinedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OmadaMembershipModel copyWith({
    String? id,
    String? omadaId,
    String? userId,
    OmadaRole? role,
    DateTime? joinedAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatar,
  }) {
    return OmadaMembershipModel(
      id: id ?? this.id,
      omadaId: omadaId ?? this.omadaId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  @override
  String toString() {
    return 'OmadaMembershipModel(userId: $userId, role: ${role.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OmadaMembershipModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
