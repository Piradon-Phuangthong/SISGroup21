-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.contact_channels (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  contact_id uuid NOT NULL,
  kind text NOT NULL,
  label text,
  value text,
  url text,
  extra jsonb,
  is_primary boolean NOT NULL DEFAULT false,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT contact_channels_pkey PRIMARY KEY (id),
  CONSTRAINT contact_channels_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id),
  CONSTRAINT contact_channels_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id)
);
CREATE TABLE public.contact_shares (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  to_user_id uuid NOT NULL,
  contact_id uuid NOT NULL,
  field_mask jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  revoked_at timestamp with time zone,
  CONSTRAINT contact_shares_pkey PRIMARY KEY (id),
  CONSTRAINT contact_shares_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id),
  CONSTRAINT contact_shares_to_user_id_fkey FOREIGN KEY (to_user_id) REFERENCES public.profiles(id),
  CONSTRAINT contact_shares_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id)
);
CREATE TABLE public.contact_tags (
  contact_id uuid NOT NULL,
  tag_id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT contact_tags_pkey PRIMARY KEY (contact_id, tag_id),
  CONSTRAINT contact_tags_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id),
  CONSTRAINT contact_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id)
);
CREATE TABLE public.contacts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
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
  custom_fields jsonb NOT NULL DEFAULT '{}'::jsonb,
  default_call_app text,
  default_msg_app text,
  is_deleted boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT contacts_pkey PRIMARY KEY (id),
  CONSTRAINT contacts_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.omada_members (
  omada_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role_id uuid NOT NULL,
  invited_by uuid,
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'active'::text,
  contact_id uuid,
  CONSTRAINT omada_members_pkey PRIMARY KEY (omada_id, user_id),
  CONSTRAINT omada_members_omada_id_fkey FOREIGN KEY (omada_id) REFERENCES public.omadas(id),
  CONSTRAINT omada_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT omada_members_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.omada_roles(id),
  CONSTRAINT omada_members_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.omada_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  omada_id uuid NOT NULL,
  requester_id uuid NOT NULL,
  target_user_id uuid NOT NULL,
  type text NOT NULL,
  message text,
  status text NOT NULL DEFAULT 'pending'::text,
  decided_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  decided_at timestamp with time zone,
  CONSTRAINT omada_requests_pkey PRIMARY KEY (id),
  CONSTRAINT omada_requests_omada_id_fkey FOREIGN KEY (omada_id) REFERENCES public.omadas(id),
  CONSTRAINT omada_requests_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.profiles(id),
  CONSTRAINT omada_requests_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.profiles(id),
  CONSTRAINT omada_requests_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.omada_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  display_name text NOT NULL,
  description text,
  rank integer NOT NULL,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT omada_roles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.omadas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  name text NOT NULL,
  handle text DEFAULT regexp_replace(lower(name), '[^a-z0-9]+'::text, '-'::text, 'g'::text),
  description text,
  avatar_url text,
  visibility text NOT NULL DEFAULT 'private'::text,
  join_policy text NOT NULL DEFAULT 'approval'::text,
  is_deleted boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT omadas_pkey PRIMARY KEY (id),
  CONSTRAINT omadas_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.share_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  requester_id uuid NOT NULL,
  recipient_id uuid NOT NULL,
  message text,
  status text NOT NULL DEFAULT 'pending'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  responded_at timestamp with time zone,
  contact_id uuid,
  field_mask jsonb DEFAULT '[]'::jsonb,
  CONSTRAINT share_requests_pkey PRIMARY KEY (id),
  CONSTRAINT share_requests_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.profiles(id),
  CONSTRAINT share_requests_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id),
  CONSTRAINT share_requests_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id)
);
CREATE TABLE public.tags (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  name text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT tags_pkey PRIMARY KEY (id),
  CONSTRAINT tags_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);