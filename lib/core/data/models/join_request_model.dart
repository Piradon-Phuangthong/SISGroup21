import 'package:flutter/foundation.dart';

/// Status of a join request
enum JoinRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String dbValue;
  const JoinRequestStatus(this.dbValue);

  static JoinRequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return JoinRequestStatus.pending;
      case 'approved':
        return JoinRequestStatus.approved;
      case 'rejected':
        return JoinRequestStatus.rejected;
      default:
        return JoinRequestStatus.pending;
    }
  }
}

/// Represents a request to join an Omada
@immutable
class JoinRequestModel {
  final String id;
  final String omadaId;
  final String userId;
  final JoinRequestStatus status;
  final String? message;
  final String? responseMessage;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Populated with joins
  final String? omadaName;
  final String? userName;
  final String? userAvatar;
  final String? reviewerName;

  const JoinRequestModel({
    required this.id,
    required this.omadaId,
    required this.userId,
    required this.status,
    this.message,
    this.responseMessage,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.omadaName,
    this.userName,
    this.userAvatar,
    this.reviewerName,
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    // Handle nested data if present
    final omadas = json['omadas'] as Map<String, dynamic>?;
    final profiles = json['profiles'] as Map<String, dynamic>?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;

    // Support both legacy 'omada_join_requests' and new 'omada_requests' schemas
    final userId = (json['user_id'] ?? json['requester_id']) as String;
    final reviewedBy = (json['reviewed_by'] ?? json['decided_by']) as String?;

    // reviewed/decided timestamp mapping
    final reviewedAtRaw = (json['reviewed_at'] ?? json['decided_at']);
    final reviewedAt = reviewedAtRaw != null
        ? DateTime.parse(reviewedAtRaw as String)
        : null;

    // updated_at may not exist in new schema; fallback to decided_at or created_at
    final updatedAtRaw =
        (json['updated_at'] ?? json['decided_at'] ?? json['created_at'])
            as String;

    return JoinRequestModel(
      id: json['id'] as String,
      omadaId: json['omada_id'] as String,
      userId: userId,
      status: JoinRequestStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      responseMessage: json['response_message'] as String?,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(updatedAtRaw),
      omadaName: omadas?['name'] as String?,
      userName: profiles?['name'] as String?,
      userAvatar: profiles?['avatar_url'] as String?,
      reviewerName: reviewer?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'omada_id': omadaId,
      'user_id': userId,
      'status': status.dbValue,
      'message': message,
      'response_message': responseMessage,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  JoinRequestModel copyWith({
    String? id,
    String? omadaId,
    String? userId,
    JoinRequestStatus? status,
    String? message,
    String? responseMessage,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? omadaName,
    String? userName,
    String? userAvatar,
    String? reviewerName,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      omadaId: omadaId ?? this.omadaId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      message: message ?? this.message,
      responseMessage: responseMessage ?? this.responseMessage,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      omadaName: omadaName ?? this.omadaName,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      reviewerName: reviewerName ?? this.reviewerName,
    );
  }

  bool get isPending => status == JoinRequestStatus.pending;
  bool get isApproved => status == JoinRequestStatus.approved;
  bool get isRejected => status == JoinRequestStatus.rejected;

  @override
  String toString() {
    return 'JoinRequestModel(userId: $userId, status: ${status.dbValue})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JoinRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
