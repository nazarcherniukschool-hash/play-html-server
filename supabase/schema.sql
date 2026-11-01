
-- PLAY HTML DATABASE

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Гравець',
  role text not null default 'user'
    check (role in ('user', 'author')),
  created_at timestamptz not null default now()
);

create table public.games (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  title text not null,
  description text not null default '',
  category text not null default 'Інше',
  storage_path text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create table public.creator_codes (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null unique references public.profiles(id),
  code text not null unique,
  created_at timestamptz not null default now()
);

create table public.author_supports (
  supporter_id uuid primary key references public.profiles(id),
  author_id uuid not null references public.profiles(id),
  started_at timestamptz not null default now(),
  check (supporter_id <> author_id)
);

create table public.gem_ledger (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  supporter_id uuid references public.profiles(id),
  amount integer not null,
  reason text not null,
  earning_date date,
  created_at timestamptz not null default now(),
  unique (author_id, supporter_id, earning_date)
);

create table public.admin_notifications (
  id uuid primary key default gen_random_uuid(),
  game_id uuid references public.games(id) on delete cascade,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.admin_logs (
  id uuid primary key default gen_random_uuid(),
  action text not null,
  target_user_id uuid references public.profiles(id),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Create a profile automatically after registration
create or replace function public.create_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'username', ''),
      'Гравець'
    )
  );

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.create_user_profile();

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.games enable row level security;
alter table public.creator_codes enable row level security;
alter table public.author_supports enable row level security;
alter table public.gem_ledger enable row level security;
alter table public.admin_notifications enable row level security;
alter table public.admin_logs enable row level security;

-- Profiles: users can see their own profile
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));

-- Users can change only their username
revoke update on public.profiles from authenticated;
grant update (username) on public.profiles to authenticated;

create policy "Users can update own username"
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- Approved games are public; owners can see their submissions
create policy "Read approved games or own games"
on public.games
for select
to anon, authenticated
using (
  status = 'approved'
  or owner_id = (select auth.uid())
);

-- Users can submit games, but submissions start as pending
grant insert (owner_id, title, description, category, storage_path)
on public.games to authenticated;

create policy "Users can submit their own games"
on public.games
for insert
to authenticated
with check (
  owner_id = (select auth.uid())
  and status = 'pending'
);

-- Other sensitive tables are managed only by the server
-- using the Supabase service-role key.
