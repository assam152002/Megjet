-- Product choices are validated and priced from database configuration.
create table if not exists public.product_options (
  product_id uuid primary key references public.products(id) on delete cascade,
  groups jsonb not null check (jsonb_typeof(groups)='array')
);
alter table public.product_options enable row level security;
grant select on public.product_options to anon,authenticated;
grant insert,update,delete on public.product_options to authenticated;
create policy "Read menu choices" on public.product_options for select to anon,authenticated using (true);
create policy "Admin manages menu choices" on public.product_options for all to authenticated
  using ((select public.megjet_is_admin())) with check ((select public.megjet_is_admin()));
alter table public.order_items add column if not exists customizations jsonb not null default '{}'::jsonb;

create or replace function public.megjet_canonical_choices(p_choices jsonb)
returns jsonb language plpgsql immutable set search_path='' as $$
declare k text; v jsonb; result jsonb:='{}'; normalized jsonb;
begin
  if p_choices is null then return result; end if;
  if jsonb_typeof(p_choices)<>'object' then raise exception 'Invalid item choices'; end if;
  for k,v in select * from jsonb_each(p_choices) loop
    if jsonb_typeof(v)<>'array' then raise exception 'Invalid choice group'; end if;
    if exists(select 1 from jsonb_array_elements(v) x where jsonb_typeof(x)<>'string') then raise exception 'Invalid choice'; end if;
    select coalesce(jsonb_agg(x order by x),'[]') into normalized from jsonb_array_elements(v) x;
    result:=result||jsonb_build_object(k,normalized);
  end loop;
  return result;
end;
$$;

create or replace function public.megjet_validate_item_choices()
returns trigger language plpgsql set search_path='' as $$
declare groups jsonb; g jsonb; selected jsonb; choice jsonb; choice_id text;
  extra numeric:=0; summary text:=''; group_summary text; n integer;
begin
  new.customizations:=public.megjet_canonical_choices(new.customizations);
  select o.groups into groups from public.product_options o where o.product_id=new.product_id;
  if groups is null then
    if new.customizations<>'{}'::jsonb then raise exception 'This item does not offer choices'; end if;
    return new;
  end if;
  if exists(select 1 from jsonb_object_keys(new.customizations) k where not exists(
    select 1 from jsonb_array_elements(groups) x where x->>'id'=k
  )) then raise exception 'Unknown choice group'; end if;
  for g in select * from jsonb_array_elements(groups) loop
    selected:=coalesce(new.customizations->(g->>'id'),'[]'::jsonb);
    n:=jsonb_array_length(selected);
    if n<(g->>'min')::integer or n>(g->>'max')::integer then
      raise exception 'Choose the required options for %',g->>'label_en';
    end if;
    if n<>(select count(distinct x) from jsonb_array_elements_text(selected) x) then raise exception 'Duplicate choice'; end if;
    group_summary:='';
    for choice_id in select * from jsonb_array_elements_text(selected) loop
      select x into choice from jsonb_array_elements(g->'choices') x where x->>'id'=choice_id;
      if choice is null then raise exception 'Unknown choice'; end if;
      extra:=extra+coalesce((choice->>'extra')::numeric,0);
      group_summary:=concat_ws(', ',nullif(group_summary,''),choice->>'label_en');
    end loop;
    summary:=concat_ws(' · ',nullif(summary,''),(g->>'label_en')||': '||coalesce(nullif(group_summary,''),'None'));
  end loop;
  new.product_name:=new.product_name||' ['||summary||']';
  new.unit_price:=new.unit_price+extra;
  new.price:=new.unit_price;
  new.total_price:=new.unit_price*new.quantity;
  return new;
end;
$$;
create trigger zz_megjet_validate_item_choices before insert or update on public.order_items
for each row execute function public.megjet_validate_item_choices();

CREATE OR REPLACE FUNCTION public.create_customer_order(p_order_id uuid, p_customer_name text, p_customer_phone text, p_delivery_address text, p_payment_method text, p_coupon_code text DEFAULT NULL::text, p_items jsonb DEFAULT '[]'::jsonb)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
 SET row_security TO 'off'
