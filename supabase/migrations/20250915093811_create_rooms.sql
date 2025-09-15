create table public.rooms (
    id uuid primary key default gen_random_uuid(),
    room_code varchar(50) not null unique,
    status varchar(50) not null check (status in ('booked', 'rented', 'available')),
    rent_price numeric(10,2) not null,
    type varchar(255),
    room_type varchar(255),
    facilities text[],
    apartment_id uuid not null references public.apartments(id) on delete cascade,
    capacity integer,
    image_urls text[],
    area numeric(10,2),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

alter table public.rooms enable row level security;

create policy "allow authenticated users to access their rooms" on public.rooms
for all
to authenticated
using (
  exists (
    select 1
    from public.apartments a
    where a.id = rooms.apartment_id
    and a.user_id = (select auth.uid())
  )
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role')::public.user_role = 'super_admin'
);

create index if not exists idx_room_apartment_id on public.rooms (apartment_id);