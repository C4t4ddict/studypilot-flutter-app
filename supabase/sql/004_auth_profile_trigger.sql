-- Ensure profile row is created automatically when a new Supabase Auth user is created
-- Works for Google OAuth signup/login and email/password signup

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, nickname)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'name', split_part(coalesce(new.email, 'user'), '@', 1))
  )
  on conflict (id) do update
    set email = excluded.email,
        nickname = coalesce(public.profiles.nickname, excluded.nickname);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();
