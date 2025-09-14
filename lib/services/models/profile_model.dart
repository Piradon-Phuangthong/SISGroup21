/// Profile model representing a user profile in the cloud database
class ProfileModel {
  final String id;
  final String username;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  /// Create ProfileModel from JSON response
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert ProfileModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create new profile for insert operations
  Map<String, dynamic> toInsertJson() {
    return {'id': id, 'username': username};
  }

  /// Create copy with updated fields
  ProfileModel copyWith({String? id, String? username, DateTime? createdAt}) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, username: $username, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileModel &&
        other.id == id &&
        other.username == username &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ createdAt.hashCode;
}
