# Screens

This directory contains screen components for the Omada Contacts app.

## Files

- `contacts_screen.dart` - Main contacts list and management screen
  - **CRUD**: Full create, read, update, delete operations
  - **Data Loading**: Fetches contacts from Supabase via `ContactService`
  - **UI States**: Loading, error, empty, and populated states
  - **Interactions**: Pull-to-refresh, add FAB, edit/delete menu
  - **Theme Support**: Dynamic theming with color palette selector
  - **Undo Functionality**: Soft-delete with snackbar undo action
  - **Epic 4 Enhancements**:
    - Debounced search field with clear button
    - Tag filter row (multi-select) using `FilterRow`
    - Manage Tags bottom sheet (create/delete tags)
    - Displays color-coded tag chips per contact
    - Tapping a tag chip toggles its filter in the list

## Usage

Screens are similar to pages but may represent a specific functional area within the app rather than a full navigation destination. They:

- Compose multiple widgets to create functional UI areas
- Handle screen-level state management
- May be embedded within pages or used as standalone navigation destinations
- Manage real-time data synchronization with backend services
- Implement user feedback patterns (loading, error, success states)