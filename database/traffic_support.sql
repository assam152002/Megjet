-- Megjet traffic and private guest support chat, 2026-09-26.
-- No IP address, location, device fingerprint or message content enters traffic analytics.
create table if not exists public.app_visit_sessions (
  session_id uuid primary key,
  visitor_id uuid not null,
  referrer_host text not null default '',
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);
create index if not exists app_visit_sessions_first_seen_idx on public.app_visit_sessions(first_seen_at);
create index if not exists app_visit_sessions_last_seen_idx on public.app_visit_sessions(last_seen_at);
alter table public.app_visit_sessions enable row level security;
revoke all on public.app_visit_sessions from public, anon, authenticated;

create table if not exists public.support_threads (
  id uuid primary key default gen_random_uuid(),
  secret_hash text not null unique,
  customer_name text not null default 'Customer',
  order_reference text not null default '',
  status text not null default 'open' check (status in ('open','closed')),
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  last_admin_seen_at timestamptz
);
create index if not exists support_threads_recent_idx on public.support_threads(last_message_at desc);
alter table public.support_threads enable row level security;
revoke all on public.support_threads from public, anon, authenticated;

create table if not exists public.support_messages (
  id bigint generated always as identity primary key,
  thread_id uuid not null references public.support_threads(id) on delete cascade,
  sender text not null check (sender in ('customer','admin')),
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists support_messages_thread_idx on public.support_messages(thread_id,id);
alter table public.support_messages enable row level security;
revoke all on public.support_messages from public, anon, authenticated;

create or replace function public.record_app_visit(p_visitor_id uuid, p_session_id uuid, p_referrer_host text default '')
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_visitor_id is null or p_session_id is null then raise exception 'Invalid visit'; end if;
  insert into public.app_visit_sessions(session_id,visitor_id,referrer_host)
  values (p_session_id,p_visitor_id,left(coalesce(p_referrer_host,''),100))
  on conflict (session_id) do update set last_seen_at=now()
  where app_visit_sessions.visitor_id=excluded.visitor_id
    and app_visit_sessions.last_seen_at < now()-interval '30 seconds';
end;
$$;
revoke all on function public.record_app_visit(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.record_app_visit(uuid,uuid,text) to anon,authenticated;

create or replace function public.admin_traffic_summary()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform public.megjet_require_admin();
  select jsonb_build_object(
    'today_visits',count(*) filter (where first_seen_at >= (timezone('Asia/Nicosia',now())::date at time zone 'Asia/Nicosia')),
    'today_visitors',count(distinct visitor_id) filter (where first_seen_at >= (timezone('Asia/Nicosia',now())::date at time zone 'Asia/Nicosia')),
    'last_7_days',count(*) filter (where first_seen_at >= now()-interval '7 days'),
    'last_30_days',count(*) filter (where first_seen_at >= now()-interval '30 days'),
    'active_now',count(*) filter (where last_seen_at >= now()-interval '5 minutes')
  ) into result from public.app_visit_sessions;
  return result || jsonb_build_object('daily',coalesce((
    select jsonb_agg(jsonb_build_object('day',d.day,'visits',coalesce(v.visits,0),'visitors',coalesce(v.visitors,0)) order by d.day)
    from generate_series((timezone('Asia/Nicosia',now())::date - 6), timezone('Asia/Nicosia',now())::date, interval '1 day') as d(day)
    left join lateral (
      select count(*) visits,count(distinct s.visitor_id) visitors from public.app_visit_sessions s
      where (s.first_seen_at at time zone 'Asia/Nicosia')::date=d.day::date
    ) v on true
  ),'[]'::jsonb));
end;
$$;
revoke all on function public.admin_traffic_summary() from public,anon,authenticated;
grant execute on function public.admin_traffic_summary() to authenticated;

-- A random 256-bit token stays only in the customer's browser. The DB stores its hash.
create or replace function public.support_customer_open(p_token text,p_name text,p_order_reference text,p_body text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_thread_id uuid; clean_body text := trim(coalesce(p_body,''));
begin
  if p_token !~ '^[0-9a-f]{64}$' then raise exception 'Invalid support session'; end if;
  if char_length(clean_body) not between 1 and 1000 then raise exception 'Message must be 1–1000 characters'; end if;
  insert into public.support_threads(secret_hash,customer_name,order_reference)
  values (md5(p_token),left(coalesce(nullif(trim(p_name),''),'Customer'),80),left(coalesce(trim(p_order_reference),''),40))
  on conflict (secret_hash) do update set status='open'
  returning id into v_thread_id;
  if exists (select 1 from public.support_messages where thread_id=v_thread_id) then
    raise exception 'Conversation already exists';
  end if;
  insert into public.support_messages(thread_id,sender,body) values (v_thread_id,'customer',clean_body);
  update public.support_threads set last_message_at=now() where id=v_thread_id;
  return v_thread_id;
end;
$$;
revoke all on function public.support_customer_open(text,text,text,text) from public,anon,authenticated;
grant execute on function public.support_customer_open(text,text,text,text) to anon,authenticated;

create or replace function public.support_customer_state(p_token text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  if p_token !~ '^[0-9a-f]{64}$' then raise exception 'Invalid support session'; end if;
  select jsonb_build_object('id',t.id,'status',t.status,'name',t.customer_name,'order_reference',t.order_reference,
    'messages',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'sender',m.sender,'body',m.body,'created_at',m.created_at) order by m.id)
      from public.support_messages m where m.thread_id=t.id),'[]'::jsonb))
  into result from public.support_threads t where t.secret_hash=md5(p_token);
  return result;
