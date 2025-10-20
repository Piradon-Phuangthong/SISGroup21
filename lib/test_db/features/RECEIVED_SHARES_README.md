# Received Shares Test Page

## Overview
A debug menu page that shows all contacts that have been shared WITH YOU (where you are the recipient) along with the specific channels you have been granted access to.

## Location
`lib/test_db/features/received_shares_test_page.dart`

## Access Path
1. Run the app in debug mode
2. Navigate to `/debug` or use "Open DB Debug (Test Suite)" from the dev selector
3. Go to **E5 — Username Discovery & Requests**
4. Select **"US-E5-5: Received Shares (My Access)"**

## Purpose
This page answers the question: **"What contacts have been shared with me, and what can I see?"**

This is the OPPOSITE of the Accepted Shares page:
- **Accepted Shares** = Contacts YOU shared with others (you are the owner)
- **Received Shares** = Contacts others shared with YOU (you are the recipient)

## Features

### Display Information
- **Contact Card**: Shows the shared contact's name with a prominent avatar
- **Owner Info**: Displays who shared this contact with you (their username)
- **Status Badge**: Shows "RECEIVED" in purple to indicate this is an incoming share
- **Channel Access Level**: 
  - 🟢 "You have access to: All Channels" if field_mask includes `"channels"`
  - 🟠 "You have access to: X Channel(s)" for specific channel sharing

### Channel Details
For each received share, the page displays:
- **Your Accessible Channels** in styled boxes showing:
  - Channel type icon (📧 email, 📱 phone, 💬 WhatsApp, etc.)
  - Channel label (e.g., "Work Email", "Personal Mobile")
  - Channel value (the actual contact info)
- Empty state if no channels are accessible
- Visual distinction between "all channels" and "specific channels" access

### Technical Details
- Query: `contact_shares` table where `to_user_id = current_user` and `revoked_at IS NULL`
- Joins: 
  - `profiles` (owner info via `owner_id`)
  - `contacts` (contact details)
- Channel filtering: Uses `ContactShareModel.sharesAllChannels` and `sharedChannelIds` to determine YOUR access
- Real-time loading with error handling and retry capability

## Data Structure

### _ReceivedShareInfo
Internal model that combines:
- `ContactShareModel` - The share record
- Owner info (username, user ID)
- Contact name (built from full_name or given_name + family_name)
- List of accessible `ContactChannelModel` objects
- Boolean flag for "has all channels"

## UI Layout

Each received share is displayed as a card:

```
┌─────────────────────────────────────────┐
│ [J] John Doe                   RECEIVED │
│     👤 Shared by @alice_smith          │
├─────────────────────────────────────────┤
│ 🟢 You have access to: All Channels    │
│ OR                                       │
│ 🟠 You have access to: 2 Channel(s)    │
│                                          │
│ Your Accessible Channels:               │
│ ┌─────────────────────────────────────┐ │
│ │ 📧 Work Email                       │ │
│ │    john.doe@company.com             │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 📱 Personal Mobile                  │ │
│ │    +1 (555) 123-4567                │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ Share ID: xyz-789                       │
│ Received: 20/10/2025 15:45             │
└─────────────────────────────────────────┘
```

## Channel Icons
The page displays contextual icons for different channel types:
- 📧 Email (blue)
- 📱 Phone/Mobile (green)
- 💬 WhatsApp (green)
- ✈️ Telegram (blue)
- 📷 Instagram (pink)
- 💼 LinkedIn (blue)
- 🐦 Twitter/X (black)
- 📄 Other/Generic (grey)

## Field Mask Support
The page fully supports the channel-level field mask specification:
- **Legacy format**: `["channels"]` - You have access to ALL channels
- **Granular format**: `["channel:{uuid1}", "channel:{uuid2}"]` - You have access to SPECIFIC channels
- See `docs/field_mask.md` for full specification

## Debug Output
The page logs to console:
- Total number of shares received
- Each contact name, owner, and accessible channel count
- Raw query response for troubleshooting
- Detailed error messages with stack traces

## Error Handling
- Shows loading spinner during data fetch
- Displays friendly error message if query fails
- Provides retry button
- Shows empty state when no shares have been received

## Use Cases
1. **User perspective**: See what contacts others have shared with you
2. **Access verification**: Confirm what channels you can actually access
3. **Test sharing flow**: Verify that shares appear correctly for recipients
4. **Debug RLS policies**: Ensure the query returns expected data
5. **Validate field mask**: Check that channel filtering works correctly
6. **Monitor incoming shares**: See all active shares you've received at a glance

## Comparison with Accepted Shares Page

| Feature | Accepted Shares | Received Shares |
|---------|----------------|-----------------|
| **Query** | `owner_id = me` | `to_user_id = me` |
| **Shows** | Who I gave access to | Who gave me access |
| **Badge Color** | Green "ACCEPTED" | Purple "RECEIVED" |
| **Primary Info** | Recipient username | Contact name |
| **Secondary Info** | Contact I shared | Owner who shared |
| **Channels** | What THEY can see | What I can see |
| **Use Case** | Monitor outgoing shares | Monitor incoming shares |

## Query Details

```dart
// Query contact_shares where YOU are the recipient
SELECT 
  contact_shares.*,
  profiles.* as owner,        // Who shared it with you
  contacts.* as contact        // The contact they shared
FROM contact_shares
JOIN profiles ON profiles.id = contact_shares.owner_id
JOIN contacts ON contacts.id = contact_shares.contact_id
WHERE 
  contact_shares.to_user_id = :current_user_id  // You are recipient
  AND contact_shares.revoked_at IS NULL          // Share is active
ORDER BY contact_shares.created_at DESC
```

## Related Files
- `lib/test_db/features/accepted_shares_test_page.dart` - Opposite perspective (outgoing shares)
- `lib/core/data/models/contact_share_model.dart` - Share model with field mask helpers
- `lib/core/data/repositories/contact_repository.dart` - Repository for fetching shared contacts
- `lib/core/data/repositories/contact_channel_repository.dart` - Repository for fetching channels
- `docs/database/sharing_rls_policies.sql` - RLS policies enabling the queries
- `docs/field_mask.md` - Field mask specification

## Example Scenario

**Scenario**: Alice shares her contact "John Doe" with you, giving you access to his work email and personal mobile (but not his other channels).

**What you see in this page**:
```
Contact: John Doe
Shared by: @alice_smith
Access: 2 Channel(s)

Your Accessible Channels:
  📧 Work Email: john.doe@company.com
  📱 Personal Mobile: +1 (555) 123-4567
```

**What you DON'T see**:
- John's WhatsApp number (not shared)
- John's personal email (not shared)
- Any other channels Alice didn't grant access to
