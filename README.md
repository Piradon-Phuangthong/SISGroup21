# Omada Contacts App

A modern contact management application built with Flutter and Supabase.

## Features

### Authentication & Profiles
- Email/password authentication
- Optional custom username during signup
- Automatic unique username generation
- Profile management and account settings

### Contact Management (Epic 2 - ✅ Implemented)
- **View contacts**: List all your contacts with search and filtering
- **Add contacts**: Create new contacts with name, phone, and email
- **Edit contacts**: Update existing contact information
- **Delete contacts**: Soft-delete with undo functionality
- **Real-time sync**: Powered by Supabase with row-level security
- **Empty state**: Friendly UI when no contacts exist
- **Pull-to-refresh**: Update contact list with gesture

### Additional Features
- Personal contact card customization
- Contact sharing and visibility controls
- Tag-based organization (future epic)
- Multi-theme support with color palettes

## Getting Started

1. **Prerequisites**
   - Flutter SDK (see `pubspec.yaml` for version)
   - Supabase account and project
   - IDE with Flutter support (VS Code, Android Studio, etc.)

2. **Setup**
   ```bash
   # Clone the repository
   git clone [repository-url]
   cd SISGroup21

   # Install dependencies
   flutter pub get

   # Run the app
   flutter run
   ```

3. **Configuration**
   - The app uses Supabase for backend services
   - Authentication and database configuration is in `lib/supabase/supabase_instance.dart`

## App Structure

### Navigation
The app has three main sections:
1. **Contacts** - View and manage your contacts list
2. **My Card** - Edit your personal contact card and profile
3. **Account** - Manage authentication and account settings

### Key Pages
- `/` - Splash screen with auth check and dev routing
- `/login` - Authentication (sign in/up)
- `/app` - Main contacts screen with CRUD functionality
- `/profile` - Contact card management
- `/account` - Account settings
- `/dev-selector` - Development mode: choose between app and debug tools
- `/debug` - Test suite for database operations and epic validation

## Development

- Built with Flutter and Dart
- Uses Supabase for backend services
- Follows modern Flutter best practices
- Implements material design principles

### Development Tools
- **Debug Mode**: Run in debug to access `/dev-selector` for testing
- **Database Testing**: Use `/debug` route to test individual epics and features
- **Contact Seeding**: Use "E2 → Contacts CRUD → Seed 12 contacts" to populate test data

## Documentation

For detailed documentation about specific components:
- [Data Layer](lib/data/README.md)
- [Pages](lib/pages/README.md)
- [Widgets](lib/widgets/README.md)
- [Database](docs/database/schema_documentation.md)
