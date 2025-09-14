/// Enhanced Tag model matching cloud database schema
class TagModel {
  final String id;
  final String ownerId;
  final String name;
  final DateTime createdAt;

  TagModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
  });

  /// Create TagModel from JSON response
  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert TagModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create insert JSON
  Map<String, dynamic> toInsertJson() {
    return {'id': id, 'owner_id': ownerId, 'name': name};
  }

  /// Create update JSON
  Map<String, dynamic> toUpdateJson() {
    return {'name': name};
  }

  /// Create copy with updated fields
  TagModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    DateTime? createdAt,
  }) {
    return TagModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TagModel(id: $id, name: $name, ownerId: $ownerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Junction model for contact-tag relationships
class ContactTagModel {
  final String contactId;
  final String tagId;
  final DateTime createdAt;

  ContactTagModel({
    required this.contactId,
    required this.tagId,
    required this.createdAt,
  });

  /// Create ContactTagModel from JSON response
  factory ContactTagModel.fromJson(Map<String, dynamic> json) {
    return ContactTagModel(
      contactId: json['contact_id'] as String,
      tagId: json['tag_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert ContactTagModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'contact_id': contactId,
      'tag_id': tagId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create insert JSON
  Map<String, dynamic> toInsertJson() {
    return {'contact_id': contactId, 'tag_id': tagId};
  }

  @override
  String toString() {
    return 'ContactTagModel(contactId: $contactId, tagId: $tagId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactTagModel &&
        other.contactId == contactId &&
        other.tagId == tagId;
  }

  @override
  int get hashCode => contactId.hashCode ^ tagId.hashCode;
}
