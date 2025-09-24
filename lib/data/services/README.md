# Services

This directory contains service classes that implement business logic for the Omada Contacts app.

## Files

- `auth_service.dart` - Handles authentication and user management
- `contact_service.dart` - Manages contact operations and business rules
- `tag_service.dart` - Manages tag operations and categorization logic
- `sharing_service.dart` - Handles contact sharing functionality
- `services.dart` - Barrel file that exports all services

## Usage

Services represent the highest layer in the data access architecture and implement business logic by:

- Coordinating operations across multiple repositories
- Enforcing business rules and validation
- Handling complex operations that span multiple data entities
- Providing a clean API for UI components

UI components should interact with the data layer exclusively through these service classes rather than directly accessing repositories.