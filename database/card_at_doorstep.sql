-- Enable physical POS collection without enabling online card payments.
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
quantity
)
VALUES (
p_order_id,
(item->>'product_id')::uuid,
(item->>'quantity')::integer
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

-- Both choices are collected in person. Online card payments remain unavailable.
alter table public.orders drop constraint if exists orders_cash_on_delivery_only;
alter table public.orders add constraint orders_pay_at_door_only
  check (payment_method in ('Cash on Delivery','Card at Doorstep (POS)'));

create or replace function public.megjet_validate_order_checkout()
returns trigger language plpgsql set search_path = '' as $$
begin
  if length(trim(coalesce(new.customer_name,''))) < 2 then
    raise exception 'Please enter your full name';
  end if;
  if length(regexp_replace(coalesce(new.customer_phone,''),'[^0-9]','','g')) not between 8 and 15 then
    raise exception 'Please enter a valid phone number';
  end if;
  if length(trim(coalesce(new.delivery_address,''))) < 8 then
    raise exception 'Please enter a complete delivery address';
  end if;
  if new.payment_method not in ('Cash on Delivery','Card at Doorstep (POS)') then
    raise exception 'Choose an available pay-on-delivery method';
  end if;
  return new;
end;
$$;
