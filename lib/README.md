# Omada Contacts App

This directory contains the source code for the Omada Contacts app, a contact management application built with Flutter and Supabase.

## Directory Structure:

- `data/` - Data layer including models, repositories, and services
  - `exceptions/` - Custom exception classes
  - `models/` - Data models for database entities
  - `repositories/` - Data access layer
  - `services/` - Business logic layer
  - `utils/` - Utility functions and helpers

- `models/` - UI models used by the presentation layer

- `pages/` - Full-screen UI components

- `screens/` - Functional screen areas

- `supabase/` - Supabase client configuration

- `test_db/` - Test application for database functionality
  - `epics/` - Epic components for testing
  - `features/` - Feature test pages

- `themes/` - App theming and styling

- `widgets/` - Reusable UI components

- `main.dart` - Application entry point

## Architecture

The application follows a layered architecture:

1. **Data Layer** - Handles data access and business logic
2. **Presentation Layer** - UI components and state management

The data layer is further divided into:
- Models - Data structures
- Repositories - Data access
- Services - Business logic

The presentation layer consists of:
- Pages - Full screens
- Screens - Functional areas
- Widgets - Reusable components

## Omadas: Added vs Not Added and Requests

- In an Omada's details page, a new "Add" tab lists users who are not yet members of the Omada.
- You can search by username and tap the Request button to invite a user to join.
- The Members tab shows who you've already added.
- The Requests tab lists incoming join requests for the Omada (moderator+ can approve/reject).

Technical notes:
- Service methods live in `core/data/services/omada_service_extended.dart`:
  - `getOmadaMemberships(omadaId)` — current members
  - `getNonMembers(omadaId, {search, limit})` — profiles not yet in the Omada
  - `inviteUserToOmada(omadaId, targetUserId, {message})` — creates an invite via `omada_requests` (type='invite')
  - Existing `requestToJoin()` continues to support user-initiated join requests (type='join').

## Channel-level Sharing (Field Mask Spec)

- Field mask lives in `contact_shares.field_mask` as a JSON array of strings.
- Standard fields: `full_name`, `given_name`, `family_name`, `primary_email`, `primary_mobile`, etc.
- Channel-level entries use the form: `channel:{channel-uuid}`.
- Backward compatibility: If the array contains `"channels"` (without a UUID), treat it as "all channels" are shared.
- Enforcement:
  - Builders: `SharingService.acceptShareRequestWithChannels()` writes `channel:{uuid}` entries.
  - Model: `ContactShareModel` exposes `sharedChannelIds`, `includesChannel()`, and `sharesAllChannels`.
  - Repo: `ContactChannelRepository.getSharedChannelsForContact()` filters channels based on the mask.