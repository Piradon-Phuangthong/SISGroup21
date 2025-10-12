-- Cloud database schema for the Contacts app (Supabase/Postgres)
-- Based on docs/database/db_cloud.dbml and Supabase user management quickstart

-- Enable needed extensions
create extension if not exists "pgcrypto" with schema extensions;

-- =============================
-- Profiles (mirror of auth.users)
-- =============================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Viewable by anyone (to enable username discovery/handshake)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'Profiles are viewable by everyone.'
  ) then
    create policy "Profiles are viewable by everyone." on public.profiles
      for select using (true);
  end if;
end $$;

-- Users can insert their own profile row
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'Users can insert their own profile.'
  ) then
    create policy "Users can insert their own profile." on public.profiles
      for insert with check (auth.uid() = id);
  end if;
end $$;

-- Users can update their own profile row
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'Users can update own profile.'
  ) then
    create policy "Users can update own profile." on public.profiles
      for update using (auth.uid() = id);
  end if;
end $$;

-- Helper to generate a unique username from a base string
create or replace function public.generate_unique_username(base text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  clean_base text := lower(regexp_replace(coalesce(base, ''), '[^a-z0-9_]', '_', 'gi'));
  candidate text;
  suffix integer := 0;
begin
  if clean_base is null or length(clean_base) = 0 then
    clean_base := 'user';
  end if;

  loop
    candidate := case when suffix = 0 then clean_base else clean_base || '_' || suffix::text end;
    exit when not exists (select 1 from public.profiles where username = candidate);
    suffix := suffix + 1;
  end loop;

  return candidate;
end;
$$;

-- Trigger to auto-create a profile row when a new auth user is created
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_username text;
  generated_username text;
begin
  -- Prefer meta-provided username, else email local-part, else short id
  base_username := coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1), left(new.id::text, 8));
  generated_username := public.generate_unique_username(base_username);

  insert into public.profiles (id, username)
  values (new.id, generated_username);

  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where t.tgname = 'on_auth_user_created' and n.nspname = 'auth' and c.relname = 'users'
  ) then
    create trigger on_auth_user_created
      after insert on auth.users
      for each row execute procedure public.handle_new_user();
  end if;
end $$;

-- =============================
-- Contacts
-- =============================
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),

  full_name text,
  given_name text,
  family_name text,
  middle_name text,
  prefix text,
  suffix text,

  primary_mobile text,
  primary_email text,

  avatar_url text,
  notes text,
  custom_fields jsonb not null default '{}',

  default_call_app text,
  default_msg_app text,

  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.contacts enable row level security;

-- Indexes
do $$ begin
  if not exists (
    select 1 from pg_class where relname = 'contacts_owner_isdel_updated_idx'
  ) then
    create index contacts_owner_isdel_updated_idx on public.contacts (owner_id, is_deleted, updated_at);
  end if;
  if not exists (
    select 1 from pg_class where relname = 'contacts_primary_mobile_idx'
  ) then
    create index contacts_primary_mobile_idx on public.contacts (primary_mobile);
  end if;
end $$;

-- RLS policies for contacts (owner only)
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contacts' and policyname='Owner can select contacts'
  ) then
    create policy "Owner can select contacts" on public.contacts for select using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contacts' and policyname='Owner can insert contacts'
  ) then
    create policy "Owner can insert contacts" on public.contacts for insert with check (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contacts' and policyname='Owner can update contacts'
  ) then
    create policy "Owner can update contacts" on public.contacts for update using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contacts' and policyname='Owner can delete contacts'
  ) then
    create policy "Owner can delete contacts" on public.contacts for delete using (auth.uid() = owner_id);
  end if;
end $$;

-- Maintain updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'set_contacts_updated_at'
  ) then
    create trigger set_contacts_updated_at
      before update on public.contacts
      for each row execute procedure public.set_updated_at();
  end if;
end $$;

-- =============================
-- Contact Channels
-- =============================
create table if not exists public.contact_channels (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  contact_id uuid not null references public.contacts(id) on delete cascade,

  kind text not null,
  label text,
  value text,
  url text,
  extra jsonb,
  is_primary boolean not null default false,

  updated_at timestamptz not null default now()
);

