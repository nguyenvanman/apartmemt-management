alter table public.rooms
drop constraint if exists rooms_room_code_key;

alter table public.rooms
add constraint rooms_room_code_apartment_id_key unique (room_code, apartment_id);
