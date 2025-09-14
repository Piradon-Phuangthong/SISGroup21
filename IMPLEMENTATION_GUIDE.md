# 🚀 Implementation Guide for Omada Contacts App

This guide tells you **what needs to be implemented** and **where to find the TODO markers** in your codebase. Each TODO comment in the service files contains detailed implementation instructions.

## 📋 Prerequisites

- Flutter SDK installed
- Supabase account created
- Basic understanding of Flutter and Dart

## 🏗️ Phase 1: Initial Setup (30 minutes)

### Step 1.1: Supabase Project Setup

**What to do:**
1. Create Supabase project at [supabase.com](https://supabase.com/dashboard)
2. Get Project URL and anon key from Settings > API
3. Run database schema from `docs/database/db_cloud.dbml` in SQL Editor
4. Create storage buckets: `contact-avatars` and `contact-attachments`
5. Enable realtime for all tables

**Where to update:**
- `lib/services/supabase_config.dart` - Replace URL and anon key placeholders

### Step 1.2: App Initialization

**What to implement:**
- Initialize Supabase in main.dart
- Add authentication check wrapper

**Where to find TODOs:**
- `lib/services/supabase_client.dart` - `initialize()` method
- `lib/main.dart` - Add Supabase initialization and auth wrapper

## 🔐 Phase 2: Authentication (2 hours)

### Step 2.1: AuthService Implementation

**What to implement:**
- User sign up with email/password
- Username availability checking
- Profile creation after signup
- User sign in
- Profile management

**Where to find TODOs:**
- `lib/services/auth_service.dart`:
  - `signUp()` - Complete user registration flow
  - `signIn()` - User authentication
  - `checkUsernameAvailability()` - Validate unique usernames
  - `getCurrentUserProfile()` - Fetch user profile
  - `_createUserProfile()` - Create profile record

### Step 2.2: Authentication UI

**What to create:**
- Sign in screen with email/password fields
- Sign up screen with username field
- Authentication state management in main app

**New files to create:**
- `lib/screens/auth/sign_in_screen.dart`
- `lib/screens/auth/sign_up_screen.dart`

## 📇 Phase 3: Contact Management (3 hours)

### Step 3.1: ContactService Implementation

**What to implement:**
- Create new contacts
- Fetch user's contacts with filtering
- Update contact information
- Soft delete contacts
- Search contacts by name/phone/email

**Where to find TODOs:**
- `lib/services/contact_service.dart`:
  - `createContact()` - Insert new contact
  - `getContacts()` - Query with filters and search
  - `updateContact()` - Update contact fields
  - `deleteContact()` - Soft delete functionality
  - `searchContacts()` - Full-text search implementation

### Step 3.2: Contact UI Updates

**What to update:**
- Modify existing `ContactsScreen` to use cloud data
- Create contact detail screen
- Add contact creation/editing forms

**Where to update:**
- `lib/screens/contacts_screen.dart` - Replace static data with service calls
- Create `lib/screens/contact_detail_screen.dart`
- Create `lib/screens/add_edit_contact_screen.dart`

## 📞 Phase 4: Contact Channels (2 hours)

### Step 4.1: ContactChannelService Implementation

**What to implement:**
- Add channels (phone, email, social, payments)
- Manage primary channel flags
- Update and delete channels
- Filter channels by type

**Where to find TODOs:**
- `lib/services/contact_channel_service.dart`:
  - `addContactChannel()` - Create new channels
  - `getContactChannels()` - Fetch channels for contact
  - `setPrimaryChannel()` - Manage primary flags
  - `getChannelsByType()` - Filter by channel type
  - `_unsetPrimaryChannels()` - Helper for primary management

### Step 4.2: Channel Management UI

**What to create:**
- Add channel screen with dropdown for types
- Channel list display in contact details
- Edit/delete channel functionality

**New files to create:**
- `lib/screens/add_channel_screen.dart`
- `lib/widgets/channel_list_widget.dart`

## 🏷️ Phase 5: Tag System (1.5 hours)

### Step 5.1: TagService Implementation

**What to implement:**
- Create and manage tags
- Apply tags to contacts
- Filter contacts by tags
- Bulk tag operations

**Where to find TODOs:**
- `lib/services/tag_service.dart`:
  - `createTag()` - Create user tags
  - `addTagToContact()` - Apply tag to contact
  - `getContactsByTags()` - Filter by multiple tags
  - `bulkAddTagsToContacts()` - Bulk operations

### Step 5.2: Tag UI Integration

**What to update:**
- Add tag management to contact details
- Update filter row to use cloud tags
- Create tag selection dialogs

**Where to update:**
- `lib/screens/contact_detail_screen.dart` - Add tag section
- `lib/widgets/filter_row.dart` - Use TagService instead of static data

## 🤝 Phase 6: Sharing System (4 hours)

### Step 6.1: SharingService Implementation

**What to implement:**
- Find users by username
- Send/receive share requests
- Grant contact access with field permissions
- Manage shared contacts

**Where to find TODOs:**
- `lib/services/sharing_service.dart`:
  - `findUserByUsername()` - User discovery
  - `sendShareRequest()` - Request sharing access
  - `respondToShareRequest()` - Accept/decline requests
  - `grantContactAccess()` - Share with field permissions
  - `getSharedContacts()` - View shared contacts

### Step 6.2: Sharing UI

**What to create:**
- User search screen for finding users to share with
- Share requests management screen
- Contact sharing permissions screen

**New files to create:**
- `lib/screens/user_search_screen.dart`
- `lib/screens/share_requests_screen.dart`
- `lib/screens/contact_sharing_screen.dart`

## 📁 Phase 7: File Upload (1 hour)

### Step 7.1: FileUploadService Implementation

**What to implement:**
- Upload contact avatars to Supabase Storage
- Handle file validation and compression
- Delete old files when updating

**Where to find TODOs:**
- `lib/services/file_upload_service.dart`:
  - `uploadContactAvatar()` - Upload to storage bucket
  - `updateContactAvatar()` - Replace existing avatar
  - `deleteFileFromUrl()` - Clean up old files

### Step 7.2: Avatar Functionality

**What to add:**
- Avatar upload in contact detail screen
- Image picker integration
- Avatar display throughout app

**Where to update:**
- Contact detail screen - Add avatar upload functionality
- Contact tiles - Display avatars from cloud

## 🔒 Phase 8: Security Setup (1 hour)

### Step 8.1: Row Level Security (RLS)

**What to implement:**
- Enable RLS on all tables
- Create policies for data access control
- Test security rules

**Where to implement:**
- Supabase SQL Editor - Run RLS policies from `lib/services/supabase_config.dart`
- Test with different users to verify isolation

## 🎯 Phase 9: Testing & Debugging (2 hours)

### Step 9.1: Test Infrastructure

**What to create:**
- Test data creation helpers
- Debug tools and screens
- Error logging service

**New files to create:**
- `lib/utils/test_data.dart` - Test data helpers
- `lib/screens/debug_screen.dart` - Debug tools
- `lib/services/error_service.dart` - Error handling

### Step 9.2: Implementation Testing

**What to test:**
- All service methods work correctly
- UI screens load and function properly
- Authentication flow works end-to-end
- Sharing system functions correctly

## 🚀 Phase 10: Production Polish (1 hour)

### Step 10.1: Error Handling

**What to implement:**
- Comprehensive error handling in all services
- User-friendly error messages
- Loading states in UI

**Where to update:**
- All service files - Improve error handling in catch blocks
- All UI screens - Add loading indicators and error states

### Step 10.2: Performance Optimization

**What to optimize:**
- Add caching where appropriate
- Implement pull-to-refresh
- Optimize database queries

## 📊 Implementation Priority Order

| Priority | Component | Time | Complexity |
|----------|-----------|------|------------|
| 1 | Setup & Auth | 2.5h | Medium |
| 2 | Contact Management | 3h | Medium |
| 3 | Contact Channels | 2h | Easy |
| 4 | Tag System | 1.5h | Easy |
| 5 | File Upload | 1h | Easy |
| 6 | Sharing System | 4h | Hard |
| 7 | Security & Testing | 3h | Medium |
| 8 | Polish | 1h | Easy |

## 🔍 How to Follow TODOs

1. **Search for TODO comments** in each service file
2. **Read the detailed instructions** in each TODO
3. **Implement the functionality** as described
4. **Test each service method** before moving to the next
5. **Update UI screens** to use the implemented services

## ✅ Completion Checklist

### Database & Setup
- [ ] Supabase project configured
- [ ] Database schema deployed
- [ ] Storage buckets created
- [ ] RLS policies applied

### Service Implementation (Complete all TODOs)
- [ ] `AuthService` - All 7 TODO methods
- [ ] `ContactService` - All 8 TODO methods  
- [ ] `ContactChannelService` - All 9 TODO methods
- [ ] `TagService` - All 12 TODO methods
- [ ] `SharingService` - All 15 TODO methods
- [ ] `FileUploadService` - All 10 TODO methods
- [ ] `UtilityService` - All 15 TODO methods

### UI Implementation
- [ ] Authentication screens created
- [ ] Contact management updated
- [ ] Channel management UI added
- [ ] Tag system integrated
- [ ] Sharing screens created
- [ ] File upload integrated

### Testing & Production
- [ ] Test data helpers created
- [ ] Debug tools implemented
- [ ] Error handling added
- [ ] Loading states implemented
- [ ] App fully functional

## 🎯 Next Steps After Implementation

1. **Test thoroughly** with multiple users
2. **Add offline support** for better UX
3. **Implement push notifications** for share requests
4. **Add analytics and monitoring**
5. **Optimize performance** for large contact lists
6. **Add advanced features** like contact import/export

Remember: Each TODO comment contains specific implementation details. Follow them systematically for best results!
