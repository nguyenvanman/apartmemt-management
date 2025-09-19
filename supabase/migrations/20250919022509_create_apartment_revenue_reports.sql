create table public.apartment_revenue_reports (
  id uuid primary key default gen_random_uuid(),
  apartment_id uuid not null references public.apartments(id) on delete cascade,
  month int not null check (month between 1 and 12),
  year int not null check (year >= 2000),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create unique index apartment_revenue_reports_unique
  on public.apartment_revenue_reports (apartment_id, month, year);

alter table public.apartment_revenue_reports enable row level security;

create policy "allow authenticated users to access their revenue reports"
on public.apartment_revenue_reports
for all
to authenticated
using (
  exists (
    select 1
    from public.apartments a
    where a.id = apartment_revenue_reports.apartment_id
    and a.user_id = (select auth.uid())
  )
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role')::public.user_role = 'super_admin'
);
