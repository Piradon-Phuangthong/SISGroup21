# Features

This directory contains test pages for various features of the Omada Contacts app.

## Files

- `accepted_shares_test_page.dart` - Shows all users who accepted share requests with their allowed channels
- `received_shares_test_page.dart` - Shows all contacts shared WITH YOU and what channels you can access
- `auth_test_page.dart` - Tests for authentication functionality
- `contacts_test_page.dart` - Tests for contact management features
- `dummy_user_wizard_page.dart` - Wizard for creating test users
- `my_channels_page.dart` - Tests for communication channels
- `my_contact_card_page.dart` - Tests for contact card display
- `my_overview_page.dart` - Overview of test features
- `profiles_test_page.dart` - Tests for profile management
- `sharing_test_page.dart` - Tests for contact sharing functionality
- `tag_assignment_test_page.dart` - Tests for assigning tags to contacts
- `tags_test_page.dart` - Tests for tag management

## Usage

These test pages provide a way to manually test and verify different features of the application during development. They allow developers to interact with specific functionality in isolation.

## Sharing Test Pages

### Accepted Shares (Outgoing)
The `accepted_shares_test_page.dart` shows shares YOU gave to others:
- Who accepted your share requests (recipients)
- Which contacts you shared with them
- What channels they have access to
- Field mask support for granular sharing

### Received Shares (Incoming)
The `received_shares_test_page.dart` shows shares RECEIVED from others:
- Contacts that others have shared with you
- Who shared each contact (owner)
- Which channels YOU have access to from each contact
- Visual distinction between "all channels" and specific channel access

See `ACCEPTED_SHARES_README.md` for detailed documentation on the sharing feature.