/// Represents a tag for organizing contacts
/// Maps to the 'tags' table in Supabase
class TagModel {
  final String id;
  final String ownerId;
  final String name;
  final DateTime createdAt;

  const TagModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
  });

  /// Creates a TagModel from a JSON map (from Supabase)
  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts the TagModel to a JSON map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts to JSON for insertion (excludes read-only fields)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    json.remove('created_at');
    return json;
  }

  /// Converts to JSON for updates (excludes read-only fields)
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('owner_id');
    json.remove('created_at');
    return json;
  }

  /// Creates a copy of this TagModel with optionally updated fields
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'TagModel(id: $id, name: $name, ownerId: $ownerId)';
  }
}