end;
$$;
revoke all on function public.support_customer_state(text) from public,anon,authenticated;
grant execute on function public.support_customer_state(text) to anon,authenticated;

create or replace function public.support_customer_send(p_token text,p_body text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_thread_id uuid; clean_body text := trim(coalesce(p_body,''));
begin
  if p_token !~ '^[0-9a-f]{64}$' then raise exception 'Invalid support session'; end if;
  if char_length(clean_body) not between 1 and 1000 then raise exception 'Message must be 1–1000 characters'; end if;
  select id into v_thread_id from public.support_threads where secret_hash=md5(p_token) for update;
  if v_thread_id is null then raise exception 'Start a support conversation first'; end if;
  if exists (select 1 from public.support_messages where thread_id=v_thread_id and sender='customer' and created_at>now()-interval '3 seconds') then
    raise exception 'Please wait before sending another message';
  end if;
  insert into public.support_messages(thread_id,sender,body) values(v_thread_id,'customer',clean_body);
  update public.support_threads set status='open',last_message_at=now() where id=v_thread_id;
end;
$$;
revoke all on function public.support_customer_send(text,text) from public,anon,authenticated;
grant execute on function public.support_customer_send(text,text) to anon,authenticated;

create or replace function public.admin_support_inbox()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform public.megjet_require_admin();
  select coalesce(jsonb_agg(jsonb_build_object('id',t.id,'name',t.customer_name,'order_reference',t.order_reference,
    'status',t.status,'last_message_at',t.last_message_at,'unread',
    (select count(*) from public.support_messages m where m.thread_id=t.id and m.sender='customer'
      and (t.last_admin_seen_at is null or m.created_at>t.last_admin_seen_at))) order by t.last_message_at desc),'[]'::jsonb)
  into result from (select * from public.support_threads order by last_message_at desc limit 100) t;
  return result;
end;
$$;
revoke all on function public.admin_support_inbox() from public,anon,authenticated;
grant execute on function public.admin_support_inbox() to authenticated;

create or replace function public.admin_support_thread(p_thread_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result jsonb;
begin
  perform public.megjet_require_admin();
  select jsonb_build_object('id',t.id,'name',t.customer_name,'order_reference',t.order_reference,'status',t.status,
    'messages',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'sender',m.sender,'body',m.body,'created_at',m.created_at) order by m.id)
      from public.support_messages m where m.thread_id=t.id),'[]'::jsonb)) into result
  from public.support_threads t where t.id=p_thread_id;
  if result is not null then update public.support_threads set last_admin_seen_at=now() where id=p_thread_id; end if;
  return result;
end;
$$;
revoke all on function public.admin_support_thread(uuid) from public,anon,authenticated;
grant execute on function public.admin_support_thread(uuid) to authenticated;

create or replace function public.admin_support_reply(p_thread_id uuid,p_body text)
returns void language plpgsql security definer set search_path = '' as $$
declare clean_body text := trim(coalesce(p_body,''));
begin
  perform public.megjet_require_admin();
  if char_length(clean_body) not between 1 and 1000 then raise exception 'Message must be 1–1000 characters'; end if;
  if not exists(select 1 from public.support_threads where id=p_thread_id) then raise exception 'Conversation not found'; end if;
  insert into public.support_messages(thread_id,sender,body) values(p_thread_id,'admin',clean_body);
  update public.support_threads set last_message_at=now(),last_admin_seen_at=now(),status='open' where id=p_thread_id;
end;
$$;
revoke all on function public.admin_support_reply(uuid,text) from public,anon,authenticated;
grant execute on function public.admin_support_reply(uuid,text) to authenticated;

create or replace function public.admin_support_close(p_thread_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.megjet_require_admin();
  update public.support_threads set status='closed' where id=p_thread_id;
end;
$$;
revoke all on function public.admin_support_close(uuid) from public,anon,authenticated;
grant execute on function public.admin_support_close(uuid) to authenticated;
