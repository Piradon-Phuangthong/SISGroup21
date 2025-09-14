import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/contact_model.dart';
import 'models/contact_channel_model.dart';

/// Utility functions for data formatting, validation, and helper operations
class UtilityService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Generate initials from a full name
  /// TODO: Implement intelligent initials generation
  static String generateContactInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '?';
    }

    final trimmed = fullName.trim();
    final words = trimmed.split(RegExp(r'\s+'));

    if (words.length == 1) {
      // Single word - take first character
      return words[0][0].toUpperCase();
    } else if (words.length >= 2) {
      // Multiple words - take first character of first and last word
      return '${words[0][0].toUpperCase()}${words[words.length - 1][0].toUpperCase()}';
    }

    return '?';
  }

  /// Format phone number for consistent display
  /// TODO: Implement phone number formatting
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Remove all non-numeric characters
    final numeric = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (numeric.isEmpty) return phone;

    // TODO: Add more sophisticated formatting based on country codes
    if (numeric.startsWith('+')) {
      // International format
      if (numeric.length >= 12) {
        // +1 234 567 8900 format
        return '${numeric.substring(0, 2)} ${numeric.substring(2, 5)} ${numeric.substring(5, 8)} ${numeric.substring(8)}';
      }
      return numeric;
    } else if (numeric.length == 10) {
      // US format: (234) 567-8900
      return '(${numeric.substring(0, 3)}) ${numeric.substring(3, 6)}-${numeric.substring(6)}';
    } else if (numeric.length == 11 && numeric.startsWith('1')) {
      // US format with country code: 1 (234) 567-8900
      return '1 (${numeric.substring(1, 4)}) ${numeric.substring(4, 7)}-${numeric.substring(7)}';
    }

    return phone; // Return original if we can't format
  }

  /// Validate email address format
  /// TODO: Implement comprehensive email validation
  static bool validateEmail(String? email) {
    if (email == null || email.isEmpty) return false;

    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Validate phone number format
  /// TODO: Implement phone number validation
  static bool validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;

    // Remove all non-numeric characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Must have at least 7 digits for a valid phone number
    final digitCount = cleaned.replaceAll('+', '').length;
    return digitCount >= 7 && digitCount <= 15;
  }

  /// Validate username format
  /// TODO: Implement username validation rules
  static bool validateUsername(String? username) {
    if (username == null || username.isEmpty) return false;

    final trimmed = username.trim().toLowerCase();

    // Username rules: 3-30 characters, alphanumeric + underscore, no spaces
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
    return usernameRegex.hasMatch(trimmed);
  }

  /// Parse and validate field mask array
  /// TODO: Implement field mask validation
  static List<String> parseFieldMask(List<dynamic>? mask) {
    if (mask == null) return [];

    return mask
        .where((field) => field is String && field.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// Get display name for contact with fallback logic
  /// TODO: Implement smart display name logic
  static String getContactDisplayName(ContactModel contact) {
    // Use the contact's built-in displayName getter
    return contact.displayName;
  }

  /// Get primary phone for contact
  /// TODO: Implement primary phone retrieval
  static String? getContactPrimaryPhone(
    ContactModel contact,
    List<ContactChannelModel>? channels,
  ) {
    // First check contact's primary mobile
    if (contact.primaryMobile?.isNotEmpty == true) {
      return contact.primaryMobile;
    }

    // Then check channels for primary phone/mobile
    if (channels != null) {
      for (final channel in channels) {
        if ((channel.kind == 'mobile' || channel.kind == 'phone') &&
            channel.isPrimary &&
            channel.value?.isNotEmpty == true) {
          return channel.value;
        }
      }

      // If no primary, get first phone/mobile channel
      for (final channel in channels) {
        if ((channel.kind == 'mobile' || channel.kind == 'phone') &&
            channel.value?.isNotEmpty == true) {
          return channel.value;
        }
      }
    }

    return null;
  }

  /// Get primary email for contact
  /// TODO: Implement primary email retrieval
  static String? getContactPrimaryEmail(
    ContactModel contact,
    List<ContactChannelModel>? channels,
  ) {
    // First check contact's primary email
    if (contact.primaryEmail?.isNotEmpty == true) {
      return contact.primaryEmail;
    }

    // Then check channels for primary email
    if (channels != null) {
      for (final channel in channels) {
        if (channel.kind == 'email' &&
            channel.isPrimary &&
            channel.value?.isNotEmpty == true) {
          return channel.value;
        }
      }

      // If no primary, get first email channel
      for (final channel in channels) {
        if (channel.kind == 'email' && channel.value?.isNotEmpty == true) {
          return channel.value;
        }
      }
    }

    return null;
  }

  /// Get avatar URL or path for contact
  /// TODO: Implement avatar handling
  static String? getContactAvatar(ContactModel contact) {
    return contact.avatarUrl;
  }

  /// Build display text for channel
  /// TODO: Implement channel display formatting
  static String buildChannelDisplayText(ContactChannelModel channel) {
    return channel.displayText;
  }

  /// Get appropriate icon for channel type
  /// TODO: Implement channel icon mapping
  static IconData getChannelIcon(String channelKind) {
    switch (channelKind.toLowerCase()) {
      case 'mobile':
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.telegram;
      case 'imessage':
        return Icons.message;
      case 'signal':
        return Icons.security;
      case 'wechat':
        return Icons.chat_bubble;
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.business;
      case 'github':
        return Icons.code;
      case 'x':
      case 'twitter':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      case 'tiktok':
        return Icons.video_library;
      case 'website':
        return Icons.web;
      case 'payid':
      case 'beem':
        return Icons.payment;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.contact_page;
    }
  }

  /// Build search query filters for contacts
  /// TODO: Implement search query building
  static Map<String, dynamic> buildContactSearchQuery({
    String? searchTerm,
    List<String>? tagIds,
    bool includeDeleted = false,
  }) {
    final filters = <String, dynamic>{};

    if (!includeDeleted) {
      filters['is_deleted'] = false;
    }

    // TODO: Add search term filtering logic
    if (searchTerm?.isNotEmpty == true) {
      filters['search_term'] = searchTerm;
    }

    // TODO: Add tag filtering logic
    if (tagIds?.isNotEmpty == true) {
      filters['tag_ids'] = tagIds;
    }

    return filters;
  }

  /// Generate a random color for contact avatars
  /// TODO: Implement consistent color generation
  static Color generateContactColor(String contactId) {
    // Use contact ID to generate consistent color
    final hash = contactId.hashCode;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    return colors[hash.abs() % colors.length];
  }

  /// Pick image from gallery or camera
  /// TODO: Implement image picking
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Compress and resize image
  /// TODO: Implement image compression
  static Future<File?> compressImage(File imageFile) async {
    try {
      // TODO: Implement image compression logic
      // For now, just return the original file
      return imageFile;
    } catch (e) {
      // TODO: Add proper error handling and logging
      return null;
    }
  }

  /// Convert file size to human readable format
  /// TODO: Implement file size formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clean and normalize text input
  /// TODO: Implement text cleaning
  static String? cleanText(String? text) {
    if (text == null) return null;
    final cleaned = text.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Generate a secure random string
  /// TODO: Implement secure random generation
  static String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;

    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }

    return result;
  }

  /// Debounce function calls
  /// TODO: Implement debouncing utility
  static void debounce({
    required String id,
    required Duration delay,
    required VoidCallback callback,
  }) {
    // TODO: Implement proper debouncing with timers
    // For now, just call the callback immediately
    callback();
  }

  /// Format date for display
  /// TODO: Implement date formatting
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Check if app is running in debug mode
  /// TODO: Implement debug mode detection
  static bool get isDebugMode {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }
}
