/// Represents a user profile in the system
/// Maps to the 'profiles' table in Supabase
class ProfileModel {
  final String id;
  final String username;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  /// Creates a ProfileModel from a JSON map (from Supabase)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts the ProfileModel to a JSON map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this ProfileModel with optionally updated fields
  ProfileModel copyWith({String? id, String? username, DateTime? createdAt}) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;

  @override
  String toString() {
    return 'ProfileModel(id: $id, username: $username, createdAt: $createdAt)';
  }
}
