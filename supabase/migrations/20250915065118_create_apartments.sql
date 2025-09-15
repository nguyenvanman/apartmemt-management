create table public.apartments (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references auth.users (id) on delete cascade,
    building_name varchar(255) not null,
    area varchar(100),
    address varchar(255),
    type varchar(255),
    rent_price_min numeric(10,2),
    rent_price_max numeric(10,2),
    service_fee varchar(255),
    payment_method varchar(255),
    deposit_method varchar(255),
    room_types text[],
    facilities text[],
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

alter table public.apartments enable row level security;

create policy "allow authenticated users to access their apartments" on
public.apartments
for all
to authenticated
using (
  user_id = (select auth.uid())
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role')::public.user_role = 'super_admin'
);