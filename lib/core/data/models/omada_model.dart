import 'package:flutter/foundation.dart';

/// Represents an Omada (Group) of contacts
@immutable
class OmadaModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? memberCount; // Optional, populated from view

  const OmadaModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
  });

  factory OmadaModel.fromJson(Map<String, dynamic> json) {
    return OmadaModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberCount: json['member_count'] as int?,
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
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (memberCount != null) 'member_count': memberCount,
    };
  }

  OmadaModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? color,
    String? icon,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
  }) {
    return OmadaModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
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
