create table public.flower_requests (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null default auth.uid() references auth.users(id),
 customer_name text not null check(length(customer_name) between 1 and 100), phone text not null check(length(phone) between 7 and 30),
 occasion text not null check(length(occasion) between 1 and 100), budget numeric not null check(budget>0 and budget<=1000000),
 preferred_date date not null check(preferred_date>=date '2026-10-05'), details text not null default '' check(length(details)<=2000),
 created_at timestamptz not null default now()
);
create table public.flower_quotes (
 id uuid primary key default gen_random_uuid(), request_id uuid not null references public.flower_requests(id),
 total numeric not null check(total>0 and total<=1000000), delivery_time text not null check(length(delivery_time) between 1 and 200),
 notes text not null default '' check(length(notes)<=2000), created_at timestamptz not null default now()
);
create table public.flower_acceptances (
 quote_id uuid primary key references public.flower_quotes(id), request_id uuid not null unique references public.flower_requests(id), customer_id uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now()
);
alter table public.flower_requests enable row level security;
alter table public.flower_quotes enable row level security;
alter table public.flower_acceptances enable row level security;
revoke all on public.flower_requests,public.flower_quotes,public.flower_acceptances from anon,authenticated;
grant select,insert on public.flower_requests,public.flower_quotes,public.flower_acceptances to authenticated;
create policy flower_requests_read on public.flower_requests for select to authenticated using(customer_id=auth.uid() or public.megjet_is_admin());
create policy flower_requests_create on public.flower_requests for insert to authenticated with check(customer_id=auth.uid() and preferred_date >= (now() at time zone 'Asia/Famagusta')::date);
create policy flower_quotes_read on public.flower_quotes for select to authenticated using(exists(select 1 from public.flower_requests r where r.id=request_id and (r.customer_id=auth.uid() or public.megjet_is_admin())));
create policy flower_quotes_admin_create on public.flower_quotes for insert to authenticated with check(public.megjet_is_admin());
create policy flower_acceptances_read on public.flower_acceptances for select to authenticated using(customer_id=auth.uid() or public.megjet_is_admin());
create policy flower_acceptances_create on public.flower_acceptances for insert to authenticated with check(customer_id=auth.uid() and exists(select 1 from public.flower_quotes q join public.flower_requests r on r.id=q.request_id where q.id=quote_id and r.id=flower_acceptances.request_id and r.customer_id=auth.uid() and not exists(select 1 from public.flower_quotes newer where newer.request_id=r.id and newer.created_at>q.created_at)));
create index flower_requests_customer_idx on public.flower_requests(customer_id,created_at desc);
create index flower_quotes_request_idx on public.flower_quotes(request_id,created_at desc);
