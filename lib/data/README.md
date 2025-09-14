# Data Layer Documentation

This directory contains the complete data access layer for the Omada Contacts app, providing safe and consistent interaction with the Supabase database.

## Architecture Overview

The data layer follows a layered architecture pattern:

```
┌─────────────────┐
│    Services     │  ← High-level business logic
├─────────────────┤
│  Repositories   │  ← Data access abstraction  
├─────────────────┤
│     Models      │  ← Data models & serialization
├─────────────────┤
│   Exceptions    │  ← Error handling
├─────────────────┤
│    Utils        │  ← Validation & utilities
└─────────────────┘
```

## Directory Structure

```
lib/data/
├── models/               # Data models that map to database tables
│   ├── profile_model.dart
│   ├── contact_model.dart
│   ├── contact_channel_model.dart
│   ├── tag_model.dart
│   ├── contact_tag_model.dart
│   ├── share_request_model.dart
│   ├── contact_share_model.dart
│   └── models.dart       # Barrel export
├── repositories/         # Data access layer
│   ├── base_repository.dart
│   ├── profile_repository.dart
│   ├── contact_repository.dart
│   ├── tag_repository.dart
│   ├── sharing_repository.dart
│   └── repositories.dart # Barrel export
├── services/            # Business logic layer
│   ├── auth_service.dart
│   ├── contact_service.dart
│   ├── tag_service.dart
│   ├── sharing_service.dart
│   └── services.dart    # Barrel export
├── exceptions/          # Custom exception handling
│   ├── data_exceptions.dart
│   └── exceptions.dart  # Barrel export
├── utils/              # Validation and utilities
│   ├── validation_utils.dart
│   ├── query_utils.dart
│   └── utils.dart      # Barrel export
├── data.dart           # Main barrel export
└── README.md           # This file
```

## Quick Start

### 1. Import the data layer

```dart
import 'package:omada/data/data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

### 2. Initialize services

```dart
final supabaseClient = Supabase.instance.client;

final authService = AuthService(supabaseClient);
final contactService = ContactService(supabaseClient);
final tagService = TagService(supabaseClient);
final sharingService = SharingService(supabaseClient);
```

### 3. Use the services

```dart
// Authentication
final user = await authService.signIn(
  email: 'user@example.com',
  password: 'password',
);

// Create a contact
final contact = await contactService.createContact(
  fullName: 'John Doe',
  primaryEmail: 'john@example.com',
  primaryMobile: '+1234567890',
);

// Add tags
final workTag = await tagService.createTag('Work');
await tagService.addTagToContact(contact.id, workTag.id);
```

## Core Components

### Models

Data models provide type-safe representations of database entities:

- **ProfileModel**: User profiles
- **ContactModel**: Contact information
- **ContactChannelModel**: Communication channels (phone, email, social media)
- **TagModel**: Contact organization tags
- **ShareRequestModel**: Contact sharing requests
- **ContactShareModel**: Active contact shares

Each model includes:
- JSON serialization/deserialization
- Validation helpers
- Computed properties
- Copy methods

### Repositories

Repositories handle direct database access with built-in error handling:

- **ProfileRepository**: User profile operations
- **ContactRepository**: Contact CRUD operations
- **TagRepository**: Tag management and associations
- **SharingRepository**: Contact sharing workflows

### Services

Services provide high-level business logic operations:

- **AuthService**: Authentication and user management
- **ContactService**: Contact management with enhanced features
- **TagService**: Tag operations with smart suggestions
- **SharingService**: Contact sharing workflows

### Exception Handling

Comprehensive exception hierarchy for different error types:

- **AuthException**: Authentication failures
- **ValidationException**: Data validation errors
- **NotFoundException**: Resource not found
- **ConflictException**: Duplicate resources
- **ForbiddenException**: Permission denied
- **DatabaseException**: Database operation failures

## Usage Examples

### Authentication

```dart
final authService = AuthService(supabaseClient);

// Sign up
try {
  final response = await authService.signUp(
    email: 'user@example.com',
    password: 'securePassword',
    username: 'johndoe',
  );
  print('User created: ${response.user?.email}');
} on AuthException catch (e) {
  print('Auth error: ${e.message}');
}

// Sign in
final response = await authService.signIn(
  email: 'user@example.com',
  password: 'securePassword',
);

// Check authentication status
if (authService.isAuthenticated) {
  final profile = await authService.currentProfile;
  print('Welcome, ${profile?.username}!');
}
```

### Contact Management

```dart
final contactService = ContactService(supabaseClient);

// Create a contact
final contact = await contactService.createContact(
  fullName: 'Alice Johnson',
  givenName: 'Alice',
  familyName: 'Johnson',
  primaryEmail: 'alice@example.com',
  primaryMobile: '+1-555-0123',
  notes: 'Met at conference',
  tagIds: [workTagId, conferenceTagId],
);

// Search contacts
final results = await contactService.searchContacts('Alice');

// Get contacts with specific tags
final workContacts = await contactService.getContactsByTag(workTagId);

