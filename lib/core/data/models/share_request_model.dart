/// Represents a request to share contact information between users
/// Maps to the 'share_requests' table in Supabase
class ShareRequestModel {
  final String id;
  final String requesterId;
  final String recipientId;
  final String? message;
  final ShareRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ShareRequestModel({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Creates a ShareRequestModel from a JSON map (from Supabase)
  factory ShareRequestModel.fromJson(Map<String, dynamic> json) {
    return ShareRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      recipientId: json['recipient_id'] as String,
      message: json['message'] as String?,
      status: ShareRequestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  /// Converts the ShareRequestModel to a JSON map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'recipient_id': recipientId,
      'message': message,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Converts to JSON for insertion (excludes read-only fields)
  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    json.remove('created_at');
    json.remove('responded_at');
    return json;
  }

  /// Converts to JSON for updates (excludes read-only fields)
  Map<String, dynamic> toUpdateJson() {
    final json = toJson();
    json.remove('id');
    json.remove('requester_id');
    json.remove('recipient_id');
    json.remove('created_at');
    return json;
  }

  /// Creates a copy of this ShareRequestModel with optionally updated fields
  ShareRequestModel copyWith({
    String? id,
    String? requesterId,
    String? recipientId,
    String? message,
    ShareRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return ShareRequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      recipientId: recipientId ?? this.recipientId,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareRequestModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ShareRequestModel(id: $id, status: $status, requesterId: $requesterId, recipientId: $recipientId)';
  }
}

/// Enumeration for share request status
enum ShareRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  const ShareRequestStatus(this.value);

  final String value;

  static ShareRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ShareRequestStatus.pending;
      case 'accepted':
        return ShareRequestStatus.accepted;
      case 'declined':
        return ShareRequestStatus.declined;
      case 'cancelled':
        return ShareRequestStatus.cancelled;
      default:
        throw ArgumentError('Unknown ShareRequestStatus: $value');
    }
  }

  @override
  String toString() => value;
}
