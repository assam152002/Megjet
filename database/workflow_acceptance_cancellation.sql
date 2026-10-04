-- Keep assignment separate from pickup; preserve existing role authorization.
create or replace function public.admin_assign_rider_to_order(p_order_id uuid,p_rider_id uuid)
returns json language plpgsql security definer set search_path='' as $$
declare v_status text;
begin
 if not exists(select 1 from public.admin_users where user_id=auth.uid()) then raise exception 'Admin access required';end if;
 select status into v_status from public.orders where id=p_order_id for update;
 if v_status is null then raise exception 'Order not found';end if;
 if v_status<>'ready_for_pickup' then raise exception 'Order must be Ready for Pickup before assigning a rider';end if;
 if not exists(select 1 from public.riders where id=p_rider_id and active=true) then raise exception 'That rider is inactive or no longer exists';end if;
 if exists(select 1 from public.order_riders where order_id=p_order_id) then raise exception 'A rider is already assigned to this order';end if;
 insert into public.order_riders(order_id,rider_id) values(p_order_id,p_rider_id);
 return json_build_object('success',true,'order_id',p_order_id,'rider_id',p_rider_id,'status',v_status);
end $$;
create or replace function public.cancel_customer_order(p_order_id uuid,p_phone text)
returns json language plpgsql security definer set search_path='' as $$
declare updated_order public.orders;
begin
 if length(regexp_replace(coalesce(p_phone,''),'[^0-9]','','g')) not between 8 and 15 then raise exception 'Please enter a valid phone number';end if;
 update public.orders set status='cancelled'
 where id=p_order_id and regexp_replace(coalesce(customer_phone,''),'[^0-9]','','g')=regexp_replace(p_phone,'[^0-9]','','g') and status='pending'
 returning * into updated_order;
 if not found then raise exception 'Order cannot be cancelled. It may not belong to this phone number, or it is no longer Pending.';end if;
 return json_build_object('success',true,'order_id',updated_order.id,'status',updated_order.status);
end $$;
