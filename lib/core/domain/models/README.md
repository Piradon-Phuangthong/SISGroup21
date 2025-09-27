# Models

This directory contains model classes used in the UI layer of the Omada Contacts app.

## Files

- `contact.dart` - UI model for contact information
- `tag.dart` - UI model for tag information

## Usage

These model classes are used by the UI components and differ from the data models in the data layer. They:

- Provide a simplified view of data for UI components
- May combine information from multiple data models
- Include UI-specific properties and methods

Note that these models are separate from the data models in `lib/data/models/` which are used for database operations.