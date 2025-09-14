## Cloud schema: Indexes and RLS policies

This document explains the indexes and Row Level Security (RLS) policies defined in `docs/database/supabase.cloud_schema.sql`. It groups them by table and clarifies their purpose and impact.

### profiles
- Indexes
  - **Primary key (id)**: Ensures 1 row per user. Backed by a unique btree index.
  - **Unique (username)**: Enforces globally unique usernames. Backed by a unique index that accelerates lookups by username.

- RLS policies
  - **Profiles are viewable by everyone. (SELECT using true)**: Allows public read access to enable username discovery and handshakes.
  - **Users can insert their own profile. (INSERT check auth.uid() = id)**: Prevents users from creating profiles for other users.
  - **Users can update own profile. (UPDATE using auth.uid() = id)**: Limits profile edits to the profile owner.

### contacts
- Indexes
  - **contacts_owner_isdel_updated_idx (owner_id, is_deleted, updated_at)**: Supports sync and list queries by owner; `is_deleted` aids soft-delete filtering; `updated_at` supports incremental sync.
  - **contacts_primary_mobile_idx (primary_mobile)**: Speeds up lookups by main phone number (e.g., dedupe, reverse-lookup).
  - **Primary key (id)**: Row identity and clustering point for joins.

- RLS policies (owner-scoped)
  - **Owner can select contacts**: `SELECT using auth.uid() = owner_id`
  - **Owner can insert contacts**: `INSERT check auth.uid() = owner_id`
  - **Owner can update contacts**: `UPDATE using auth.uid() = owner_id`
  - **Owner can delete contacts**: `DELETE using auth.uid() = owner_id`

### contact_channels
- Indexes
  - **contact_channels_contact_id_idx (contact_id)**: Enables efficient fetch of all channels for a contact.
  - **contact_channels_owner_kind_idx (owner_id, kind)**: Accelerates filtering channels by owner and type (e.g., "all emails").
  - **channels_value_idx (value)**: Supports reverse-lookup by value (phone, email, handle).
  - **Primary key (id)**: Row identity and join target.

- RLS policies (owner-scoped)
  - **Owner can select channels**: `SELECT using auth.uid() = owner_id`
  - **Owner can insert channels**: `INSERT check auth.uid() = owner_id`
  - **Owner can update channels**: `UPDATE using auth.uid() = owner_id`
  - **Owner can delete channels**: `DELETE using auth.uid() = owner_id`

### tags
- Indexes
  - **tags_owner_name_uniq (owner_id, name)**: Per-owner uniqueness for tag names and fast lookup when filtering by owner+name.
  - **Primary key (id)**: Row identity.

- RLS policies (owner-scoped)
  - **Owner can select tags**: `SELECT using auth.uid() = owner_id`
  - **Owner can insert tags**: `INSERT check auth.uid() = owner_id`
  - **Owner can update tags**: `UPDATE using auth.uid() = owner_id`
  - **Owner can delete tags**: `DELETE using auth.uid() = owner_id`

### contact_tags (junction)
- Indexes
  - **Primary key (contact_id, tag_id)**: Enforces one link per pair and provides the canonical unique index.
  - **contact_tags_uniq (contact_id, tag_id)**: A unique index matching the DBML notation; functionally redundant with the primary key but harmless. It can improve planner choices in some scenarios.
  - **contact_tags_tag_id_idx (tag_id)**: Speeds up reverse lookups: all contacts for a given tag.

- RLS policies
  - **Owner can select contact_tags**: `SELECT using` current user must own both the contact and the tag.
  - **Owner can insert contact_tags**: `INSERT check` current user must own both the contact and the tag.
  - **Owner can delete contact_tags**: `DELETE using` current user must own the contact. (Update is not needed; re-link by delete+insert.)

### share_requests
- Indexes
  - **share_requests_recipient_status_idx (recipient_id, status)**: Efficient inbox queries and filtering by status.
  - **share_requests_requester_status_idx (requester_id, status)**: Speeds up sent-requests queries by requester and status.
  - **Primary key (id)**: Row identity.

- RLS policies
  - **Requester or recipient can select share_requests**: `SELECT using auth.uid() = requester_id or auth.uid() = recipient_id`
  - **Requester can insert share_requests**: `INSERT check auth.uid() = requester_id`
  - **Requester or recipient can update share_requests**: `UPDATE using` same requester-or-recipient rule.
  - **Requester or recipient can delete share_requests**: `DELETE using` same requester-or-recipient rule.

### contact_shares (grants)
- Indexes
  - **contact_shares_owner_to_user_idx (owner_id, to_user_id)**: Speeds owner-centric audits of who has access.
  - **contact_shares_to_user_contact_idx (to_user_id, contact_id)**: Speeds recipient views of shared contacts.
  - **contact_share_uniq (owner_id, contact_id, to_user_id)**: Ensures only one grant exists per owner→recipient per contact; backs fast existence checks.
  - **Primary key (id)**: Row identity.

- RLS policies
  - **Owner or recipient can select contact_shares**: `SELECT using auth.uid() = owner_id or auth.uid() = to_user_id` (recipient visibility; owner control).
  - **Owner can insert contact_shares**: `INSERT check auth.uid() = owner_id`
  - **Owner can update contact_shares**: `UPDATE using auth.uid() = owner_id`
  - **Owner can delete contact_shares**: `DELETE using auth.uid() = owner_id`

### storage.objects (avatars)
- Policies
  - **Avatar images are publicly accessible. (SELECT using bucket_id = 'avatars')**: Allows unauthenticated reads of avatar files to enable public profile images.
  - **Anyone can upload an avatar. (INSERT check bucket_id = 'avatars')**: Permits uploads to the `avatars` bucket. (Consider adding path-based ownership rules if you need stricter control.)

---

Notes
- Primary keys and unique constraints implicitly create supporting indexes; they are listed above where relevant.
- All application tables have RLS enabled explicitly; only storage objects are in the `storage` schema and use storage policies.
- Owner-scoped policies consistently rely on `auth.uid()` to tie access to the authenticated user.