AS $function$
DECLARE
item jsonb;
v_subtotal numeric := 0;
v_discount numeric := 0;
v_total numeric := 0;
v_delivery numeric := 0;
v_count integer := 0;
BEGIN
IF p_order_id IS NULL THEN
RAISE EXCEPTION 'Invalid order ID';
END IF;
IF NULLIF(trim(p_customer_name),'') IS NULL
OR NULLIF(trim(p_customer_phone),'') IS NULL
OR NULLIF(trim(p_delivery_address),'') IS NULL THEN
RAISE EXCEPTION 'Name, phone and delivery address are required';
END IF;
IF p_payment_method NOT IN ('Cash on Delivery', 'Card at Doorstep (POS)') THEN
RAISE EXCEPTION 'Invalid payment method';
END IF;
IF jsonb_typeof(p_items) <> 'array'
OR jsonb_array_length(p_items) = 0 THEN
RAISE EXCEPTION 'Cart is empty';
END IF;
IF EXISTS (
SELECT 1
FROM public.orders
WHERE id = p_order_id
) THEN
RAISE EXCEPTION 'Order already exists';
END IF;
INSERT INTO public.orders (
id,
customer_name,
customer_phone,
delivery_address,
payment_method,
delivery_fee,
discount_amount,
coupon_code,
total,
status,
payment_status
)
VALUES (
p_order_id,
trim(p_customer_name),
trim(p_customer_phone),
trim(p_delivery_address),
p_payment_method,
v_delivery,
0,
NULLIF(trim(p_coupon_code),''),
v_delivery,
'pending',
'pending'
);
FOR item IN SELECT * FROM jsonb_array_elements(p_items)
LOOP
IF (item->>'product_id') IS NULL
OR (item->>'quantity')::integer < 1 THEN
RAISE EXCEPTION 'Invalid cart item';
END IF;
INSERT INTO public.order_items (
order_id,
product_id,
quantity,
customizations
)
VALUES (
p_order_id,
(item->>'product_id')::uuid,
(item->>'quantity')::integer,
coalesce(item->'customizations','{}'::jsonb)
);
v_count := v_count + 1;
END LOOP;
SELECT COALESCE(SUM(total_price),0)
INTO v_subtotal
FROM public.order_items
WHERE order_id = p_order_id;
IF v_count = 0 OR v_subtotal <= 0 THEN
DELETE FROM public.orders WHERE id = p_order_id;
RAISE EXCEPTION 'No valid products in cart';
END IF;
IF NULLIF(trim(p_coupon_code),'') IS NOT NULL THEN
v_discount := public.calculate_coupon_discount(
trim(p_coupon_code),
v_subtotal
);
END IF;
v_discount := LEAST(
GREATEST(COALESCE(v_discount,0),0),
v_subtotal + v_delivery
);
v_total := GREATEST(
0,
v_subtotal + v_delivery - v_discount
);
UPDATE public.orders
SET
subtotal = v_subtotal,
discount_amount = v_discount,
total = v_total
WHERE id = p_order_id;
RETURN json_build_object(
'success', true,
'order_id', p_order_id,
'subtotal', v_subtotal,
'delivery_fee', v_delivery,
'discount_amount', v_discount,
'total', v_total
);
END;
$function$;
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
    jsonb_build_object('product_id',oi.product_id::text,'quantity',oi.quantity,'customizations',oi.customizations)
    order by oi.product_id,oi.quantity,oi.customizations::text
  ),'[]'::jsonb) into original_items
  from public.order_items oi where oi.order_id=p_order_id;

  select coalesce(jsonb_agg(
    jsonb_build_object('product_id',(i.item->>'product_id')::uuid::text,'quantity',(i.item->>'quantity')::integer,'customizations',public.megjet_canonical_choices(i.item->'customizations'))
    order by (i.item->>'product_id')::uuid,(i.item->>'quantity')::integer,public.megjet_canonical_choices(i.item->'customizations')::text
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
