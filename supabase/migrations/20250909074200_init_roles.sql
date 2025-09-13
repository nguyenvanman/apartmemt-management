-- 1. Role enum (only two roles)
create type public.user_role as enum ('super_admin', 'apartment_manager');

-- 2. User roles table
create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  created_at timestamptz default now()
);

-- 3. BEFORE INSERT trigger: inject default role into raw_app_meta_data
create or replace function public.set_app_metadata_role()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  -- Add role = apartment_manager to raw_app_meta_data
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
for each row execute procedure public.set_app_metadata_role();

-- 4. AFTER INSERT trigger: insert into user_roles table
create or replace function public.handle_new_user_role()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.user_roles (user_id, role)
  values (new.id, 'apartment_manager')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_role on auth.users;
create trigger on_auth_user_created_role
after insert on auth.users
for each row execute procedure public.handle_new_user_role();

-- 5. Custom hook for access token generation
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := (event->>'user_id')::uuid;
  role text;
begin
  -- Pull role from user_roles
  select r.role into role
  from public.user_roles r
  where r.user_id = uid;

  if role is not null then
    -- Add role to top-level JWT claims (for RLS policies)
    event := jsonb_set(event, '{claims,role}', to_jsonb(role), true);

    -- Also ensure app_metadata has the role (so it appears in /auth/v1/token response)
    event := jsonb_set(event, '{app_metadata,role}', to_jsonb(role), true);
  end if;

  return event;
end;
$$;
