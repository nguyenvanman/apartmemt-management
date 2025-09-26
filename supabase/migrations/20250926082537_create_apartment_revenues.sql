create table public.apartment_revenues (
  id uuid primary key default gen_random_uuid(),
  apartment_id uuid not null references public.apartments(id) on delete cascade,
  cycle_month int not null check (cycle_month between 1 and 12),
  cycle_year int not null check (cycle_year >= 2000),
  total_revenue numeric(15,2) not null default 0,
  fixed_cost numeric(15,2) not null default 0,
  revenue_after_fixed_cost numeric(15,2) not null default 0,
  operating_cost numeric(15,2) not null default 0,
  investor_revenue numeric(15,2) not null default 0,
  advance_payment numeric(15,2) not null default 0,
  investor_profit numeric(15,2) not null default 0,
  investor_total_income numeric(15,2) not null default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(apartment_id, cycle_month, cycle_year)
);

create type apartment_revenue_detail_type as enum ('fixed_cost', 'advance_payment');

create table public.apartment_revenue_details (
  id uuid primary key default gen_random_uuid(),
  description text not null,
  amount numeric(15,2) not null default 0,
  note text,
  type apartment_revenue_detail_type not null,
  apartment_revenue_id uuid not null references public.apartment_revenues(id) on delete cascade,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
