-- Advanced Omadas (Groups) Schema with Role-Based Membership
-- This extends the basic omadas schema with role management and join requests

-- =============================
-- Omada Roles Table
-- =============================
-- Define available roles within an Omada
create table if not exists public.omada_roles (
  role_name text primary key,
  description text,
  hierarchy_level int not null unique, -- Higher number = more permissions
  created_at timestamptz not null default now()
);

alter table public.omada_roles enable row level security;

-- Allow anyone to read role definitions
create policy "Anyone can view omada_roles" on public.omada_roles
  for select using (true);

-- Insert default roles
insert into public.omada_roles (role_name, description, hierarchy_level) values
  ('guest', 'Can view limited content', 1),
  ('member', 'Regular member with standard access', 2),
  ('moderator', 'Can moderate content and approve join requests', 3),
  ('admin', 'Can manage members and settings', 4),
  ('owner', 'Full control over the Omada', 5)
on conflict (role_name) do nothing;

-- =============================
-- Update Omadas Table
-- =============================
-- Add join_policy to control how users can join
alter table public.omadas 
  add column if not exists join_policy text not null default 'approval' 
  check (join_policy in ('open', 'approval', 'closed'));

alter table public.omadas
  add column if not exists avatar_url text;

alter table public.omadas
  add column if not exists is_public boolean not null default true;

-- Update RLS for public omadas
drop policy if exists "Owner can select omadas" on public.omadas;
create policy "Users can select their omadas or public ones" on public.omadas
  for select using (
    auth.uid() = owner_id 
    or (is_public = true and is_deleted = false)
  );

