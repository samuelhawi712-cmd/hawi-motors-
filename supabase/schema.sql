create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', phone text not null default '',
 account_type text not null default 'seller' check (account_type in ('seller','dealer','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.listings (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null references auth.users(id) on delete cascade,
 make text not null, model text not null,
 year integer not null check (year between 1950 and 2100),
 price_kes bigint not null check (price_kes > 0),
 mileage_km integer check (mileage_km is null or mileage_km >= 0),
 transmission text not null default 'Not specified',
 fuel text not null default 'Not specified',
 location text not null, description text not null default '',
 contact_phone text not null,
 status text not null default 'pending' check (status in ('pending','approved','rejected','sold')),
 featured_until timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.listing_photos (
 id uuid primary key default gen_random_uuid(),
 listing_id uuid not null references public.listings(id) on delete cascade,
 storage_path text not null, sort_order integer not null default 0, created_at timestamptz not null default now()
);
create index if not exists listings_status_created_idx on public.listings(status, created_at desc);
create index if not exists listings_make_model_idx on public.listings(make, model);
create index if not exists listings_price_idx on public.listings(price_kes);
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.listing_photos enable row level security;
drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles for select to authenticated using (auth.uid() = id);
drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "Anyone reads approved listings" on public.listings;
create policy "Anyone reads approved listings" on public.listings for select to anon, authenticated using (status = 'approved' or auth.uid() = seller_id);
drop policy if exists "Signed-in users create own listings" on public.listings;
create policy "Signed-in users create own listings" on public.listings for insert to authenticated with check (auth.uid() = seller_id);
drop policy if exists "Sellers update own pending listings" on public.listings;
create policy "Sellers update own pending listings" on public.listings for update to authenticated using (auth.uid() = seller_id and status in ('pending','rejected')) with check (auth.uid() = seller_id and status in ('pending','rejected'));
drop policy if exists "Sellers delete own pending listings" on public.listings;
create policy "Sellers delete own pending listings" on public.listings for delete to authenticated using (auth.uid() = seller_id and status in ('pending','rejected'));
drop policy if exists "Read photos for visible listings" on public.listing_photos;
create policy "Read photos for visible listings" on public.listing_photos for select to anon, authenticated using (exists (select 1 from public.listings l where l.id = listing_id and (l.status = 'approved' or l.seller_id = auth.uid())));
drop policy if exists "Sellers add own listing photos" on public.listing_photos;
create policy "Sellers add own listing photos" on public.listing_photos for insert to authenticated with check (exists (select 1 from public.listings l where l.id = listing_id and l.seller_id = auth.uid()));
drop policy if exists "Sellers remove own listing photos" on public.listing_photos;
create policy "Sellers remove own listing photos" on public.listing_photos for delete to authenticated using (exists (select 1 from public.listings l where l.id = listing_id and l.seller_id = auth.uid()));
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('car-photos', 'car-photos', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
drop policy if exists "Public view car photos" on storage.objects;
create policy "Public view car photos" on storage.objects for select to anon, authenticated using (bucket_id = 'car-photos');
drop policy if exists "Sellers upload own car photos" on storage.objects;
create policy "Sellers upload own car photos" on storage.objects for insert to authenticated with check (bucket_id = 'car-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Sellers update own car photos" on storage.objects;
create policy "Sellers update own car photos" on storage.objects for update to authenticated using (bucket_id = 'car-photos' and (storage.foldername(name))[1] = auth.uid()::text) with check (bucket_id = 'car-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "Sellers delete own car photos" on storage.objects;
create policy "Sellers delete own car photos" on storage.objects for delete to authenticated using (bucket_id = 'car-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- Prevent ordinary signed-in users from promoting themselves to dealer/admin.
create or replace function public.prevent_profile_role_escalation()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is not null and new.account_type is distinct from old.account_type then
    raise exception 'Account type changes must be performed by a trusted administrator';
  end if;
  return new;
end;
$$;
drop trigger if exists protect_profile_account_type on public.profiles;
create trigger protect_profile_account_type
before update on public.profiles
for each row execute function public.prevent_profile_role_escalation();
