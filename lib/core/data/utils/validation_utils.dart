import '../exceptions/exceptions.dart';

/// Utility class for data validation
class ValidationUtils {
  /// Validates an email address
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates a phone number (basic validation)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    // Remove common formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // Should be between 7 and 15 digits
    final phoneRegex = RegExp(r'^\d{7,15}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  /// Validates a username
  static bool isValidUsername(String username) {
    if (username.isEmpty || username.length < 3 || username.length > 30) {
      return false;
    }
    // Only alphanumeric characters and underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  /// Validates a tag name
  static bool isValidTagName(String tagName) {
    if (tagName.isEmpty || tagName.length > 50) {
      return false;
    }
    // Allow letters, numbers, spaces, and common punctuation
    final tagRegex = RegExp(r'^[a-zA-Z0-9\s\-_.,!?()]+$');
    return tagRegex.hasMatch(tagName.trim());
  }

  /// Validates a contact name
  static bool isValidContactName(String name) {
    if (name.isEmpty || name.length > 100) {
      return false;
    }
    // Allow letters, spaces, apostrophes, hyphens, and dots
    final nameRegex = RegExp(r"^[a-zA-Z\s'\-\.]+$");
    return nameRegex.hasMatch(name.trim());
  }

  /// Validates a URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validates contact data and returns validation errors
  static Map<String, List<String>> validateContactData({
    String? fullName,
    String? givenName,
    String? familyName,
    String? primaryEmail,
    String? primaryMobile,
    bool allowNameOnly = false, // <-- NEW
  }) {
    final errors = <String, List<String>>{};

    if (!allowNameOnly) {
      if ((primaryEmail?.trim().isEmpty ?? true) &&
          (primaryMobile?.trim().isEmpty ?? true)) {
        errors['contact'] = ['At least email or phone number must be provided'];
      }
    }
    
    // At least one name field should be provided
    if ((fullName?.trim().isEmpty ?? true) &&
        (givenName?.trim().isEmpty ?? true) &&
        (familyName?.trim().isEmpty ?? true)) {
      errors['name'] = ['At least one name field must be provided'];
    }

    // Validate individual name fields
    if (fullName?.isNotEmpty == true && !isValidContactName(fullName!)) {
      errors['fullName'] = ['Invalid full name format'];
    }
    if (givenName?.isNotEmpty == true && !isValidContactName(givenName!)) {
      errors['givenName'] = ['Invalid given name format'];
    }
    if (familyName?.isNotEmpty == true && !isValidContactName(familyName!)) {
      errors['familyName'] = ['Invalid family name format'];
    }

    // Validate email if provided
    if (primaryEmail?.isNotEmpty == true && !isValidEmail(primaryEmail!)) {
      errors['primaryEmail'] = ['Invalid email format'];
    }

    // Validate phone if provided
    if (primaryMobile?.isNotEmpty == true &&
        !isValidPhoneNumber(primaryMobile!)) {
      errors['primaryMobile'] = ['Invalid phone number format'];
    }

    

    return errors;
  }

  /// Validates tag data
  static void validateTag(String tagName) {
    if (!isValidTagName(tagName)) {
      throw ValidationException(
        'Invalid tag name: must be 1-50 characters and contain only letters, numbers, spaces, and common punctuation',
      );
    }
  }

  /// Validates username
  static void validateUsername(String username) {
    if (!isValidUsername(username)) {
      throw ValidationException(
        'Invalid username: must be 3-30 characters and contain only letters, numbers, and underscores',
      );
    }
  }

  /// Validates contact channel data
  static Map<String, List<String>> validateContactChannel({
    required String kind,
    String? value,
    String? url,
  }) {
    final errors = <String, List<String>>{};

    if (kind.isEmpty) {
      errors['kind'] = ['Channel kind is required'];
    }

    // Validate based on channel kind
    switch (kind.toLowerCase()) {
      case 'email':
        if (value?.isNotEmpty == true && !isValidEmail(value!)) {
          errors['value'] = ['Invalid email format'];
        }
        break;
      case 'phone':
        if (value?.isNotEmpty == true && !isValidPhoneNumber(value!)) {
          errors['value'] = ['Invalid phone number format'];
        }
        break;
      case 'website':
        if (url?.isNotEmpty == true && !isValidUrl(url!)) {
          errors['url'] = ['Invalid URL format'];
        }
        break;
    }

    // At least value or URL should be provided
    if ((value?.trim().isEmpty ?? true) && (url?.trim().isEmpty ?? true)) {
      errors['content'] = ['Either value or URL must be provided'];
    }

    return errors;
  }

  /// Validates share request data
  static Map<String, List<String>> validateShareRequest({String? message}) {
    final errors = <String, List<String>>{};

    if (message?.isNotEmpty == true && message!.length > 500) {
      errors['message'] = ['Message cannot exceed 500 characters'];
    }

    return errors;
  }

  /// Sanitizes a string by trimming whitespace and removing excessive spaces
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Normalizes a phone number by removing formatting
  static String normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }

  /// Normalizes an email address by converting to lowercase
  static String normalizeEmail(String email) {
    return email.toLowerCase().trim();
  }

  /// Generates initials from a name
  static String generateInitials(String name) {
    if (name.isEmpty) return '??';

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.length >= 2
          ? words.first.substring(0, 2).toUpperCase()
          : words.first.toUpperCase();
    }

    return words
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .where((initial) => initial.isNotEmpty)
        .join();
  }
}
