-- Applied to Megjet Supabase on 2026-09-23. Run after workflow_protection.sql.
-- A repeated request with the same UUID returns the original order only when
-- the customer identity, checkout details, and cart match exactly.
create or replace function public.create_customer_order_retry(
  p_order_id uuid,
  p_customer_name text,
  p_customer_phone text,
  p_delivery_address text,
  p_payment_method text,
  p_coupon_code text,
  p_items jsonb
) returns json
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing public.orders%rowtype;
  original_items jsonb;
  requested_items jsonb;
begin
  if p_order_id is null then raise exception 'Invalid order ID'; end if;
  select * into existing from public.orders where id=p_order_id;
  if not found then
    begin
      return public.create_customer_order_account(
        p_order_id,p_customer_name,p_customer_phone,p_delivery_address,
        p_payment_method,p_coupon_code,p_items
      );
    exception when others then
      select * into existing from public.orders where id=p_order_id;
      if not found then raise; end if;
    end;
  end if;

  if trim(coalesce(existing.customer_name,'')) is distinct from trim(coalesce(p_customer_name,''))
     or trim(coalesce(existing.customer_phone,'')) is distinct from trim(coalesce(p_customer_phone,''))
     or trim(coalesce(existing.delivery_address,'')) is distinct from trim(coalesce(p_delivery_address,''))
     or existing.payment_method is distinct from p_payment_method
     or coalesce(existing.coupon_code,'') is distinct from coalesce(nullif(trim(p_coupon_code),''),'')
     or existing.auth_user_id is distinct from auth.uid()
  then
    raise exception 'This order ID belongs to a different checkout';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object('product_id',oi.product_id::text,'quantity',oi.quantity)
    order by oi.product_id,oi.quantity
  ),'[]'::jsonb) into original_items
  from public.order_items oi where oi.order_id=p_order_id;

  select coalesce(jsonb_agg(
    jsonb_build_object('product_id',(i.item->>'product_id')::uuid::text,'quantity',(i.item->>'quantity')::integer)
    order by (i.item->>'product_id')::uuid,(i.item->>'quantity')::integer
  ),'[]'::jsonb) into requested_items
  from jsonb_array_elements(p_items) as i(item);

  if original_items is distinct from requested_items then
    raise exception 'This order ID belongs to a different cart';
  end if;
  return json_build_object(
    'success',true,'order_id',p_order_id,'status',existing.status,
    'replayed',true,'total',existing.total
  );
end;
$$;
revoke execute on function public.create_customer_order_retry(uuid,text,text,text,text,text,jsonb) from public;
grant execute on function public.create_customer_order_retry(uuid,text,text,text,text,text,jsonb) to anon, authenticated;
