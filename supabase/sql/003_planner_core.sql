-- GUICULUM core: roadmap -> curriculum -> todo

create table if not exists public.roadmaps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  target_role text not null,
  title text not null,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.curriculums (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  roadmap_id uuid not null references public.roadmaps(id) on delete cascade,
  title text not null,
  start_date date not null,
  end_date date not null,
  created_at timestamptz not null default now()
);

create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  curriculum_id uuid not null references public.curriculums(id) on delete cascade,
  title text not null,
  status text not null default 'todo' check (status in ('todo','in_progress','done')),
  priority text not null default 'medium' check (priority in ('low','medium','high')),
  due_date date,
  created_at timestamptz not null default now()
);

alter table public.roadmaps enable row level security;
alter table public.curriculums enable row level security;
alter table public.todos enable row level security;

create policy "roadmaps_owner_all"
on public.roadmaps
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "curriculums_owner_all"
on public.curriculums
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "todos_owner_all"
on public.todos
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
