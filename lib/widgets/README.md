# Widgets

This directory contains reusable UI components for the Omada Contacts app.

## Files

### Navigation Components
- `app_bottom_nav.dart` - Bottom navigation bar component
  - Manages navigation between main app sections:
    1. Contacts (icon: menu_book)
    2. My Card (icon: card_membership)
    3. Account (icon: account_circle)
  - Maintains navigation state
  - Handles route transitions

### Contact Management
- `contact_tile.dart` - List tile for displaying contact information
  - Displays contact avatar and basic info
  - Handles tap interactions
  - Supports various display states

### UI Components
- `custom_app_bar.dart` - Custom app bar component
  - Consistent app bar styling
  - Action button management
- `filter_row.dart` - Component for filtering lists
  - Tag-based filtering interface
  - Selection state management
- `theme_selector.dart` - Component for selecting app themes
  - Theme switching interface
  - Visual theme preview

## Implementation Details

These widgets are designed to:
- Encapsulate specific UI functionality
- Maintain consistent styling across the app
- Support composition into larger UI structures
- Improve code reusability and maintainability
- Follow material design principles

## Usage Examples

### Bottom Navigation
```dart
AppBottomNav(
  active: AppNav.contacts, // or .profile, .account
)
```

### Contact Tile
```dart
ContactTile(
  contact: contactModel,
  colorPalette: selectedTheme,
)
```

### Theme Selection
```dart
ThemeSelector(
  themes: allThemes,
  selectedTheme: currentTheme,
  onThemeChanged: handleThemeChange,
)
```