# Models

This directory contains data model classes that map to database tables in the Supabase backend for the Omada Contacts app.

## Files

- `profile_model.dart` - Represents user profile data
- `contact_model.dart` - Represents contact information
- `contact_channel_model.dart` - Represents communication channels for contacts
- `tag_model.dart` - Represents tags for categorizing contacts
- `contact_tag_model.dart` - Represents the many-to-many relationship between contacts and tags
- `share_request_model.dart` - Represents contact sharing requests between users
- `contact_share_model.dart` - Represents shared contact information
- `models.dart` - Barrel file that exports all models for convenient importing

## Usage

These model classes handle serialization and deserialization of data between the app and the database. They include:

- JSON conversion methods
- Data validation
- Relationship mapping

Models are primarily used by the repository layer to convert between database records and Dart objects.