# Cloud database (Supabase / Postgres)

## Overview

* **Auth users** live in `auth.users` (Supabase). We mirror essentials in **`profiles`** (username).
* You own your data: every “owned” row carries `owner_id`.
* Sharing is **request-by-username only**. After acceptance, owners choose **which contacts** and **which fields** to share using `contact_shares`.

---

## Table: `profiles`

Purpose: mirror of the authenticated user with a unique **username** used for requests.

| Field        | Type                              | Required | Default | Description                            |
| ------------ | --------------------------------- | -------: | ------- | -------------------------------------- |
| `id`         | `uuid` (PK, FK → `auth.users.id`) |        ✅ | –       | User’s auth id.                        |
| `username`   | `text` (unique)                   |        ✅ | –       | Handle used to find users (lowercase). |
| `created_at` | `timestamptz`                     |        ✅ | `now()` | Row creation time.                     |

**Fits in:** lets you **search by username**, join ownership (`owner_id`) and request targets.

---

## Table: `contacts`

Purpose: the contact “card” you own.

| Field                                                              | Type                        | Required | Default             | Description                                         |
| ------------------------------------------------------------------ | --------------------------- | -------: | ------------------- | --------------------------------------------------- |
| `id`                                                               | `uuid` (PK)                 |        ✅ | `gen_random_uuid()` | Contact id.                                         |
| `owner_id`                                                         | `uuid` (FK → `profiles.id`) |        ✅ | –                   | The profile that owns this contact.                 |
| `full_name`                                                        | `text`                      |        – | –                   | Convenience full name.                              |
| `given_name` / `family_name` / `middle_name` / `prefix` / `suffix` | `text`                      |        – | –                   | Optional name parts.                                |
| `primary_mobile`                                                   | `text`                      |        – | –                   | Main mobile (not the DB PK; people change numbers). |
| `primary_email`                                                    | `text`                      |        – | –                   | Main email.                                         |
| `avatar_url`                                                       | `text`                      |        – | –                   | Cloud file path/URL for profile picture.            |
| `notes`                                                            | `text`                      |        – | –                   | Free-text notes (owner only).                       |
| `custom_fields`                                                    | `jsonb`                     |        – | `{}`                | Simple extensibility (key/values).                  |
| `default_call_app` / `default_msg_app`                             | `text`                      |        – | –                   | Per-contact overrides for call/message.             |
| `is_deleted`                                                       | `bool`                      |        ✅ | `false`             | Soft delete flag.                                   |
| `created_at`                                                       | `timestamptz`               |        ✅ | `now()`             | Created time.                                       |
| `updated_at`                                                       | `timestamptz`               |        ✅ | `now()`             | Last change time.                                   |

**Fits in:** owner’s master record; related rows (channels, addresses, tags) hang off this.

---

## Table: `contact_channels`

Purpose: **one row per phone/email/social/payment/etc.** (keeps schema small).

