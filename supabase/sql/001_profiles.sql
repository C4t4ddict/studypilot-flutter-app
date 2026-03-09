create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  nickname text not null,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- 검색 데모용 공개 테이블(포트폴리오 프로토타입)
create table if not exists public.search_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  created_at timestamptz not null default now()
);

alter table public.search_items enable row level security;

create policy "search_items_select_all"
on public.search_items
for select
using (true);
