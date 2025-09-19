create type public.user_role as enum ('super_admin', 'apartment_manager');

create table public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  email varchar(255),
  name varchar(255),
  phone_number varchar(20),
  created_at timestamptz default now()
);

alter table public.user_profiles enable row level security;

create policy "allow authenticated users to access their profiles" on public.user_profiles
for all
to authenticated
using (
  user_id = (select auth.uid())
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role')::public.user_role = 'super_admin'
);

create or replace function public.set_app_metadata_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.raw_app_meta_data := jsonb_set(
    coalesce(new.raw_app_meta_data, '{}'::jsonb),
    '{role}',
    to_jsonb('apartment_manager'::text),
    true
  );
  return new;
end;
$$;

drop trigger if exists set_app_metadata_role on auth.users;
create trigger set_app_metadata_role
before insert on auth.users
for each row execute function public.set_app_metadata_role();

create or replace function public.handle_new_user_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.user_profiles (user_id, role, email, name, phone_number)
  values (new.id, 'apartment_manager', new.email, new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'phone_number')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_role on auth.users;
create trigger on_auth_user_created_role
after insert on auth.users
for each row execute function public.handle_new_user_role();

create or replace function public.update_user_metadata_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update auth.users
  set raw_app_meta_data = jsonb_set(
    coalesce(raw_app_meta_data, '{}'::jsonb),
    '{role}',
    to_jsonb(new.role::text),
    true
  )
  where id = new.user_id;
  return new;
end;
$$;

drop trigger if exists update_user_metadata_role_trigger on public.user_profiles;
create trigger update_user_metadata_role_trigger
after update on public.user_profiles
for each row
when (old.role is distinct from new.role)
execute function public.update_user_metadata_role();