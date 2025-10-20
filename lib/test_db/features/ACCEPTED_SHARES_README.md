# Accepted Shares Test Page

## Overview
A debug menu page that shows everyone who has accepted your share requests along with the specific channels they have been granted access to.

## Location
`lib/test_db/features/accepted_shares_test_page.dart`

## Access Path
1. Run the app in debug mode
2. Navigate to `/debug` or use "Open DB Debug (Test Suite)" from the dev selector
3. Go to **E5 — Username Discovery & Requests**
4. Select **"US-E5-4: Accepted Shares (with Channels)"**

## Features

### Display Information
- **Recipient Profile**: Shows username, full name, and avatar
- **Acceptance Status**: Displays "ACCEPTED" badge for active shares
- **Contact Name**: Shows which contact is being shared
- **Channel Access Level**: 
  - "All Channels" if the share includes the legacy `"channels"` field mask
  - "X Channel(s)" if specific channels are shared using `"channel:{uuid}"` format

### Channel Details
For each accepted share, the page displays:
- List of all allowed channels with their:
  - Type icon (email, phone, WhatsApp, etc.)
  - Label
  - Value
- Empty state if no channels are shared
- Visual distinction between "all channels" and "specific channels"

### Technical Details
- Query: `contact_shares` table where `owner_id = current_user` and `revoked_at IS NULL`
- Joins: `profiles` (recipient info) and `contacts` (contact name)
- Channel filtering: Uses `ContactShareModel.sharesAllChannels` and `sharedChannelIds` to determine allowed channels
- Real-time loading with error handling and retry capability

## Data Structure

### _ShareRecipientInfo
Internal model that combines:
- `ContactShareModel` - The share record
- Recipient profile info (username, full name, avatar)
- Contact name
- List of allowed `ContactChannelModel` objects
- Boolean flag for "shares all channels"

## Channel Icons
The page displays contextual icons for different channel types:
- 📧 Email
- 📱 Phone/Mobile
- 💬 WhatsApp
- ✈️ Telegram
- 📷 Instagram
- 💼 LinkedIn
- 📄 Other/Generic

## Field Mask Support
The page fully supports the channel-level field mask specification:
- **Legacy format**: `["channels"]` - All channels shared
- **Granular format**: `["channel:{uuid1}", "channel:{uuid2}"]` - Specific channels shared
- See `docs/field_mask.md` for full specification

## Debug Output
The page logs to console:
- Total number of recipients found
- Each recipient's username and allowed channel count
- Raw query response for troubleshooting
- Detailed error messages with stack traces

## Error Handling
- Shows loading spinner during data fetch
- Displays friendly error message if query fails
- Provides retry button
- Shows empty state when no accepted shares exist

## Use Cases
1. **Verify sharing flow**: Confirm that accepted share requests create proper contact_shares records
2. **Test RLS policies**: Ensure the query returns expected data based on RLS rules
3. **Debug channel filtering**: Verify field_mask is correctly filtering channels
4. **Monitor share status**: See all active shares at a glance
5. **Validate UI data**: Check what data will appear in the production contacts screen

## Related Files
- `lib/core/data/models/contact_share_model.dart` - Share data model with field mask helpers
- `lib/core/data/repositories/contact_repository.dart` - Repository for fetching shared contacts
- `lib/core/data/repositories/contact_channel_repository.dart` - Repository for fetching channels
- `docs/database/sharing_rls_policies.sql` - RLS policies enabling the queries
- `docs/field_mask.md` - Field mask specification
