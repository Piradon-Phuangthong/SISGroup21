/// Central export file for all Supabase services
/// Import this file to access all service classes and models

// Core Supabase client
export 'supabase_client.dart';

// Authentication services
export 'auth_service.dart';

// Contact management services
export 'contact_service.dart';
export 'contact_channel_service.dart';
export 'tag_service.dart';

// Sharing and collaboration services
export 'sharing_service.dart';

// File and media services
export 'file_upload_service.dart';

// Utility services
export 'utility_service.dart';

// Data models
export 'models/profile_model.dart';
export 'models/contact_model.dart';
export 'models/contact_channel_model.dart';
export 'models/tag_model.dart';
export 'models/share_request_model.dart';
export 'models/contact_share_model.dart';

/// Example usage:
/// 
/// ```dart
/// import 'package:your_app/services/services.dart';
/// 
/// // Use any service or model
/// final contacts = await ContactService.getContacts(ownerId: userId);
/// final profile = await AuthService.getCurrentUserProfile();
/// ```
