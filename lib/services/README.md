# Supabase Services Documentation

This folder contains all the Supabase integration services and models for the Omada contacts app. All functions are marked with TODO comments for implementation.

## 📁 Folder Structure

```
lib/services/
├── models/                     # Data models matching cloud schema
│   ├── profile_model.dart     # User profile model
│   ├── contact_model.dart     # Contact model with full schema
│   ├── contact_channel_model.dart  # Channels (phone/email/social/etc.)
│   ├── tag_model.dart         # Tag and contact-tag models
│   ├── share_request_model.dart    # Share request model
│   └── contact_share_model.dart    # Contact sharing permissions
├── auth_service.dart          # Authentication & user management
├── contact_service.dart       # Contact CRUD operations
├── contact_channel_service.dart    # Channel management
├── tag_service.dart          # Tag system operations
├── sharing_service.dart      # Contact sharing & permissions
├── file_upload_service.dart  # File upload to Supabase Storage
├── utility_service.dart      # Helper functions & utilities
├── supabase_client.dart      # Centralized Supabase client
├── supabase_config.dart      # Configuration & setup guide
├── services.dart             # Central export file
└── README.md                 # This file
```

## 🚀 Quick Start

### 1. Install Dependencies

The required dependencies are already added to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.5.6
  image_picker: ^1.0.7
  uuid: ^4.3.3
```

Run: `flutter pub get`

### 2. Set Up Supabase Project

1. Create a new project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key
3. Update `lib/services/supabase_config.dart` with your credentials

### 3. Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Supabase
  await SupabaseClientService.initialize();
  
  runApp(MyApp());
}
```

### 4. Import Services

```dart
import 'package:your_app/services/services.dart';

// Now you can use any service:
final contacts = await ContactService.getContacts(ownerId: userId);
final profile = await AuthService.getCurrentUserProfile();
```

## 📋 Implementation Checklist

### Database Setup
- [ ] Create Supabase project
- [ ] Run database migration (see `docs/database/`)
- [ ] Set up Row Level Security (RLS) policies
- [ ] Create storage buckets for avatars and attachments
- [ ] Configure real-time subscriptions

### Service Implementation
- [ ] **Authentication Service** - Sign up, sign in, profile management
- [ ] **Contact Service** - CRUD operations for contacts
- [ ] **Channel Service** - Manage phones, emails, socials, payments
- [ ] **Tag Service** - Create and apply tags to contacts
- [ ] **Sharing Service** - Username-based sharing and permissions
- [ ] **File Upload Service** - Avatar and attachment uploads
- [ ] **Utility Service** - Helper functions and formatting

### Models Implementation
- [ ] **ProfileModel** - User profile with username
- [ ] **ContactModel** - Full contact with all fields
- [ ] **ContactChannelModel** - Unified channels model
- [ ] **TagModel & ContactTagModel** - Tag system models
- [ ] **ShareRequestModel** - Sharing handshake model
- [ ] **ContactShareModel** - Permission-based sharing

## 🔧 Service Details

### AuthService
Handles user authentication and profile management.

**Key Methods:**
- `signUp()` - Create new user account
- `signIn()` - Authenticate user
- `getCurrentUserProfile()` - Get user profile
- `checkUsernameAvailability()` - Validate usernames

### ContactService
Manages contact CRUD operations.

**Key Methods:**
- `createContact()` - Create new contact
- `getContacts()` - Fetch user's contacts
- `updateContact()` - Update contact information
- `deleteContact()` - Soft delete contact
- `searchContacts()` - Search across contact fields

### ContactChannelService
Handles phones, emails, social media, payments, etc.

**Key Methods:**
- `addContactChannel()` - Add new channel
- `getContactChannels()` - Get all channels for contact
- `setPrimaryChannel()` - Set primary for channel type
- `getChannelsByType()` - Filter by channel type

### TagService
Manages the tag system for organizing contacts.

**Key Methods:**
- `createTag()` - Create new tag
- `addTagToContact()` - Apply tag to contact
- `getContactsByTags()` - Filter contacts by tags
- `bulkAddTagsToContacts()` - Bulk operations

### SharingService
Implements username-based contact sharing.

**Key Methods:**
- `findUserByUsername()` - Search users for sharing
- `sendShareRequest()` - Request access to share
- `grantContactAccess()` - Grant specific field access
- `getSharedContacts()` - Get contacts shared with user

### FileUploadService
Handles file uploads to Supabase Storage.

**Key Methods:**
- `uploadContactAvatar()` - Upload profile pictures
- `uploadAttachment()` - Upload files
- `deleteFileFromUrl()` - Clean up files

### UtilityService
Helper functions for formatting and validation.

**Key Methods:**
- `generateContactInitials()` - Create display initials
- `formatPhoneNumber()` - Format phone numbers
- `validateEmail()` - Email validation
- `getChannelIcon()` - Get appropriate icons

## 🔒 Security Notes

All services include TODO markers for:
- Row Level Security (RLS) policy enforcement
- Input validation and sanitization
- Error handling and logging
- Authentication checks

## 📱 Usage Examples

### Creating a Contact
```dart
final contact = await ContactService.createContact(
  ownerId: currentUserId,
  fullName: 'John Doe',
  primaryMobile: '+1234567890',
  primaryEmail: 'john@example.com',
);
```

### Adding Channels
```dart
await ContactChannelService.addContactChannel(
  ownerId: currentUserId,
  contactId: contact.id,
  kind: 'whatsapp',
  value: '+1234567890',
  isPrimary: true,
);
```

### Sharing Contacts
```dart
// Find user
final user = await SharingService.findUserByUsername('jane_doe');

// Send request
await SharingService.sendShareRequest(
  requesterId: currentUserId,
  recipientId: user.id,
  message: 'Let\'s share contacts!',
);

// Grant access (after acceptance)
await SharingService.grantContactAccess(
  ownerId: currentUserId,
  toUserId: user.id,
  contactId: contact.id,
  fieldMask: ['full_name', 'primary_mobile', 'channels'],
);
```

## 🔄 Real-time Features

Several services include real-time subscription methods:
- `ContactService.subscribeToContacts()`
- `SharingService.subscribeToIncomingRequests()`
- `ContactChannelService.subscribeToContactChannels()`

## 🎯 Next Steps

1. Set up your Supabase project and update configuration
2. Implement the TODO functions starting with authentication
3. Test each service independently
4. Add proper error handling and logging
5. Implement the UI screens to use these services
6. Add real-time subscriptions for live updates
7. Optimize with caching and offline support

## 📚 Additional Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart)
- [Database Schema Documentation](../docs/database/schema_documentation.md)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