// Update contact
final updatedContact = await contactService.updateContact(
  contact.id,
  notes: 'Updated notes',
  defaultCallApp: 'WhatsApp',
);
```

### Tag Management

```dart
final tagService = TagService(supabaseClient);

// Create tags
final workTag = await tagService.createTag('Work');
final friendsTag = await tagService.createTag('Friends');

// Get all tags
final allTags = await tagService.getTags();

// Tag a contact
await tagService.addTagToContact(contactId, workTag.id);

// Get contacts for a tag
final taggedContacts = await tagService.getContactsForTag(workTag.id);

// Get tag usage statistics
final stats = await tagService.getTagUsageStats();
for (final stat in stats) {
  print('${stat.name}: ${stat.contactCount} contacts');
}
```

### Contact Sharing

```dart
final sharingService = SharingService(supabaseClient);

// Send a share request
final request = await sharingService.sendShareRequest(
  recipientUsername: 'friend_username',
  message: 'Would like to share contact info',
);

// Accept a share request and choose what to share
await sharingService.acceptShareRequest(
  request.id,
  shareConfigs: [
    ContactShareConfig(
      contactId: contact.id,
      fieldMask: ContactFields.basic, // Name, phone, email only
    ),
  ],
);

// Get my shares
final myShares = await sharingService.getMyShares();

// Revoke a share
await sharingService.revokeContactShare(shareId);
```

## Error Handling

The data layer provides comprehensive error handling:

```dart
try {
  final contact = await contactService.createContact(
    fullName: 'Test User',
    primaryEmail: 'invalid-email', // This will fail validation
  );
} on ValidationException catch (e) {
  print('Validation error: ${e.message}');
  if (e.fieldErrors != null) {
    e.fieldErrors!.forEach((field, errors) {
      print('$field: ${errors.join(', ')}');
    });
  }
} on ConflictException catch (e) {
  print('Conflict: ${e.message}');
} on DatabaseException catch (e) {
  print('Database error: ${e.message}');
} on DataException catch (e) {
  print('General data error: ${e.message}');
}
```

## Validation

Built-in validation for data integrity:

```dart
// Email validation
if (ValidationUtils.isValidEmail('test@example.com')) {
  // Valid email
}

// Phone validation
if (ValidationUtils.isValidPhoneNumber('+1-555-0123')) {
  // Valid phone
}

// Username validation
try {
  ValidationUtils.validateUsername('valid_username');
} on ValidationException catch (e) {
  print('Invalid username: ${e.message}');
}

// Contact data validation
final errors = ValidationUtils.validateContactData(
  fullName: 'John Doe',
  primaryEmail: 'john@example.com',
);
if (errors.isNotEmpty) {
  // Handle validation errors
}
```

## Security Features

- **Row Level Security (RLS)**: All database operations respect Supabase RLS policies
- **Ownership Validation**: Users can only access their own data
- **Field-level Sharing**: Fine-grained control over shared contact fields
- **Authentication Checks**: All operations require valid authentication

## Best Practices

1. **Always handle exceptions**: Wrap service calls in try-catch blocks
2. **Use validation**: Validate data before sending to services
3. **Check authentication**: Verify user is authenticated before operations
4. **Clean up resources**: Properly dispose of streams and subscriptions
5. **Use appropriate service level**: Use services for business logic, repositories for direct data access

## Testing

The data layer is designed to be testable:

```dart
// Mock the Supabase client for testing
final mockClient = MockSupabaseClient();
final authService = AuthService(mockClient);

// Test service methods
test('should create contact successfully', () async {
  // Arrange
  when(mockClient.from('contacts')).thenReturn(mockQuery);
  
  // Act
  final contact = await contactService.createContact(
    fullName: 'Test User',
    primaryEmail: 'test@example.com',
  );
  
  // Assert
  expect(contact.fullName, equals('Test User'));
});
```

## Performance Considerations

- **Pagination**: Use limit/offset parameters for large datasets
- **Caching**: Consider implementing caching for frequently accessed data
- **Batch Operations**: Use bulk operations when working with multiple items
- **Query Optimization**: Use specific field selection when possible

## Database Schema

The data layer maps to these Supabase tables:

- `profiles`: User profiles
- `contacts`: Contact information
- `contact_channels`: Communication channels
- `tags`: Organization tags
- `contact_tags`: Many-to-many contact-tag relationships
- `share_requests`: Contact sharing requests
- `contact_shares`: Active contact shares

See `docs/database/supabase.cloud_schema.sql` for the complete schema.

## Contributing

When extending the data layer:

1. Add new models to `models/`
2. Create repositories for data access in `repositories/`
3. Build services for business logic in `services/`
4. Add custom exceptions as needed in `exceptions/`
5. Update this README with usage examples
6. Add tests for new functionality

## Migration Guide

When updating from previous data layer versions:

1. Update import paths to use the new barrel exports
2. Replace direct repository usage with service calls
3. Update exception handling to use the new exception hierarchy
4. Migrate validation logic to use `ValidationUtils`

For questions or issues, please refer to the project documentation or create an issue in the repository.
