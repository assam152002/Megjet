-- Keep the existing PIN and rider-assignment checks in the internal 3-argument
-- delivery function. The exposed 4-argument version also records collection.
create or replace function public.rider_complete_delivery(
  p_order_id text, p_pin text, p_proof_photo_url text, p_pos_paid boolean
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_method text;
  v_result jsonb;
begin
  select payment_method into v_method
  from public.orders where id = p_order_id::uuid for update;
  if v_method is null then raise exception 'Order not found'; end if;
  if v_method = 'Card at Doorstep (POS)' and p_pos_paid is distinct from true then
    raise exception 'Confirm successful payment on the physical POS terminal';
  end if;

  -- This function verifies the assigned rider, PIN, order status and delivery.
  v_result := public.rider_complete_delivery(p_order_id,p_pin,p_proof_photo_url);
  update public.orders set payment_status = 'paid'
  where id = p_order_id::uuid and status = 'delivered';
  return v_result;
end;
$$;

revoke execute on function public.rider_complete_delivery(text,text,text) from public, anon, authenticated;
revoke execute on function public.rider_complete_delivery(text,text,text,boolean) from public, anon;
grant execute on function public.rider_complete_delivery(text,text,text,boolean) to authenticated;
