create table public.bank_transfer_settings (
 id integer primary key check(id=1), bank_name text not null, account_holder text not null,
 iban text not null check(iban ~ '^TR[0-9]{24}$'), currency text not null check(currency='TRY'),
 enabled boolean not null default true
);
alter table public.bank_transfer_settings enable row level security;
grant select on public.bank_transfer_settings to anon,authenticated;
grant update on public.bank_transfer_settings to authenticated;
create policy bank_settings_read on public.bank_transfer_settings for select to anon,authenticated using(true);
create policy bank_settings_admin_update on public.bank_transfer_settings for update to authenticated using(public.megjet_is_admin()) with check(public.megjet_is_admin());
insert into public.bank_transfer_settings values(1,'Halkbank','Mustafa Balsever','TR720001200989900001017278','TRY',true);
alter table public.orders add column bank_transfer_details jsonb, add column bank_verified_at timestamptz, add column bank_verified_by uuid;
alter table public.orders drop constraint orders_pay_at_door_only;
alter table public.orders add constraint orders_supported_payment_methods check(payment_method in ('Cash on Delivery','Card at Doorstep (POS)','Bank Transfer'));
do $patch$
declare d text;
begin
 select pg_get_functiondef('public.create_customer_order(uuid,text,text,text,text,text,jsonb)'::regprocedure) into d;
 d:=replace(d,'''Cash on Delivery'', ''Card at Doorstep (POS)''','''Cash on Delivery'', ''Card at Doorstep (POS)'', ''Bank Transfer''');
 execute d;
 select pg_get_functiondef('public.megjet_validate_order_checkout()'::regprocedure) into d;
 d:=replace(d,'''Cash on Delivery'',''Card at Doorstep (POS)''','''Cash on Delivery'',''Card at Doorstep (POS)'',''Bank Transfer''');
 d:=replace(d,'Choose an available pay-on-delivery method','Choose an available payment method');
 execute d;
 select pg_get_functiondef('public.get_customer_orders_account()'::regprocedure) into d;
 d:=replace(d,'''payment_status'', o.payment_status,','''payment_status'', o.payment_status, ''bank_transfer_details'', o.bank_transfer_details,');
 execute d;
end $patch$;
create function public.megjet_guard_bank_transfer() returns trigger language plpgsql set search_path='' as $fn$
begin
 if tg_op='INSERT' and new.payment_method='Bank Transfer' then
   select jsonb_build_object('bank_name',s.bank_name,'account_holder',s.account_holder,'iban',s.iban,'currency',s.currency)
   into new.bank_transfer_details from public.bank_transfer_settings s where id=1 and enabled;
   if new.bank_transfer_details is null then raise exception 'Bank transfers are temporarily unavailable'; end if;
   new.payment_status:='pending'; new.payment_reference:=null; new.bank_verified_at:=null; new.bank_verified_by:=null;
 elsif tg_op='UPDATE' and (old.payment_method='Bank Transfer' or new.payment_method='Bank Transfer') then
   if new.payment_method is distinct from old.payment_method or new.bank_transfer_details is distinct from old.bank_transfer_details then
     raise exception 'Bank transfer instructions are fixed for this order';
   end if;
   if (new.payment_status is distinct from old.payment_status or new.payment_reference is distinct from old.payment_reference or new.bank_verified_at is distinct from old.bank_verified_at or new.bank_verified_by is distinct from old.bank_verified_by)
      and not public.megjet_is_admin() then raise exception 'Only admin can verify a bank transfer'; end if;
   if new.payment_status='paid' and (nullif(trim(new.payment_reference),'') is null or new.bank_verified_at is null or new.bank_verified_by is null) then
     raise exception 'Record the received transfer before marking it paid';
   end if;
 end if;
 if new.payment_method='Bank Transfer' and new.status not in ('pending','cancelled') and new.payment_status is distinct from 'paid' then
   raise exception 'Verify the bank transfer before confirming or preparing this order';
 end if;
 return new;
end $fn$;
create trigger megjet_bank_transfer_guard before insert or update on public.orders for each row execute function public.megjet_guard_bank_transfer();
create function public.confirm_bank_transfer(p_order_id uuid,p_received_amount numeric,p_reference text)
returns jsonb language plpgsql security invoker set search_path='' as $fn$
declare o public.orders%rowtype;
begin
 if auth.uid() is null or not public.megjet_is_admin() then raise exception 'Admin access required'; end if;
 select * into o from public.orders where id=p_order_id for update;
 if not found or o.payment_method<>'Bank Transfer' then raise exception 'Bank transfer order not found'; end if;
 if o.status='cancelled' then raise exception 'Do not verify a cancelled order'; end if;
 if nullif(trim(p_reference),'') is null or length(p_reference)>200 then raise exception 'Enter the bank transaction reference'; end if;
 if p_received_amount is null or p_received_amount is distinct from o.total then raise exception 'Received amount must match the order total'; end if;
 if o.payment_status='paid' then return jsonb_build_object('success',true,'already_verified',true); end if;
 update public.orders set payment_status='paid',payment_reference=trim(p_reference),bank_verified_at=now(),bank_verified_by=auth.uid() where id=p_order_id;
 return jsonb_build_object('success',true);
end $fn$;
revoke all on function public.confirm_bank_transfer(uuid,numeric,text) from public,anon;
grant execute on function public.confirm_bank_transfer(uuid,numeric,text) to authenticated;
create or replace function public.create_customer_order_retry(p_order_id uuid,p_customer_name text,p_customer_phone text,p_delivery_address text,p_payment_method text,p_coupon_code text,p_items jsonb)
returns json language plpgsql security definer set search_path='' as $fn$
declare existing public.orders%rowtype; original_items jsonb; requested_items jsonb; replayed boolean:=true;
begin
 if p_order_id is null then raise exception 'Invalid order ID'; end if;
 select * into existing from public.orders where id=p_order_id;
 if not found then
  begin
   perform public.create_customer_order_account(p_order_id,p_customer_name,p_customer_phone,p_delivery_address,p_payment_method,p_coupon_code,p_items);
   replayed:=false;
   select * into existing from public.orders where id=p_order_id;
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
 or existing.auth_user_id is distinct from auth.uid() then raise exception 'This order ID belongs to a different checkout'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('product_id',oi.product_id::text,'quantity',oi.quantity,'customizations',oi.customizations) order by oi.product_id,oi.quantity,oi.customizations::text),'[]'::jsonb)
 into original_items from public.order_items oi where oi.order_id=p_order_id;
 select coalesce(jsonb_agg(jsonb_build_object('product_id',(i.item->>'product_id')::uuid::text,'quantity',(i.item->>'quantity')::integer,'customizations',public.megjet_canonical_choices(i.item->'customizations')) order by (i.item->>'product_id')::uuid,(i.item->>'quantity')::integer,public.megjet_canonical_choices(i.item->'customizations')::text),'[]'::jsonb)
 into requested_items from jsonb_array_elements(p_items) i(item);
 if original_items is distinct from requested_items then raise exception 'This order ID belongs to a different cart'; end if;
 return json_build_object('success',true,'order_id',p_order_id,'status',existing.status,'replayed',replayed,'total',existing.total,'payment_method',existing.payment_method,'payment_status',existing.payment_status,'bank_transfer_details',existing.bank_transfer_details);
end $fn$;
