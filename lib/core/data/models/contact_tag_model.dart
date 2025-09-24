/// Represents the many-to-many relationship between contacts and tags
/// Maps to the 'contact_tags' table in Supabase
class ContactTagModel {
  final String contactId;
  final String tagId;
  final DateTime createdAt;

  const ContactTagModel({
    required this.contactId,
    required this.tagId,
    required this.createdAt,
  });

  /// Creates a ContactTagModel from a JSON map (from Supabase)
  factory ContactTagModel.fromJson(Map<String, dynamic> json) {
    return ContactTagModel(
      contactId: json['contact_id'] as String,
      tagId: json['tag_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts the ContactTagModel to a JSON map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'contact_id': contactId,
      'tag_id': tagId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts to JSON for insertion (excludes read-only fields)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('created_at');
    return json;
  }

  /// Creates a copy of this ContactTagModel with optionally updated fields
  ContactTagModel copyWith({
    String? contactId,
    String? tagId,
    DateTime? createdAt,
  }) {
    return ContactTagModel(
      contactId: contactId ?? this.contactId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactTagModel &&
          runtimeType == other.runtimeType &&
          contactId == other.contactId &&
          tagId == other.tagId;

  @override
  int get hashCode => contactId.hashCode ^ tagId.hashCode;

  @override
  String toString() {
    return 'ContactTagModel(contactId: $contactId, tagId: $tagId)';
  }
}
