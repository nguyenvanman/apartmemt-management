create table public.contracts (
  id uuid primary key default gen_random_uuid(),
  contract_code varchar(50) not null unique,
  signed_date date not null,
  rent_price numeric(10,2) not null,
  deposit numeric(10,2) not null default 0,
  tenant_name varchar(255) not null,
  tenant_phone varchar(20) not null,
  room_id uuid not null references public.rooms(id) on delete cascade,
  contract_urls text[] default '{}',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);