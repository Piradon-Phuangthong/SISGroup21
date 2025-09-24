# Repositories

This directory contains repository classes that provide a clean API for data access operations in the Omada Contacts app.

## Files

- `base_repository.dart` - Abstract base class with common functionality for all repositories
- `profile_repository.dart` - Handles user profile data operations
- `contact_repository.dart` - Handles contact data operations
- `tag_repository.dart` - Handles tag data operations
- `contact_channel_repository.dart` - Handles contact communication channel operations
- `sharing_repository.dart` - Handles contact sharing operations
- `repositories.dart` - Barrel file that exports all repositories

## Usage

Repositories serve as an abstraction layer between the data sources (Supabase) and the business logic. They:

- Handle CRUD operations for their respective data models
- Manage data caching when appropriate
- Convert between database records and model objects
- Handle database-specific error conditions

Repositories are typically used by the service layer, which implements higher-level business logic.