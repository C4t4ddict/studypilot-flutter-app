-- Demo seed data for search_items
insert into public.search_items (title, subtitle)
values
  ('Flutter Architecture', 'Layered app design and boundaries'),
  ('Supabase Auth Flow', 'OAuth redirect + session lifecycle'),
  ('RLS Policy Design', 'Owner-based read/write policies'),
  ('Reactive Search', 'debounce + distinct + switchMap with RxDart'),
  ('Portfolio ADR Writing', 'Decision/Trade-off documentation'),
  ('GoRouter Patterns', 'Typed route and navigation structure')
on conflict do nothing;
