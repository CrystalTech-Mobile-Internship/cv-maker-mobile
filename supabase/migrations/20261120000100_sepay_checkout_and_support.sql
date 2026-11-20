begin;

-- ---------------------------------------------------------------------------
-- Automatic Pro payments through SePay.
--
-- The app starts a checkout (server-side price and transfer code), shows a
-- VietQR code, and the `sepay-webhook` Edge Function approves the request as
-- soon as SePay reports the matching bank transfer.
-- ---------------------------------------------------------------------------

alter table public.pro_upgrade_requests
  add column if not exists amount integer,
  add column if not exists paid_at timestamptz,
  add column if not exists payment_ref text;

-- Codes no longer use dashes: some banks strip them from transfer notes.
alter table public.pro_upgrade_requests
  drop constraint if exists pro_upgrade_requests_code;
alter table public.pro_upgrade_requests
  add constraint pro_upgrade_requests_code
  check (transfer_code ~ '^CVPRO[A-Z0-9-]{4,40}$');

alter table public.pro_upgrade_requests
  drop constraint if exists pro_upgrade_requests_status;
alter table public.pro_upgrade_requests
  add constraint pro_upgrade_requests_status
  check (status in ('pending', 'approved', 'rejected', 'expired'));

-- Server-side prices in VND; the client never decides the amount.
create or replace function public.pro_plan_price(p_plan text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_plan when 'monthly' then 49000 when 'lifetime' then 99000 end;
$$;

-- Starts (or reuses) the caller's checkout for a plan and returns it.
-- Any other pending request of the caller expires, so switching plans works.
create or replace function public.start_pro_checkout(p_plan text)
returns public.pro_upgrade_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_code text;
  v_row public.pro_upgrade_requests;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_plan not in ('monthly', 'lifetime') then
    raise exception 'unknown plan' using errcode = '22023';
  end if;

  v_code := 'CVPRO'
    || case p_plan when 'monthly' then 'M' else 'L' end
    || upper(substr(replace(v_user::text, '-', ''), 1, 8));

  select * into v_row from public.pro_upgrade_requests
  where user_id = v_user and status = 'pending' and plan = p_plan
  limit 1;
  if found then
    return v_row;
  end if;

  update public.pro_upgrade_requests
  set status = 'expired', reviewed_at = timezone('utc', now())
  where user_id = v_user and status = 'pending';

  insert into public.pro_upgrade_requests (user_id, plan, transfer_code, amount)
  values (v_user, p_plan, v_code, public.pro_plan_price(p_plan))
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.start_pro_checkout(text) from public, anon;
grant execute on function public.start_pro_checkout(text) to authenticated;

-- Every SePay notification, kept once per SePay transaction id.
create table if not exists public.payment_events (
  id bigint generated always as identity primary key,
  provider text not null default 'sepay',
  provider_id text not null,
  amount bigint not null default 0,
  content text,
  request_id uuid references public.pro_upgrade_requests (id) on delete set null,
  status text not null default 'received',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  constraint payment_events_status check (status in ('received', 'matched', 'unmatched', 'ignored')),
  constraint payment_events_unique unique (provider, provider_id)
);

alter table public.payment_events enable row level security;
revoke all on table public.payment_events from anon, authenticated;
grant all on table public.payment_events to service_role;

-- Lets the app notice the upgrade without reloading.
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'user_entitlements'
  ) then
    alter publication supabase_realtime add table public.user_entitlements;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Support chat: one conversation per account, kept on the server so it is
-- the same on the web and in the app. New user messages are emailed to the
-- support inbox by the `support-notify` Edge Function.
-- ---------------------------------------------------------------------------

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  sender text not null default 'user',
  body text not null,
  emailed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  constraint support_messages_sender check (sender in ('user', 'support')),
  constraint support_messages_body check (char_length(btrim(body)) between 1 and 2000)
);

create index if not exists support_messages_user_created
  on public.support_messages (user_id, created_at);

alter table public.support_messages enable row level security;
revoke all on table public.support_messages from anon, authenticated;
grant select on table public.support_messages to authenticated;
grant insert (body) on table public.support_messages to authenticated;
grant all on table public.support_messages to service_role;

drop policy if exists support_messages_select_own on public.support_messages;
create policy support_messages_select_own on public.support_messages
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists support_messages_insert_own on public.support_messages;
create policy support_messages_insert_own on public.support_messages
for insert to authenticated
with check ((select auth.uid()) = user_id and sender = 'user');

-- Basic flood protection: at most 10 messages per 10 minutes per account.
create or replace function public.support_messages_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.sender = 'user' and (
    select count(*) from public.support_messages
    where user_id = new.user_id and sender = 'user'
      and created_at > timezone('utc', now()) - interval '10 minutes'
  ) >= 10 then
    raise exception 'too many support messages' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists support_messages_rate_limit on public.support_messages;
create trigger support_messages_rate_limit
before insert on public.support_messages
for each row execute function public.support_messages_rate_limit();

-- Reply from the SQL editor: select public.reply_support('<user id>', 'text');
create or replace function public.reply_support(p_user_id uuid, p_body text)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.support_messages (user_id, sender, body)
  values (p_user_id, 'support', p_body);
$$;

revoke all on function public.reply_support(uuid, text) from public, anon, authenticated;
grant execute on function public.reply_support(uuid, text) to service_role;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'support_messages'
  ) then
    alter publication supabase_realtime add table public.support_messages;
  end if;
end;
$$;

commit;
