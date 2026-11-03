-- Portland apartment finder: database setup
-- Run in Supabase: SQL Editor > New query > paste > Run.
-- Safe to run again: it only adds what's missing.

-- 1. Listings: one row per apartment listing URL
create table if not exists public.listings (
  id             uuid primary key default gen_random_uuid(),
  listing_url    text not null unique,          -- the listing's own page; used to spot repeats
  company        text,                          -- management company, as named in Cara's sheet
  title          text,                          -- the listing's headline
  address        text,
  neighborhood   text,
  rent           integer,                       -- base monthly rent in dollars
  fees_note      text,                          -- e.g. "+$25/mo garbage, $1,600 total"
  beds           numeric,
  baths          numeric,
  sqft           integer,
  property_type  text,                          -- apartment, condo, townhome, ADU, garage apartment...
  floor          text,                          -- what the listing says about the floor, in words
  floor_level    integer,                       -- 1 = ground; null = unknown
  washer_dryer   text check (washer_dryer in ('in_unit','unclear','no')),
  parking        text check (parking in ('yes','unclear','no')),
  parking_note   text,                          -- e.g. "garage, waitlist may apply"
  available_date text,
  contact_phone  text,
  contact_email  text,
  photos         text[] not null default '{}',  -- image URLs from the listing
  description    text,
  match          text check (match in ('strong','unclear')),
  reasons        text[] not null default '{}',  -- what to double-check before applying
  first_seen     date not null default current_date,
  last_seen      date not null default current_date,
  is_active      boolean not null default true, -- false once the listing disappears
  updated_at     timestamptz not null default now()
);

-- 2. Scrape runs: one row per daily check, so the site can show when it last updated
create table if not exists public.scrape_runs (
  id            bigint generated always as identity primary key,
  run_at        timestamptz not null default now(),
  run_date      date not null default current_date,  -- Pacific date of the run
  sites_checked integer,
  sites_failed  jsonb not null default '[]',         -- e.g. [{"company":"Affinity","why":"blocked"}]
  notes         text
);

-- 3. Access rules (Row Level Security): the website may READ, nobody may write with the public key.
--    The daily task writes through the Supabase connector, which uses your own account instead.
alter table public.listings    enable row level security;
alter table public.scrape_runs enable row level security;

drop policy if exists "Website can read listings" on public.listings;
create policy "Website can read listings" on public.listings
  for select to anon, authenticated using (true);

drop policy if exists "Website can read runs" on public.scrape_runs;
create policy "Website can read runs" on public.scrape_runs
  for select to anon, authenticated using (true);

-- 3b. Version 2 additions (safe to run again if you already ran this file once)
alter table public.listings add column if not exists status text not null default 'available'
  check (status in ('available','application_pending','removed'));
alter table public.listings add column if not exists lat double precision;
alter table public.listings add column if not exists lng double precision;

-- Your saves and suppressions. Each row belongs to the signed-in person who made it.
create table if not exists public.marks (
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  listing_url text not null,
  kind        text not null check (kind in ('saved','suppressed')),
  until       date,            -- suppressions: null = permanent, a date = hidden until then
  title       text,            -- snapshot so the Suppressed page still works after a listing is gone
  address     text,
  company     text,
  photo       text,
  created_at  timestamptz not null default now(),
  primary key (user_id, listing_url, kind)
);
alter table public.marks enable row level security;

drop policy if exists "You can see your own marks" on public.marks;
create policy "You can see your own marks" on public.marks
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "You can add your own marks" on public.marks;
create policy "You can add your own marks" on public.marks
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "You can change your own marks" on public.marks;
create policy "You can change your own marks" on public.marks
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "You can remove your own marks" on public.marks;
create policy "You can remove your own marks" on public.marks
  for delete to authenticated using (user_id = auth.uid());

-- Make sure the website is allowed to reach these tables at all (RLS above still decides which rows)
grant select on public.listings, public.scrape_runs to anon, authenticated;
grant select, insert, update, delete on public.marks to authenticated;

-- 4. Starter row so the site has something to show right away (found Nov 2026 on Alpine's site)
insert into public.listings
  (listing_url, company, title, address, rent, fees_note, beds, baths, sqft, property_type,
   floor, floor_level, washer_dryer, parking, parking_note, available_date, contact_phone,
   photos, description, match, reasons, first_seen, last_seen, lat, lng)
values
  ('https://www.alpinepdx.com/_system/listings/77/1415-SE-Pardee-St--409-Portland-OR-97202-US',
   'Alpine', 'Live Modern at The Tristan', '1415 SE Pardee St #409, Portland, OR 97202',
   1575, '+$25/mo garbage, $1,600 total. $600 deposit, $55 app fee', 1, 1, 746, 'Apartment',
   'Unit 409, likely 4th floor', 4, 'in_unit', 'yes', 'Secure garage, waitlist may apply',
   'Immediately', '(971) 458-4999',
   array[
     'https://www.alpinepdx.com/_system/listings/images/1922?size=large',
     'https://www.alpinepdx.com/_system/listings/images/1905?size=large',
     'https://www.alpinepdx.com/_system/listings/images/1906?size=large',
     'https://www.alpinepdx.com/_system/listings/images/1907?size=large',
     'https://www.alpinepdx.com/_system/listings/images/1908?size=large'],
   '2019 building. Open layout with hardwood floors, granite counters and stainless appliances. Private washer and dryer, A/C. Secure entry, bike room, dog wash. Cats OK, dogs up to 40 lbs considered. Matterport tour on the listing.',
   'strong',
   array['Garage parking may have a waitlist', 'Floor is inferred from unit number 409'],
   current_date, current_date, null, null)
on conflict (listing_url) do nothing;