| Field        | Type                        | Req | Default             | Description                                                                                                                                                                                         |
| ------------ | --------------------------- | --: | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`         | `uuid` (PK)                 |   ✅ | `gen_random_uuid()` | Channel id.                                                                                                                                                                                         |
| `owner_id`   | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Owner (same as contact owner).                                                                                                                                                                      |
| `contact_id` | `uuid` (FK → `contacts.id`) |   ✅ | –                   | Parent contact.                                                                                                                                                                                     |
| `kind`       | `text`                      |   ✅ | –                   | e.g. `mobile`, `phone`, `email`, `whatsapp`, `telegram`, `imessage`, `signal`, `wechat`, `instagram`, `linkedin`, `github`, `x`, `facebook`, `tiktok`, `website`, `payid`, `beem`, `bank`, `other`. |
| `label`      | `text`                      |   – | –                   | e.g. `work`, `home`, `main`.                                                                                                                                                                        |
| `value`      | `text`                      |   – | –                   | Number, email, @handle, payment id, etc.                                                                                                                                                            |
| `url`        | `text`                      |   – | –                   | Canonical URL (e.g., LinkedIn profile).                                                                                                                                                             |
| `extra`      | `jsonb`                     |   – | –                   | Structured extras (e.g., `{ "bsb": "062000", "acct": "123456" }`).                                                                                                                                  |
| `is_primary` | `bool`                      |   ✅ | `false`             | Primary flag for this channel kind.                                                                                                                                                                 |
| `updated_at` | `timestamptz`               |   ✅ | `now()`             | Last change time.                                                                                                                                                                                   |

**Fits in:** unifies phones/emails/social/payments into one simple, flexible table.

---

## Table: `addresses`

Purpose: optional physical/mailing addresses per contact.

| Field          | Type                        | Req | Default             | Description             |
| -------------- | --------------------------- | --: | ------------------- | ----------------------- |
| `id`           | `uuid` (PK)                 |   ✅ | `gen_random_uuid()` | Address id.             |
| `owner_id`     | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Owner of the address.   |
| `contact_id`   | `uuid` (FK → `contacts.id`) |   ✅ | –                   | Parent contact.         |
| `label`        | `text`                      |   – | –                   | e.g. `home`, `office`.  |
| `address_text` | `text`                      |   – | –                   | Free-form address blob. |
| `updated_at`   | `timestamptz`               |   ✅ | `now()`             | Last change time.       |

**Fits in:** keep addresses separate so contacts stay light.

---

## Table: `tags`

Purpose: your personal tags (free-text).

| Field        | Type                        | Req | Default             | Description                  |
| ------------ | --------------------------- | --: | ------------------- | ---------------------------- |
| `id`         | `uuid` (PK)                 |   ✅ | `gen_random_uuid()` | Tag id.                      |
| `owner_id`   | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Tag owner.                   |
| `name`       | `text`                      |   ✅ | –                   | Tag text (unique per owner). |
| `created_at` | `timestamptz`               |   ✅ | `now()`             | Created time.                |

**Fits in:** used for grouping/filtering and tag-scoped shares (if you ever add them later).

---

## Table: `contact_tags`

Purpose: junction table between contacts and tags.

| Field        | Type                        | Req | Default | Description             |
| ------------ | --------------------------- | --: | ------- | ----------------------- |
| `contact_id` | `uuid` (FK → `contacts.id`) |   ✅ | –       | Contact.                |
| `tag_id`     | `uuid` (FK → `tags.id`)     |   ✅ | –       | Tag.                    |
| `created_at` | `timestamptz`               |   ✅ | `now()` | When the tag was added. |

**Fits in:** many-to-many link; keeps tags reusable and fast to filter.

---

## Table: `share_requests`

Purpose: **request-by-username** flow. Recipient accepts/declines.

| Field          | Type                        | Req | Default             | Description                                           |
| -------------- | --------------------------- | --: | ------------------- | ----------------------------------------------------- |
| `id`           | `uuid` (PK)                 |   ✅ | `gen_random_uuid()` | Request id.                                           |
| `requester_id` | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Who sent the request.                                 |
| `recipient_id` | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Who receives the request.                             |
| `message`      | `text`                      |   – | –                   | Optional note (“Hi, let’s share!”).                   |
| `status`       | `text`                      |   ✅ | `'pending'`         | `'pending' \| 'accepted' \| 'declined' \| 'blocked'`. |
| `created_at`   | `timestamptz`               |   ✅ | `now()`             | Created time.                                         |
| `responded_at` | `timestamptz`               |   – | –                   | When recipient acted.                                 |

**Fits in:** gate to start sharing; **does not** grant access by itself.

---

## Table: `contact_shares`

Purpose: owner grants **read-only** access for **one contact** to **one user**, with a simple **field mask**.

| Field        | Type                        | Req | Default             | Description                                                                                           |
| ------------ | --------------------------- | --: | ------------------- | ----------------------------------------------------------------------------------------------------- |
| `id`         | `uuid` (PK)                 |   ✅ | `gen_random_uuid()` | Share id.                                                                                             |
| `owner_id`   | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Contact owner granting access.                                                                        |
| `to_user_id` | `uuid` (FK → `profiles.id`) |   ✅ | –                   | Recipient user.                                                                                       |
| `contact_id` | `uuid` (FK → `contacts.id`) |   ✅ | –                   | The contact being shared.                                                                             |
| `field_mask` | `jsonb`                     |   ✅ | `'[]'`              | List of allowed fields, e.g. `["full_name","primary_mobile","primary_email","channels","addresses"]`. |
| `created_at` | `timestamptz`               |   ✅ | `now()`             | When grant was made.                                                                                  |
| `revoked_at` | `timestamptz`               |   – | –                   | When access was revoked.                                                                              |

**Fits in:** the **actual permission**. Your app pulls these to build the recipient’s read-only view.

> **Field mask guidance (keep simple):**
>
> * Top-level tokens: `full_name`, `given_name`, `family_name`, `primary_mobile`, `primary_email`, `channels`, `addresses`.
> * If you want finer control later, allow `channels.mobile`, `channels.email`, etc.—but this is optional for the project.

---

# Local database (Isar)

## Overview

* Mirrors cloud structures for easy mapping.
* Adds **`is_dirty`** for owner data (push later) and **`source/localOnlyEdits`** for shared-in contacts.

---

## Collection: `LocalSettings`

Purpose: device/app-level settings and sync cursor.

| Field                                          | Type                 | Required | Description                      |
| ---------------------------------------------- | -------------------- | -------: | -------------------------------- |
| `id`                                           | `int` (PK, always 1) |        ✅ | Singleton row.                   |
| `deviceId`                                     | `String`             |        ✅ | Stable device id.                |
| `userId`                                       | `String?`            |        – | Supabase user id once signed in. |
| `globalDefaultCallApp` / `globalDefaultMsgApp` | `String?`            |        – | App-wide defaults.               |
| `lastFullSyncAt`                               | `DateTime?`          |        – | Cursor for pull sync.            |

**Fits in:** small app config and sync timing.

---

## Collection: `Contact`

Purpose: the local contact card (owned or shared-in).

| Field                                                                        | Type       | Req | Description                                       |
| ---------------------------------------------------------------------------- | ---------- | --: | ------------------------------------------------- |
| `id`                                                                         | `int` (PK) |   ✅ | Local Isar id.                                    |
| `cloudId`                                                                    | `String?`  |   – | Cloud `contacts.id` (uuid) when synced.           |
| `ownerUserId`                                                                | `String?`  |   – | Cloud owner (for shared-in contacts).             |
| `fullName` / `givenName` / `familyName` / `middleName` / `prefix` / `suffix` | `String?`  |   – | Name parts.                                       |
| `primaryMobile` / `primaryEmail`                                             | `String?`  |   – | Primaries for quick UX.                           |
| `avatarPath`                                                                 | `String?`  |   – | Local file path for avatar (if any).              |
| `notes`                                                                      | `String?`  |   – | Your private notes.                               |
| `customFieldsJson`                                                           | `String?`  |   – | JSON string for custom fields.                    |
| `defaultCallApp` / `defaultMsgApp`                                           | `String?`  |   – | Per-contact overrides.                            |
| `isDeleted`                                                                  | `bool`     |   ✅ | Soft delete flag.                                 |
| `createdAt` / `updatedAt`                                                    | `DateTime` |   ✅ | Timestamps.                                       |
| `isDirty`                                                                    | `bool`     |   ✅ | True if needs push (only for **owned** contacts). |
| `source`                                                                     | `String`   |   ✅ | `'local'` (owned) or `'external'` (shared-in).    |
| `localOnlyEdits`                                                             | `bool`     |   ✅ | True for shared-in contacts—never push these.     |

**Fits in:** single source of truth for the app UI; links out to channels, addresses, tags.

---

## Collection: `ContactChannel`

Purpose: local channels (phone/email/social/payment/etc.) for a contact.

| Field       | Type       | Req | Description                                     |
| ----------- | ---------- | --: | ----------------------------------------------- |
| `id`        | `int` (PK) |   ✅ | Local id.                                       |
| `contactId` | `int`      |   ✅ | Parent contact (denormalized for speed).        |
| `kind`      | `String`   |   ✅ | e.g. `mobile`, `email`, `instagram`, `payid`, … |
| `label`     | `String?`  |   – | `work`, `home`, `main`, …                       |
| `value`     | `String?`  |   – | Number/email/handle/etc.                        |
| `url`       | `String?`  |   – | Canonical URL (if any).                         |
| `extraJson` | `String?`  |   – | JSON extras (e.g., bank details).               |
| `isPrimary` | `bool`     |   ✅ | Primary flag.                                   |
| `updatedAt` | `DateTime` |   ✅ | Last change time.                               |
| `isDirty`   | `bool`     |   ✅ | Needs push (owned contacts only).               |

**Fits in:** mirrors cloud `contact_channels` 1:1.

---

## Collection: `Address`

Purpose: local addresses per contact.

| Field         | Type       | Req | Description                       |
| ------------- | ---------- | --: | --------------------------------- |
| `id`          | `int` (PK) |   ✅ | Local id.                         |
| `contactId`   | `int`      |   ✅ | Parent contact.                   |
| `label`       | `String?`  |   – | `home`, `office`, …               |
| `addressText` | `String?`  |   – | Free-form text.                   |
| `updatedAt`   | `DateTime` |   ✅ | Last change time.                 |
| `isDirty`     | `bool`     |   ✅ | Needs push (owned contacts only). |

**Fits in:** optional, keeps contact core light.

---

## Collection: `Tag`

Purpose: local list of tags.

| Field  | Type       | Req | Description |
| ------ | ---------- | --: | ----------- |
| `id`   | `int` (PK) |   ✅ | Local id.   |
| `name` | `String`   |   ✅ | Tag text.   |

**Fits in:** tag filters & quick grouping.

---

## Collection: `ContactTag`

Purpose: local many-to-many link between contacts and tags.

| Field       | Type       | Req | Description         |
| ----------- | ---------- | --: | ------------------- |
| `id`        | `int` (PK) |   ✅ | Local id.           |
| `contactId` | `int`      |   ✅ | Contact.            |
| `tagId`     | `int`      |   ✅ | Tag.                |
| `createdAt` | `DateTime` |   ✅ | When tag was added. |

**Fits in:** enables tag filtering and counts.

---

## (Optional) `share_request_cache` & `contact_share_cache`

Purpose: **UX caches** so you can show pending requests & active grants offline. Safe to omit for the assignment if time is tight.

---

# How the pieces fit (short flows)

* **Create a contact (offline):** write `Contact` (+ `ContactChannel`) in Isar → mark `isDirty=true`.
* **Sync up (owner):** push dirty contacts/channels to cloud → receive `cloudId` → clear `isDirty`.
* **Find a user by username:** query `profiles` with `username`.
* **Send request:** insert row in `share_requests` (`pending`).
* **Accept:** recipient updates `share_requests.status='accepted'`.
* **Grant access:** owner inserts rows in `contact_shares` for selected contacts with a **field mask** (e.g., `["full_name","primary_mobile","channels"]`).
* **Recipient pulls shares:** join `contact_shares` → fetch those `contacts` + `contact_channels` → store locally as `Contact.source='external'` & `localOnlyEdits=true`. Recipient can annotate locally, but never pushes those edits.

---

# Minimal field-mask you can support in v1

* `"full_name"`, `"given_name"`, `"family_name"`, `"primary_mobile"`, `"primary_email"`, `"channels"`, `"addresses"`
  (Keep it simple. If you want per-channel granularity later, you can add `"channels.mobile"`, `"channels.email"`.)