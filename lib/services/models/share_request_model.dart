/// Share request model for username-based sharing handshake
class ShareRequestModel {
  final String id;
  final String requesterId;
  final String recipientId;
  final String? message;
  final String status; // pending|accepted|declined|blocked
  final DateTime createdAt;
  final DateTime? respondedAt;

  ShareRequestModel({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  /// Supported status values
  static const List<String> validStatuses = [
    'pending',
    'accepted',
    'declined',
    'blocked',
  ];

  /// Create ShareRequestModel from JSON response
  factory ShareRequestModel.fromJson(Map<String, dynamic> json) {
    return ShareRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      recipientId: json['recipient_id'] as String,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  /// Convert ShareRequestModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'recipient_id': recipientId,
      'message': message,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Create insert JSON
  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'recipient_id': recipientId,
      'message': message,
      'status': status,
    };
  }

  /// Create update JSON for responding to request
  Map<String, dynamic> toResponseJson(String newStatus) {
    return {
      'status': newStatus,
      'responded_at': DateTime.now().toIso8601String(),
    };
  }

  /// Check if request is still pending
  bool get isPending => status == 'pending';

  /// Check if request was accepted
  bool get isAccepted => status == 'accepted';

  /// Check if request was declined
  bool get isDeclined => status == 'declined';

  /// Check if user is blocked
  bool get isBlocked => status == 'blocked';

  /// Create copy with updated fields
  ShareRequestModel copyWith({
    String? id,
    String? requesterId,
    String? recipientId,
    String? message,
    String? status,
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
  String toString() {
    return 'ShareRequestModel(id: $id, status: $status, requester: $requesterId, recipient: $recipientId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
