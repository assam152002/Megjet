-- Assigned riders may read only the restaurant IDs/names for their own order items.
-- Allow access to the pickup address even if a vendor is later deactivated,
-- but only for restaurants in the rider's assigned deliveries.
create policy "Riders view their assigned order items"
on public.order_items for select to authenticated
using (exists (
  select 1 from public.order_riders assignment
  join public.rider_users rider on rider.rider_id=assignment.rider_id
  where assignment.order_id=order_items.order_id
    and rider.user_id=(select auth.uid())
));

create policy "Riders view assigned restaurant pickups"
on public.vendors for select to authenticated
using (exists (
  select 1 from public.order_items item
  join public.order_riders assignment on assignment.order_id=item.order_id
  join public.rider_users rider on rider.rider_id=assignment.rider_id
  where item.vendor_id=vendors.id
    and rider.user_id=(select auth.uid())
));
