# Pages

This directory contains page-level components for the Omada Contacts app.

## Files

### Authentication & Profile Pages
- `splash_page.dart` - Initial loading screen with auth check and routing
- `login_page.dart` - Authentication page with sign-in and sign-up functionality
- `account_page.dart` - Account settings and auth management
  - View/edit username
  - View email
  - Sign out functionality
- `profile_management_page.dart` - Contact card management
  - Edit personal contact information
  - Manage contact channels
  - Configure sharing settings

## Navigation Flow

1. **Initial Flow**
   - App starts at `splash_page.dart`
   - Routes to `login_page.dart` if not authenticated
   - Routes to main app if authenticated

2. **Authentication**
   - `login_page.dart` handles both sign-in and sign-up
   - Supports email/password auth
   - Optional username during sign-up
   - Auto-generates unique username if not provided

3. **Main App Navigation**
   - Bottom navigation between main sections:
     1. Contacts List
     2. My Card (`profile_management_page.dart`)
     3. Account (`account_page.dart`)

## Implementation Details

These pages:
- Compose multiple widgets to create complete UI screens
- Handle page-level state management
- Interact with Supabase services for data and auth
- Manage navigation within their scope
- Implement proper loading states and error handling
- Follow material design principles