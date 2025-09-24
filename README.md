# Omada Contacts App

A modern contact management application built with Flutter and Supabase.

## Features

### Authentication & Profiles
- Email/password authentication
- Optional custom username during signup
- Automatic unique username generation
- Profile management and account settings

### Contact Management
- View and manage your contacts
- Personal contact card customization
- Contact sharing and visibility controls
- Tag-based organization

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
- `/` - Splash screen with auth check
- `/login` - Authentication (sign in/up)
- `/app` - Main contacts screen
- `/profile` - Contact card management
- `/account` - Account settings

## Development

- Built with Flutter and Dart
- Uses Supabase for backend services
- Follows modern Flutter best practices
- Implements material design principles

## Documentation

For detailed documentation about specific components:
- [Data Layer](lib/data/README.md)
- [Pages](lib/pages/README.md)
- [Widgets](lib/widgets/README.md)
- [Database](docs/database/schema_documentation.md)
