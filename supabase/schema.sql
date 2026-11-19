-- Dear, Us — Supabase schema
-- Run this whole file in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Dear, Us',
  created_at timestamptz not null default now()
);

create table if not exists public.couple_members (
  couple_id uuid not null references public.couples(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (couple_id, user_id)
);

create table if not exists public.capsules (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  title text not null,
  opens_at date not null,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

-- Secret content is physically separated from capsule metadata.
create table if not exists public.capsule_contents (
  capsule_id uuid primary key references public.capsules(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists capsules_couple_opens_idx on public.capsules(couple_id, opens_at);

-- SECURITY DEFINER helper avoids recursive membership RLS policies.
create or replace function public.is_couple_member(target_couple uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.couple_members
    where couple_id = target_couple and user_id = auth.uid()
  );
$$;
revoke all on function public.is_couple_member(uuid) from public;
grant execute on function public.is_couple_member(uuid) to authenticated;

alter table public.couples enable row level security;
alter table public.couple_members enable row level security;
alter table public.capsules enable row level security;
alter table public.capsule_contents enable row level security;

drop policy if exists "members can view their couple" on public.couples;
create policy "members can view their couple" on public.couples
for select to authenticated using (public.is_couple_member(id));

drop policy if exists "members can view own membership" on public.couple_members;
create policy "members can view own membership" on public.couple_members
for select to authenticated using (public.is_couple_member(couple_id));

drop policy if exists "members can view capsules" on public.capsules;
create policy "members can view capsules" on public.capsules
for select to authenticated using (public.is_couple_member(couple_id));

drop policy if exists "members can create capsules" on public.capsules;
create policy "members can create capsules" on public.capsules
for insert to authenticated with check (
  public.is_couple_member(couple_id) and created_by = auth.uid()
);

drop policy if exists "members can read unlocked capsule content" on public.capsule_contents;
create policy "members can read unlocked capsule content" on public.capsule_contents
for select to authenticated using (
  exists (
    select 1 from public.capsules c
    where c.id = capsule_id
      and public.is_couple_member(c.couple_id)
      and c.opens_at <= (now() at time zone 'utc')::date
  )
);

drop policy if exists "members can add capsule content" on public.capsule_contents;
create policy "members can add capsule content" on public.capsule_contents
for insert to authenticated with check (
  exists (
    select 1 from public.capsules c
    where c.id = capsule_id and public.is_couple_member(c.couple_id)
  )
);

-- Intentionally no client UPDATE/DELETE policies. Add controlled admin workflows later.
grant select on public.couples, public.couple_members, public.capsules, public.capsule_contents to authenticated;
grant insert on public.capsules, public.capsule_contents to authenticated;

-- SETUP AFTER BOTH PEOPLE HAVE SIGNED UP:
-- 1) In Authentication > Users, copy both user UUIDs.
-- 2) Run this block, replacing the two UUIDs. Save the returned couple id.
--
-- insert into public.couples(name) values ('Dear, Us') returning id;
-- insert into public.couple_members(couple_id,user_id) values
-- ('PASTE-COUPLE-UUID','PASTE-FIRST-USER-UUID'),
-- ('PASTE-COUPLE-UUID','PASTE-SECOND-USER-UUID');
