create table if not exists public.room_reports (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references public.rooms(id) on delete cascade,
  apartment_revenue_report_id uuid references public.apartment_revenue_reports(id) on delete cascade,

  num_people int default 0 check (num_people >= 0),     
  contract_start_date date,                                      
  contract_end_date date,                                        

  room_price numeric(15,2) default 0,                   
  deposit_held numeric(15,2) default 0,                 

  elec_meter_new numeric(15,2) default 0,               
  elec_meter_old numeric(15,2) default 0,               
  elec_price numeric(15,2) default 0,                   
  elec_amount numeric(15,2) default 0,                  

  water_amount numeric(15,2) default 0,                 
  wifi_amount numeric(15,2) default 0,                  
  utilities_total numeric(15,2) default 0,              

  extra_deposit numeric(15,2) default 0,                
  actual_room_fee numeric(15,2) default 0,              
  net_received numeric(15,2) default 0,                 

  management_income numeric(15,2) default 0,            
  other_income numeric(15,2) default 0,                 
  service_mgmt_fee numeric(15,2) default 0,             
  management_total numeric(15,2) default 0,             

  note_manager text,                                             
  note_accounting text,                                          

  occupancy_calc boolean default false,                 

  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

create index if not exists idx_room_reports_room_id
  on public.room_reports (room_id);

create index if not exists idx_room_reports_apartment_revenue_report_id
  on public.room_reports (apartment_revenue_report_id);
