-- Applied to Megjet Supabase on 2026-09-23. Keep this script for fresh databases.
-- Order status is enforced in the database, including calls that bypass the webpage.
create or replace function public.megjet_enforce_order_status()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  if not (
    (old.status = 'pending' and new.status in ('confirmed','cancelled')) or
    (old.status = 'confirmed' and new.status in ('preparing','cancelled')) or
    (old.status = 'preparing' and new.status in ('ready_for_pickup','cancelled')) or
    (old.status = 'ready_for_pickup' and new.status in ('out_for_delivery','cancelled')) or
    (old.status = 'out_for_delivery' and new.status in ('delivered','cancelled'))
  ) then
    raise exception 'Invalid order status transition: % to %',old.status,new.status;
  end if;

  if new.status = 'out_for_delivery' and not exists (
    select 1 from public.order_riders r where r.order_id = new.id
  ) then
    raise exception 'Assign a rider before sending the order out for delivery';
  end if;

  if new.status = 'delivered' and not exists (
    select 1 from public.delivery_security d
    join public.order_riders r on r.order_id = new.id
      and r.rider_id::text = d.rider_id
    where d.order_id = new.id::text and d.pin_verified_at is not null
  ) then
    raise exception 'Assigned rider must verify the delivery PIN first';
  end if;

  return new;
end;
$$;

drop trigger if exists megjet_enforce_order_status on public.orders;
create trigger megjet_enforce_order_status
before update of status on public.orders
for each row execute function public.megjet_enforce_order_status();

-- Legacy single-argument delivery RPCs bypass the PIN and must stay private.
-- The active rider_complete_delivery(text,text,text) RPC calls the internal helper
-- as a definer, after checking the PIN and rider assignment.
revoke execute on function public.rider_complete_delivery(uuid) from public, anon, authenticated;
revoke execute on function public.rider_mark_order_delivered(uuid) from public, anon, authenticated;
