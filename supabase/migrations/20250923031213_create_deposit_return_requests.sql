create type deposit_return_status as enum ('pending', 'approved', 'rejected');

create table public.deposit_return_requests (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  contract_id uuid not null references public.contracts(id) on delete cascade,
  reason text,
  account_number varchar(50),
  bank_name varchar(100),
  account_holder varchar(255),
  status deposit_return_status not null default 'pending',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
