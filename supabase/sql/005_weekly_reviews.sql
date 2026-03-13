create table if not exists public.weekly_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  week_label text not null,
  wins text,
  lows text,
  next_plan text,
  created_at timestamptz not null default now()
);

alter table public.weekly_reviews enable row level security;

create policy "weekly_reviews_owner_all"
on public.weekly_reviews
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
