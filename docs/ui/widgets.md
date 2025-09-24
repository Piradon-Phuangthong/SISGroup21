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
  - Uses `ContactModel` from data layer
  - Displays contact avatar (generated from `ContactModel.initials`)
  - Shows display name and primary contact method
  - Renders color-coded tag chips under each contact
  - Chips are tappable to toggle tag filtering on the list
  - Popup menu for edit/delete actions
  - Color-coded avatars using theme palette

### Channel Management
- `add_channel_sheet.dart` - Bottom sheet to add a contact channel with presets
  - Preset kinds: mobile, email, instagram, linkedin, whatsapp, messenger
  - Auto-computes a read-only URL preview per kind (e.g., wa.me, m.me, instagram)
  - Validates basic input and shows progress while saving

### UI Components
- `custom_app_bar.dart` - Custom app bar component
  - Consistent app bar styling
  - Action button management
- `filter_row.dart` - Component for filtering lists
  - Tag-based filtering interface
  - Multi-select tags; passes the selected set upstream
  - Intended for use above lists (e.g., contacts list)
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

The channel add sheet works together with the utilities in `lib/data/utils/channel_presets.dart` and the launcher in `lib/data/utils/channel_launcher.dart`.

## Usage Examples

### Contact Tile
```dart
ContactTile(
  contact: contactModel,
  colorPalette: selectedTheme,
  tags: contactTags,
  onTagTap: (tag) => toggleFilterForTag(tag.id),
  onTap: () => editContact(contactModel),
  onEdit: () => editContact(contactModel),
  onDelete: () => deleteContact(contactModel),
)
```

### Filter Row
```dart
FilterRow(
  tags: allTags,                      // List<TagModel>
  selectedTagIds: selectedTagIds,     // Set<String>
  colorPalette: selectedTheme,
  onTagToggle: (tag) => toggle(tag.id),
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