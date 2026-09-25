-- No card gateway is connected. Prevent old RPCs and direct writes from
-- recording unsupported payment methods until online payment is implemented.
alter table public.orders
  add constraint orders_cash_on_delivery_only
  check (payment_method is not distinct from 'Cash on Delivery');
