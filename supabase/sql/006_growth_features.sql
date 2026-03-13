-- Additional growth features tables

create table if not exists public.portfolio_checklists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  title text not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.interview_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question text not null,
  answer text,
  mock_feedback text,
  created_at timestamptz not null default now()
);

create table if not exists public.resume_versions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  company text not null,
  version_label text not null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_name text not null,
  log_date date not null,
  minutes int not null default 0,
  created_at timestamptz not null default now(),
  unique(user_id, habit_name, log_date)
);

alter table public.portfolio_checklists enable row level security;
alter table public.interview_cards enable row level security;
alter table public.resume_versions enable row level security;
alter table public.habit_logs enable row level security;

create policy "portfolio_owner_all" on public.portfolio_checklists
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "interview_owner_all" on public.interview_cards
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "resume_owner_all" on public.resume_versions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "habit_owner_all" on public.habit_logs
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