alter table public.contact_channels enable row level security;

-- Indexes
do $$ begin
  if not exists (
    select 1 from pg_class where relname = 'contact_channels_contact_id_idx'
  ) then
    create index contact_channels_contact_id_idx on public.contact_channels (contact_id);
  end if;
  if not exists (
    select 1 from pg_class where relname = 'contact_channels_owner_kind_idx'
  ) then
    create index contact_channels_owner_kind_idx on public.contact_channels (owner_id, kind);
  end if;
  if not exists (
    select 1 from pg_class where relname = 'channels_value_idx'
  ) then
    create index channels_value_idx on public.contact_channels (value);
  end if;
end $$;

-- RLS policies (owner only)
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_channels' and policyname='Owner can select channels'
  ) then
    create policy "Owner can select channels" on public.contact_channels for select using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_channels' and policyname='Owner can insert channels'
  ) then
    create policy "Owner can insert channels" on public.contact_channels for insert with check (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_channels' and policyname='Owner can update channels'
  ) then
    create policy "Owner can update channels" on public.contact_channels for update using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_channels' and policyname='Owner can delete channels'
  ) then
    create policy "Owner can delete channels" on public.contact_channels for delete using (auth.uid() = owner_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_trigger where tgname = 'set_contact_channels_updated_at'
  ) then
    create trigger set_contact_channels_updated_at
      before update on public.contact_channels
      for each row execute procedure public.set_updated_at();
  end if;
end $$;

-- =============================
-- Tags
-- =============================
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  name text not null,
  created_at timestamptz not null default now(),
  unique (owner_id, name)
);

alter table public.tags enable row level security;

-- Ensure index name matches dbml (unique already creates named constraint)
do $$ begin
  if not exists (
    select 1 from pg_constraint where conname = 'tags_owner_name_uniq'
  ) then
    alter table public.tags
      add constraint tags_owner_name_uniq unique (owner_id, name);
  end if;
end $$;

-- RLS (owner only)
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='tags' and policyname='Owner can select tags'
  ) then
    create policy "Owner can select tags" on public.tags for select using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='tags' and policyname='Owner can insert tags'
  ) then
    create policy "Owner can insert tags" on public.tags for insert with check (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='tags' and policyname='Owner can update tags'
  ) then
    create policy "Owner can update tags" on public.tags for update using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='tags' and policyname='Owner can delete tags'
  ) then
    create policy "Owner can delete tags" on public.tags for delete using (auth.uid() = owner_id);
  end if;
end $$;

-- =============================
-- Contact ↔ Tags junction
-- =============================
create table if not exists public.contact_tags (
  contact_id uuid not null references public.contacts(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (contact_id, tag_id)
);

alter table public.contact_tags enable row level security;

-- Indexes
do $$ begin
  if not exists (
    select 1 from pg_class where relname = 'contact_tags_uniq'
  ) then
    create unique index contact_tags_uniq on public.contact_tags (contact_id, tag_id);
  end if;
  if not exists (
    select 1 from pg_class where relname = 'contact_tags_tag_id_idx'
  ) then
    create index contact_tags_tag_id_idx on public.contact_tags (tag_id);
  end if;
end $$;

-- RLS: user can only see/modify where they own the contact AND tag
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_tags' and policyname='Owner can select contact_tags'
  ) then
    create policy "Owner can select contact_tags" on public.contact_tags
      for select using (
        exists (
          select 1 from public.contacts c
          where c.id = contact_id and c.owner_id = auth.uid()
        )
        and exists (
          select 1 from public.tags t
          where t.id = tag_id and t.owner_id = auth.uid()
        )
      );
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_tags' and policyname='Owner can insert contact_tags'
  ) then
    create policy "Owner can insert contact_tags" on public.contact_tags
      for insert with check (
        exists (
          select 1 from public.contacts c
          where c.id = contact_id and c.owner_id = auth.uid()
        )
        and exists (
          select 1 from public.tags t
          where t.id = tag_id and t.owner_id = auth.uid()
        )
      );
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_tags' and policyname='Owner can delete contact_tags'
  ) then
    create policy "Owner can delete contact_tags" on public.contact_tags
      for delete using (
        exists (
          select 1 from public.contacts c
          where c.id = contact_id and c.owner_id = auth.uid()
        )
      );
  end if;
