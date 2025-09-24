/// Base exception class for all data layer exceptions
abstract class DataException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const DataException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'DataException: $message';
}

/// Exception thrown when authentication fails
class AuthException extends DataException {
  const AuthException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when user is not authenticated
class UnauthenticatedException extends AuthException {
  const UnauthenticatedException([String? message])
    : super(message ?? 'User is not authenticated');
}

/// Exception thrown when access is forbidden
class ForbiddenException extends DataException {
  const ForbiddenException([String? message])
    : super(message ?? 'Access forbidden');

  @override
  String toString() => 'ForbiddenException: $message';
}

/// Exception thrown when a resource is not found
class NotFoundException extends DataException {
  final String resourceType;
  final String? resourceId;

  const NotFoundException(this.resourceType, {this.resourceId, String? message})
    : super(
        message ??
            'Resource not found: $resourceType${resourceId != null ? ' (id: $resourceId)' : ''}',
      );

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception thrown when trying to create a resource that already exists
class ConflictException extends DataException {
  final String resourceType;
  final String? field;

  const ConflictException(this.resourceType, {this.field, String? message})
    : super(
        message ??
            'Resource already exists: $resourceType${field != null ? ' (field: $field)' : ''}',
      );

  @override
  String toString() => 'ConflictException: $message';
}

/// Exception thrown when validation fails
class ValidationException extends DataException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(String message, {this.fieldErrors, String? code})
    : super(message, code: code);

  @override
  String toString() {
    if (fieldErrors?.isNotEmpty == true) {
      final errorDetails = fieldErrors!.entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join('; ');
      return 'ValidationException: $message ($errorDetails)';
    }
    return 'ValidationException: $message';
  }
}

/// Exception thrown when database operation fails
class DatabaseException extends DataException {
  const DatabaseException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception thrown when network operation fails
class NetworkException extends DataException {
  const NetworkException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when file upload fails
class FileUploadException extends DataException {
  final String? fileName;
  final int? fileSize;

  const FileUploadException(
    String message, {
    this.fileName,
    this.fileSize,
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);

  @override
  String toString() =>
      'FileUploadException: $message${fileName != null ? ' (file: $fileName)' : ''}';
}

/// Exception thrown when rate limiting is encountered
class RateLimitException extends DataException {
  final DateTime? retryAfter;

  const RateLimitException(String message, {this.retryAfter, String? code})
    : super(message, code: code);

  @override
  String toString() =>
      'RateLimitException: $message${retryAfter != null ? ' (retry after: $retryAfter)' : ''}';
}

/// Exception thrown when data format is invalid
class DataFormatException extends DataException {
  final String? expectedFormat;
  final String? actualFormat;

  const DataFormatException(
    String message, {
    this.expectedFormat,
    this.actualFormat,
    String? code,
  }) : super(message, code: code);

  @override
  String toString() => 'DataFormatException: $message';
}

/// Utility class for creating common exceptions
class ExceptionFactory {
  static AuthException authFailed(String message, {dynamic originalError}) {
    return AuthException(message, originalError: originalError);
  }

  static NotFoundException contactNotFound(String contactId) {
    return NotFoundException('Contact', resourceId: contactId);
  }

  static NotFoundException tagNotFound(String tagId) {
    return NotFoundException('Tag', resourceId: tagId);
  }

  static NotFoundException profileNotFound(String profileId) {
    return NotFoundException('Profile', resourceId: profileId);
  }

  static NotFoundException shareRequestNotFound(String requestId) {
    return NotFoundException('ShareRequest', resourceId: requestId);
  }

  static ConflictException tagAlreadyExists(String tagName) {
    return ConflictException(
      'Tag',
      field: 'name',
      message: 'Tag "$tagName" already exists',
    );
  }

  static ConflictException usernameAlreadyExists(String username) {
    return ConflictException(
      'Profile',
      field: 'username',
      message: 'Username "$username" already exists',
    );
  }

  static ValidationException invalidContactData(
    Map<String, List<String>> errors,
  ) {
    return ValidationException('Invalid contact data', fieldErrors: errors);
  }

  static ValidationException invalidTagName(String reason) {
    return ValidationException('Invalid tag name: $reason');
  }

  static ValidationException invalidUsername(String reason) {
    return ValidationException('Invalid username: $reason');
  }

  static DatabaseException queryFailed(
    String operation, {
    dynamic originalError,
  }) {
    return DatabaseException(
      'Database query failed: $operation',
      originalError: originalError,
    );
  }

  static NetworkException connectionFailed({dynamic originalError}) {
    return NetworkException(
      'Network connection failed',
      originalError: originalError,
    );
  }

  static FileUploadException uploadFailed(
    String fileName,
    String reason, {
    dynamic originalError,
  }) {
    return FileUploadException(
      'Upload failed for $fileName: $reason',
      fileName: fileName,
      originalError: originalError,
    );
  }
}