-- =============================
-- Omada Memberships (Replaces omada_members)
-- =============================
-- New table with roles instead of simple junction
create table if not exists public.omada_memberships (
  id uuid primary key default gen_random_uuid(),
  omada_id uuid not null references public.omadas(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_name text not null references public.omada_roles(role_name) on delete restrict,
  
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  unique (omada_id, user_id)
);

alter table public.omada_memberships enable row level security;

-- Indexes
create index if not exists omada_memberships_omada_idx on public.omada_memberships (omada_id);
create index if not exists omada_memberships_user_idx on public.omada_memberships (user_id);
create index if not exists omada_memberships_role_idx on public.omada_memberships (role_name);

-- RLS: Users can see memberships of omadas they belong to or public omadas
create policy "Users can select memberships of their omadas" on public.omada_memberships
  for select using (
    user_id = auth.uid()
    or exists (
      select 1 from public.omada_memberships om
      where om.omada_id = omada_memberships.omada_id 
      and om.user_id = auth.uid()
    )
    or exists (
      select 1 from public.omadas o
      where o.id = omada_memberships.omada_id
      and o.is_public = true
    )
  );

-- Only owner or admin can insert memberships
create policy "Owners and admins can insert memberships" on public.omada_memberships
  for insert with check (
    exists (
      select 1 from public.omadas o
      where o.id = omada_id 
      and o.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.omada_memberships om
      join public.omada_roles r on r.role_name = om.role_name
      where om.omada_id = omada_id
      and om.user_id = auth.uid()
      and r.hierarchy_level >= 4 -- Admin or higher
    )
  );

-- Only owner, admin, or moderator can update memberships
create policy "Owners, admins, mods can update memberships" on public.omada_memberships
  for update using (
    exists (
      select 1 from public.omadas o
      where o.id = omada_id 
      and o.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.omada_memberships om
      join public.omada_roles r on r.role_name = om.role_name
      where om.omada_id = omada_id
      and om.user_id = auth.uid()
      and r.hierarchy_level >= 3 -- Moderator or higher
    )
  );

-- Only owner or admin can delete memberships
create policy "Owners and admins can delete memberships" on public.omada_memberships
  for delete using (
    exists (
      select 1 from public.omadas o
      where o.id = omada_id 
      and o.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.omada_memberships om
      join public.omada_roles r on r.role_name = om.role_name
      where om.omada_id = omada_id
      and om.user_id = auth.uid()
      and r.hierarchy_level >= 4 -- Admin or higher
    )
  );

-- Maintain updated_at
create trigger if not exists set_omada_memberships_updated_at
  before update on public.omada_memberships
  for each row execute procedure public.set_updated_at();

-- =============================
-- Join Requests Table
-- =============================
create table if not exists public.omada_join_requests (
  id uuid primary key default gen_random_uuid(),
  omada_id uuid not null references public.omadas(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  
  status text not null default 'pending' 
    check (status in ('pending', 'approved', 'rejected')),
  
  message text, -- Optional message from user
  response_message text, -- Optional message from moderator
  
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  unique (omada_id, user_id, status) -- One pending request per user per omada
);

alter table public.omada_join_requests enable row level security;

-- Indexes
create index if not exists omada_join_requests_omada_idx on public.omada_join_requests (omada_id, status);
create index if not exists omada_join_requests_user_idx on public.omada_join_requests (user_id);

-- RLS: Users can see their own requests
create policy "Users can select their join requests" on public.omada_join_requests
  for select using (user_id = auth.uid());

-- RLS: Moderators and above can see requests for their omadas
create policy "Moderators can select omada join requests" on public.omada_join_requests
  for select using (
    exists (
      select 1 from public.omada_memberships om
      join public.omada_roles r on r.role_name = om.role_name
      where om.omada_id = omada_join_requests.omada_id
      and om.user_id = auth.uid()
      and r.hierarchy_level >= 3 -- Moderator or higher
    )
  );

-- Users can create join requests
create policy "Users can create join requests" on public.omada_join_requests
  for insert with check (
    user_id = auth.uid()
    and status = 'pending'
    and not exists (
      select 1 from public.omada_memberships om
      where om.omada_id = omada_id
      and om.user_id = auth.uid()
    )
  );

-- Moderators and above can update requests (approve/reject)
create policy "Moderators can update join requests" on public.omada_join_requests
  for update using (
    exists (
      select 1 from public.omada_memberships om
      join public.omada_roles r on r.role_name = om.role_name
      where om.omada_id = omada_join_requests.omada_id
      and om.user_id = auth.uid()
      and r.hierarchy_level >= 3 -- Moderator or higher
    )
  );

-- Users can delete their own pending requests
create policy "Users can delete their pending requests" on public.omada_join_requests
  for delete using (
    user_id = auth.uid() 
    and status = 'pending'
  );

-- Maintain updated_at
create trigger if not exists set_omada_join_requests_updated_at
  before update on public.omada_join_requests
  for each row execute procedure public.set_updated_at();

-- =============================
-- Helper Functions
-- =============================

-- Function to check user's role in an omada
create or replace function public.get_user_omada_role(
  p_omada_id uuid,
  p_user_id uuid
)
returns text
language plpgsql
security definer
as $$
declare
  v_role text;
  v_is_owner boolean;
begin
  -- Check if user is owner
  select true into v_is_owner
  from public.omadas
  where id = p_omada_id and owner_id = p_user_id;
  
  if v_is_owner then
    return 'owner';
  end if;
  
  -- Check membership role
  select role_name into v_role
  from public.omada_memberships
  where omada_id = p_omada_id and user_id = p_user_id;
  
  return v_role;
end;
$$;

-- Function to check if user has permission
create or replace function public.user_has_omada_permission(
  p_omada_id uuid,
  p_user_id uuid,
  p_required_level int
)
returns boolean
language plpgsql
security definer
as $$
declare
  v_role text;
  v_level int;
begin
  v_role := public.get_user_omada_role(p_omada_id, p_user_id);
  
  if v_role is null then
    return false;
  end if;
  
  select hierarchy_level into v_level
  from public.omada_roles
  where role_name = v_role;
  
  return v_level >= p_required_level;
end;
$$;

-- Trigger to automatically create owner membership when omada is created
create or replace function public.create_owner_membership()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.omada_memberships (omada_id, user_id, role_name)
  values (new.id, new.owner_id, 'owner');
  return new;
end;
$$;

create trigger if not exists create_owner_membership_trigger
  after insert on public.omadas
  for each row execute procedure public.create_owner_membership();

-- Trigger to auto-create membership when join request is approved
create or replace function public.handle_join_request_approval()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.status = 'approved' and old.status = 'pending' then
    -- Create membership with 'member' role
    insert into public.omada_memberships (omada_id, user_id, role_name)
    values (new.omada_id, new.user_id, 'member')
    on conflict (omada_id, user_id) do nothing;
    
    -- Set reviewed info
    new.reviewed_by := auth.uid();
    new.reviewed_at := now();
  end if;
  
  return new;
end;
$$;

create trigger if not exists handle_join_request_approval_trigger
  before update on public.omada_join_requests
  for each row execute procedure public.handle_join_request_approval();

-- =============================
-- Updated View: Omadas with Member Count
-- =============================
drop view if exists public.omadas_with_counts;

create or replace view public.omadas_with_counts as
select 
  o.*,
  count(om.user_id) as member_count,
  count(case when jr.status = 'pending' then 1 end) as pending_requests_count
from public.omadas o
left join public.omada_memberships om on om.omada_id = o.id
left join public.omada_join_requests jr on jr.omada_id = o.id and jr.status = 'pending'
where o.is_deleted = false
group by o.id;

-- RLS on view
alter view public.omadas_with_counts set (security_invoker = true);

-- =============================
-- Migration from old schema
-- =============================
-- If you have existing omada_members data, migrate it:
-- insert into public.omada_memberships (omada_id, user_id, role_name)
-- select 
--   om.omada_id,
--   c.owner_id as user_id,
--   'member' as role_name
-- from public.omada_members om
-- join public.contacts c on c.id = om.contact_id
-- on conflict (omada_id, user_id) do nothing;
