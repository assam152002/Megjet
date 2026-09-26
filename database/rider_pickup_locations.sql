-- Assigned riders may read only the restaurant IDs/names for their own order items.
-- Restaurant addresses are already available through the active vendors read policy.
create policy "Riders view their assigned order items"
on public.order_items for select to authenticated
using (exists (
  select 1 from public.order_riders assignment
  join public.rider_users rider on rider.rider_id=assignment.rider_id
  where assignment.order_id=order_items.order_id
    and rider.user_id=(select auth.uid())
));
