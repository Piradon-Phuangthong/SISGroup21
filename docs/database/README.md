# Database Documentation

*Generated: 2025-10-12 12:55 UTC*
Covers the **public** schema.

---

## 📑 Schema (Tables & Columns)

### `contact_channels`

| Column     | Type                     | Nullable | Default           |
| ---------- | ------------------------ | -------- | ----------------- |
| id         | uuid                     | NO       | gen_random_uuid() |
| owner_id   | uuid                     | NO       |                   |
| contact_id | uuid                     | NO       |                   |
| kind       | text                     | NO       |                   |
| label      | text                     | YES      |                   |
| value      | text                     | YES      |                   |
| url        | text                     | YES      |                   |
| extra      | jsonb                    | YES      |                   |
| is_primary | boolean                  | NO       | false             |
| updated_at | timestamp with time zone | NO       | now()             |

### `contact_shares`

| Column     | Type                     | Nullable | Default           |
| ---------- | ------------------------ | -------- | ----------------- |
| id         | uuid                     | NO       | gen_random_uuid() |
| owner_id   | uuid                     | NO       |                   |
| to_user_id | uuid                     | NO       |                   |
| contact_id | uuid                     | NO       |                   |
| field_mask | jsonb                    | NO       | '[]'::jsonb       |
| created_at | timestamp with time zone | NO       | now()             |
| revoked_at | timestamp with time zone | YES      |                   |

### `contact_tags`

| Column     | Type                     | Nullable | Default |
| ---------- | ------------------------ | -------- | ------- |
| contact_id | uuid                     | NO       |         |
| tag_id     | uuid                     | NO       |         |
| created_at | timestamp with time zone | NO       | now()   |

### `contacts`

| Column           | Type                     | Nullable | Default           |
| ---------------- | ------------------------ | -------- | ----------------- |
| id               | uuid                     | NO       | gen_random_uuid() |
| owner_id         | uuid                     | NO       |                   |
| full_name        | text                     | YES      |                   |
| given_name       | text                     | YES      |                   |
| family_name      | text                     | YES      |                   |
| middle_name      | text                     | YES      |                   |
| prefix           | text                     | YES      |                   |
| suffix           | text                     | YES      |                   |
| primary_mobile   | text                     | YES      |                   |
| primary_email    | text                     | YES      |                   |
| avatar_url       | text                     | YES      |                   |
| notes            | text                     | YES      |                   |
| custom_fields    | jsonb                    | NO       | '{}'::jsonb       |
| default_call_app | text                     | YES      |                   |
| default_msg_app  | text                     | YES      |                   |
| is_deleted       | boolean                  | NO       | false             |
| created_at       | timestamp with time zone | NO       | now()             |
| updated_at       | timestamp with time zone | NO       | now()             |

*(repeat same compact style for `omada_members`, `omada_requests`, `omada_roles`, `omadas`, `profiles`, `share_requests`, `tags` …)*

---

## 🔗 Relationships (Foreign Keys)

* `contact_channels.owner_id` → `profiles.id`
* `contact_channels.contact_id` → `contacts.id`
* `contact_shares.to_user_id` → `profiles.id`
* `contact_shares.contact_id` → `contacts.id`
* `contact_shares.owner_id` → `profiles.id`
* `contact_tags.tag_id` → `tags.id`
* `contact_tags.contact_id` → `contacts.id`
* `contacts.owner_id` → `profiles.id`
* `omada_members.role_id` → `omada_roles.id`
* `omada_members.user_id` → `profiles.id`
* `omada_members.invited_by` → `profiles.id`
* `omada_members.omada_id` → `omadas.id`
* … *(and so on for all constraints)*

---

## ⚡ Indexes (Selected)

```sql
CREATE INDEX channels_value_idx ON public.contact_channels USING btree (value);
CREATE UNIQUE INDEX contact_shares_pkey ON public.contact_shares USING btree (id);
CREATE INDEX contacts_owner_isdel_updated_idx ON public.contacts USING btree (owner_id, is_deleted, updated_at);
CREATE UNIQUE INDEX omada_members_pkey ON public.omada_members USING btree (omada_id, user_id);
CREATE INDEX omada_requests_target_user_id_status_idx ON public.omada_requests USING btree (target_user_id, status);
CREATE UNIQUE INDEX profiles_username_key ON public.profiles USING btree (username);
CREATE UNIQUE INDEX tags_owner_id_name_key ON public.tags USING btree (owner_id, name);
```

*(list shortened here, but in your full file keep all definitions grouped by table)*

---

## 📊 Row Counts (approx)

| Table                 | Rows |
| --------------------- | ---- |
| audit_log_entries     | 172  |
| contact_channels      | 72   |
| contacts              | 13   |
| omada_roles           | 5    |
| profiles              | 2    |
| tags                  | 5    |
| users                 | 13   |
| … *(others mostly 0)* |      |

---

## 🛠️ Functions

### `enforce_single_owner_per_omada()` → trigger

```sql
CREATE OR REPLACE FUNCTION public.enforce_single_owner_per_omada()
RETURNS trigger AS $$
-- ensures only one active owner per omada
...
$$ LANGUAGE plpgsql;
```

### `generate_unique_username(base text)` → text

```sql
CREATE OR REPLACE FUNCTION public.generate_unique_username(base text)
RETURNS text AS $$
-- generates unique usernames by appending suffixes
...
$$ LANGUAGE plpgsql;
```

### `handle_new_user()` → trigger

```sql
-- ensures profile + username created for new auth.users
```

### `handle_user_signup()` → trigger

```sql
-- ensures profile, self-contact, and email channel are created
```

### `set_updated_at()` → trigger

```sql
-- auto-updates updated_at column
```

### `sync_omada_owner_id()` → trigger

```sql
-- syncs omada owner_id whenever an active owner role is assigned
```

*(expand with full definitions as in your dump if you want exact reproducibility)*

---

✅ This format is:

* **Readable in GitHub** (tables render properly, functions collapsed in code blocks).
* **Structured** by sections: Schema, Relationships, Indexes, Row Counts, Functions.
* **Minimal but complete** for repo documentation.

---

Would you like me to **split this into multiple smaller `.md` files** (`schema.md`, `relationships.md`, `functions.md`, etc.) or keep it as **one big README.md** for your `/docs/db` folder?
