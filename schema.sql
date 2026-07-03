-- SQL Schema for IEEE Event Keeper

-- 1. Create Profiles Table (linked to Auth.Users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  email text not null,
  photo_url text,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Profiles
alter table public.profiles enable row level security;

-- Profiles Policies
create policy "Public profiles are viewable by everyone." on public.profiles
  for select using (true);

create policy "Users can update their own profile." on public.profiles
  for update using (auth.uid() = id);

create policy "Admins can update any profile." on public.profiles
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- 2. Create Categories Table
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  name text unique not null,
  color text not null -- Hex code, e.g., '#FF0000'
);

-- Enable RLS on Categories
alter table public.categories enable row level security;

-- Categories Policies
create policy "Categories are viewable by everyone" on public.categories
  for select using (true);

create policy "Only Admins can modify categories" on public.categories
  for all using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- 3. Create Events Table
create table public.events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  venue text not null,
  organizer text not null,
  start_datetime timestamp with time zone not null,
  end_datetime timestamp with time zone not null,
  category_id uuid references public.categories(id) on delete set null,
  banner_url text,
  registration_link text,
  max_participants integer,
  is_pinned boolean default false not null,
  is_approved boolean default true not null,
  created_by uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Events
alter table public.events enable row level security;

-- Events Policies
create policy "Events are viewable by everyone" on public.events
  for select using (true);

create policy "Authenticated users can create events" on public.events
  for insert with check (auth.uid() is not null);

create policy "Users can update their own events" on public.events
  for update using (
    auth.uid() = created_by or
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

create policy "Users can delete their own events" on public.events
  for delete using (
    auth.uid() = created_by or
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- 4. Trigger for Profile Creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, photo_url, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data->>'avatar_url',
    case
      -- Pre-define admins by email if needed, default to 'user'
      when new.email in ('admin@ieee.org', 'admin@gmail.com') then 'admin'
      else 'user'
    end
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 5. Insert Predefined Categories
insert into public.categories (name, color) values
  ('Workshops', '#2196F3'),      -- Blue
  ('Conferences', '#9C27B0'),    -- Purple
  ('Seminars', '#4CAF50'),       -- Green
  ('Networking', '#FF9800'),     -- Orange
  ('Competitions', '#F44336'),   -- Red
  ('Other', '#607D8B')           -- Blue Grey
on conflict (name) do nothing;

-- 6. Enable Realtime Replication
begin;
  -- Remove the table if it's already there
  alter publication supabase_realtime drop table if exists public.events;
  -- Add table to publication
  alter publication supabase_realtime add table public.events;
commit;
