-- Enable required extension
create extension if not exists pgcrypto;

-- 1) Drivers table
create table if not exists public.cab_drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone_number text not null default '',
  car_model text not null default 'Sedan',
  car_number text not null default '',
  profile_image_url text not null default '',
  rating numeric(3,2) not null default 4.5,
  latitude double precision not null,
  longitude double precision not null,
  is_available boolean not null default true,
  completed_rides integer not null default 0,
  license_number text not null default '',
  updated_at timestamptz not null default now()
);

-- 2) Bookings table
create table if not exists public.cab_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  driver_id uuid not null references public.cab_drivers(id) on delete restrict,
  pickup_lat double precision not null,
  pickup_lng double precision not null,
  pickup_address text not null,
  status text not null default 'booked',
  created_at timestamptz not null default now()
);

-- 3) In-app notifications table
create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  booking_id uuid null references public.cab_bookings(id) on delete set null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- Helpful indexes
create index if not exists idx_cab_drivers_available on public.cab_drivers(is_available);
create index if not exists idx_cab_bookings_user_created on public.cab_bookings(user_id, created_at desc);
create index if not exists idx_notifications_user_created on public.app_notifications(user_id, created_at desc);

-- RLS
alter table public.cab_drivers enable row level security;
alter table public.cab_bookings enable row level security;
alter table public.app_notifications enable row level security;

-- Drivers are readable by authenticated users
drop policy if exists "drivers_select_authenticated" on public.cab_drivers;
create policy "drivers_select_authenticated"
on public.cab_drivers
for select
to authenticated
using (true);

-- Optional: only service role can modify drivers
drop policy if exists "drivers_mutation_service_role" on public.cab_drivers;
create policy "drivers_mutation_service_role"
on public.cab_drivers
for all
to service_role
using (true)
with check (true);

-- Users can view/insert only their own bookings
drop policy if exists "bookings_select_own" on public.cab_bookings;
create policy "bookings_select_own"
on public.cab_bookings
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "bookings_insert_own" on public.cab_bookings;
create policy "bookings_insert_own"
on public.cab_bookings
for insert
to authenticated
with check (auth.uid() = user_id);

-- Users can view/insert only their own notifications
drop policy if exists "notifications_select_own" on public.app_notifications;
create policy "notifications_select_own"
on public.app_notifications
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "notifications_insert_own" on public.app_notifications;
create policy "notifications_insert_own"
on public.app_notifications
for insert
to authenticated
with check (auth.uid() = user_id);

-- Seed 5 sample nearby drivers (Delhi sample coordinates; change as needed)
insert into public.cab_drivers
(name, phone_number, car_model, car_number, rating, latitude, longitude, is_available, completed_rides, license_number)
values
('Amit Sharma', '9990011111', 'Swift Dzire', 'DL01AB1234', 4.8, 28.6139, 77.2090, true, 420, 'LIC-1001'),
('Rohan Verma', '9990022222', 'Hyundai Aura', 'DL02CD5678', 4.7, 28.6170, 77.2105, true, 380, 'LIC-1002'),
('Karan Mehta', '9990033333', 'WagonR', 'DL03EF9012', 4.6, 28.6112, 77.2030, true, 295, 'LIC-1003'),
('Imran Khan', '9990044444', 'Honda Amaze', 'DL04GH3456', 4.9, 28.6202, 77.2151, true, 510, 'LIC-1004'),
('Sandeep Yadav', '9990055555', 'Tigor', 'DL05IJ7890', 4.5, 28.6085, 77.2067, true, 210, 'LIC-1005')
on conflict do nothing;