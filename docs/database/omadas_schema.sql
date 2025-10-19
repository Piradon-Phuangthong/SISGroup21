-- Omadas (Groups) Schema Extension for Supabase
-- Purpose: Enable users to create groups of contacts for organized management

-- =============================
-- Omadas (Groups) Table
-- =============================
create table if not exists public.omadas (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  
  name text not null,
  description text,
  color text, -- hex color code for UI display
  icon text, -- optional icon identifier
  
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.omadas enable row level security;

-- Indexes
create index if not exists omadas_owner_idx on public.omadas (owner_id, is_deleted);
create index if not exists omadas_name_idx on public.omadas (owner_id, name);

-- RLS policies (owner only)
create policy "Owner can select omadas" on public.omadas
  for select using (auth.uid() = owner_id);

create policy "Owner can insert omadas" on public.omadas
  for insert with check (auth.uid() = owner_id);

create policy "Owner can update omadas" on public.omadas
  for update using (auth.uid() = owner_id);

create policy "Owner can delete omadas" on public.omadas
  for delete using (auth.uid() = owner_id);

-- Maintain updated_at
create trigger if not exists set_omadas_updated_at
  before update on public.omadas
  for each row execute procedure public.set_updated_at();

-- =============================
-- Omada Members Junction Table
-- =============================
create table if not exists public.omada_members (
  omada_id uuid not null references public.omadas(id) on delete cascade,
  contact_id uuid not null references public.contacts(id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (omada_id, contact_id)
);

alter table public.omada_members enable row level security;

-- Indexes
create unique index if not exists omada_members_uniq on public.omada_members (omada_id, contact_id);
create index if not exists omada_members_contact_idx on public.omada_members (contact_id);

-- RLS: user can only see/modify where they own the omada AND contact
create policy "Owner can select omada_members" on public.omada_members
  for select using (
    exists (
      select 1 from public.omadas o
      where o.id = omada_id and o.owner_id = auth.uid()
    )
    and exists (
      select 1 from public.contacts c
      where c.id = contact_id and c.owner_id = auth.uid()
    )
  );

create policy "Owner can insert omada_members" on public.omada_members
  for insert with check (
    exists (
      select 1 from public.omadas o
      where o.id = omada_id and o.owner_id = auth.uid()
    )
    and exists (
      select 1 from public.contacts c
      where c.id = contact_id and c.owner_id = auth.uid()
    )
  );

create policy "Owner can delete omada_members" on public.omada_members
  for delete using (
    exists (
      select 1 from public.omadas o
      where o.id = omada_id and o.owner_id = auth.uid()
    )
  );

-- =============================
-- Helper View: Omadas with Member Count
-- =============================
create or replace view public.omadas_with_counts as
select 
  o.*,
  count(om.contact_id) as member_count
from public.omadas o
left join public.omada_members om on om.omada_id = o.id
where o.is_deleted = false
group by o.id;

-- RLS on view
alter view public.omadas_with_counts set (security_invoker = true);
