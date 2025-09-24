# UI Pages

This directory contains the main pages and screens of the Omada Contacts app.

## Main Pages

- `account_page.dart` - User account management page
- `contact_form_page.dart` - Form for creating and editing contacts
- `contacts_screen.dart` - Main contacts listing and management screen
- `login_page.dart` - Authentication page
- `profile_management_page.dart` - Profile editing and management page
- `splash_page.dart` - Initial loading screen

## Subdirectories

- `contacts/` - Components for contacts functionality (requests, tags, discovery)
- `profile/` - Profile page components (sections, avatar, channels)

## Architecture

Pages are organized to separate business logic from UI presentation. They typically use controllers from the core directory to manage state and data operations.