end $$;

-- =============================
-- Share Requests (username handshake)
-- =============================
create table if not exists public.share_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  message text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  responded_at timestamptz
);

alter table public.share_requests enable row level security;

-- Indexes
do $$ begin
  if not exists (
    select 1 from pg_class where relname = 'share_requests_recipient_status_idx'
  ) then
    create index share_requests_recipient_status_idx on public.share_requests (recipient_id, status);
  end if;
  if not exists (
    select 1 from pg_class where relname = 'share_requests_requester_status_idx'
  ) then
    create index share_requests_requester_status_idx on public.share_requests (requester_id, status);
  end if;
end $$;

-- RLS: requester or recipient can see; requester inserts; both can update/delete
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='share_requests' and policyname='Requester or recipient can select share_requests'
  ) then
    create policy "Requester or recipient can select share_requests" on public.share_requests
      for select using (auth.uid() = requester_id or auth.uid() = recipient_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='share_requests' and policyname='Requester can insert share_requests'
  ) then
    create policy "Requester can insert share_requests" on public.share_requests
      for insert with check (auth.uid() = requester_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='share_requests' and policyname='Requester or recipient can update share_requests'
  ) then
    create policy "Requester or recipient can update share_requests" on public.share_requests
      for update using (auth.uid() = requester_id or auth.uid() = recipient_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='share_requests' and policyname='Requester or recipient can delete share_requests'
  ) then
    create policy "Requester or recipient can delete share_requests" on public.share_requests
      for delete using (auth.uid() = requester_id or auth.uid() = recipient_id);
  end if;
end $$;

-- =============================
-- Contact Shares (grants)
-- =============================
create table if not exists public.contact_shares (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  to_user_id uuid not null references public.profiles(id),
  contact_id uuid not null references public.contacts(id) on delete cascade,
  field_mask jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique (owner_id, contact_id, to_user_id)
);

alter table public.contact_shares enable row level security;

-- Indexes
do $$ begin
  if not exists (
    select 1 from pg_class where relname = 'contact_shares_owner_to_user_idx'
  ) then
    create index contact_shares_owner_to_user_idx on public.contact_shares (owner_id, to_user_id);
  end if;
  if not exists (
    select 1 from pg_class where relname = 'contact_shares_to_user_contact_idx'
  ) then
    create index contact_shares_to_user_contact_idx on public.contact_shares (to_user_id, contact_id);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'contact_share_uniq'
  ) then
    alter table public.contact_shares
      add constraint contact_share_uniq unique (owner_id, contact_id, to_user_id);
  end if;
end $$;

-- RLS: owner manages, recipient can read
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_shares' and policyname='Owner or recipient can select contact_shares'
  ) then
    create policy "Owner or recipient can select contact_shares" on public.contact_shares
      for select using (auth.uid() = owner_id or auth.uid() = to_user_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_shares' and policyname='Owner can insert contact_shares'
  ) then
    create policy "Owner can insert contact_shares" on public.contact_shares
      for insert with check (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_shares' and policyname='Owner can update contact_shares'
  ) then
    create policy "Owner can update contact_shares" on public.contact_shares
      for update using (auth.uid() = owner_id);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='contact_shares' and policyname='Owner can delete contact_shares'
  ) then
    create policy "Owner can delete contact_shares" on public.contact_shares
      for delete using (auth.uid() = owner_id);
  end if;
end $$;

-- =============================
-- Storage (avatars bucket and policies)
-- =============================
insert into storage.buckets (id, name)
select 'avatars', 'avatars'
where not exists (
  select 1 from storage.buckets where id = 'avatars'
);

-- Publicly readable avatars
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Avatar images are publicly accessible.'
  ) then
    create policy "Avatar images are publicly accessible." on storage.objects
      for select using (bucket_id = 'avatars');
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Anyone can upload an avatar.'
  ) then
    create policy "Anyone can upload an avatar." on storage.objects
      for insert with check (bucket_id = 'avatars');
  end if;
end $$;


