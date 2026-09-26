-- Exact restaurant pickup pins are private to Admin and riders assigned an order.
create table if not exists public.vendor_pickup_pins (
  vendor_id uuid primary key references public.vendors(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  updated_at timestamptz not null default now()
);
alter table public.vendor_pickup_pins enable row level security;
grant select, insert, update, delete on public.vendor_pickup_pins to authenticated;
revoke all on public.vendor_pickup_pins from anon;

create policy "Admin manages pickup pins" on public.vendor_pickup_pins
  for all to authenticated using ((select public.megjet_is_admin()))
  with check ((select public.megjet_is_admin()));

create policy "Assigned riders see pickup pins" on public.vendor_pickup_pins
  for select to authenticated using (exists (
    select 1 from public.order_items item
    join public.order_riders assignment on assignment.order_id=item.order_id
    join public.rider_users rider on rider.rider_id=assignment.rider_id
    where item.vendor_id=vendor_pickup_pins.vendor_id
      and rider.user_id=(select auth.uid())
  ));
