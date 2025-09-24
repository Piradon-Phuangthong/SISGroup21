# Pages

This directory contains page-level components for the Omada Contacts app.

## Files

### Authentication & Profile Pages
- `splash_page.dart` - Initial loading screen with auth check and routing
  - Routes to `/dev-selector` in debug mode, `/app` in release
  - Validates Supabase session on startup
- `login_page.dart` - Authentication page with sign-in and sign-up functionality
- `account_page.dart` - Account settings and auth management
  - View/edit username
  - View email
  - Sign out functionality
- `profile_management_page.dart` - Contact card management
  - Edit personal contact information
  - Manage contact channels
  - Configure sharing settings

### Contact Management Pages
- `contact_form_page.dart` - Create and edit contacts
  - Form validation using `ValidationUtils`
  - Supports both create and edit modes
  - Required: name fields + phone, optional: email
  - Real-time validation with error display

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
     1. Contacts List (with CRUD functionality)
     2. My Card (`profile_management_page.dart`)
     3. Account (`account_page.dart`)
   - Modal navigation for contact management:
     - Add contact: FAB → `contact_form_page.dart`
     - Edit contact: Tap/menu → `contact_form_page.dart` with existing contact

4. **Development Navigation** (debug mode only)
   - `splash_page.dart` → `/dev-selector` for route choice
   - `/dev-selector` → `/app` (main app) or `/debug` (test suite)
   - `/debug` → Epic-based testing including contact seeding

## Implementation Details

These pages:
- Compose multiple widgets to create complete UI screens
- Handle page-level state management
- Interact with Supabase services for data and auth
- Manage navigation within their scope
- Implement proper loading states and error handling
- Follow material design principles