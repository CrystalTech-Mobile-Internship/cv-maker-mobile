begin;

-- ---------------------------------------------------------------------------
-- Admin console: support inbox, Pro payments and a few totals.
--
-- Admins are listed in `admin_users`, which only the service role and the
-- SQL editor can change. Add one with:
--   insert into public.admin_users (user_id)
--   select id from auth.users where email = '<admin email>';
--
-- Admins get exactly the access below: support conversations, Pro requests,
-- SePay events and totals. They cannot read or change anyone's CVs.
-- ---------------------------------------------------------------------------

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.admin_users enable row level security;
revoke all on table public.admin_users from anon, authenticated;
grant all on table public.admin_users to service_role;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- Raises unless the caller is an admin.
create or replace function public.require_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.require_admin() from public, anon, authenticated;

-- Admins read every conversation (also keeps the live updates working).
drop policy if exists support_messages_select_admin on public.support_messages;
create policy support_messages_select_admin on public.support_messages
for select to authenticated
using ((select public.is_admin()));

-- One row per account that has written to support, newest first.
-- `waiting` counts the user's messages after the last support reply.
create or replace function public.admin_support_threads()
returns table (
  user_id uuid,
  display_name text,
  email text,
  last_body text,
  last_sender text,
  last_at timestamptz,
  waiting integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_admin();
  return query
  with last_reply as (
    select m.user_id, max(m.created_at) as at
    from public.support_messages m
    where m.sender = 'support'
    group by m.user_id
  ),
  latest as (
    select distinct on (m.user_id) m.user_id, m.body, m.sender, m.created_at
    from public.support_messages m
    order by m.user_id, m.created_at desc
  )
  select
    l.user_id,
    coalesce(
      nullif(btrim(p.full_name), ''),
      nullif(btrim(u.raw_user_meta_data ->> 'full_name'), ''),
      split_part(u.email::text, '@', 1)
    ),
    u.email::text,
    left(l.body, 200),
    l.sender,
    l.created_at,
    (
      select count(*)::integer from public.support_messages w
      where w.user_id = l.user_id and w.sender = 'user'
        and w.created_at > coalesce(r.at, '-infinity'::timestamptz)
    )
  from latest l
  left join last_reply r on r.user_id = l.user_id
  left join auth.users u on u.id = l.user_id
  left join public.profiles p on p.id = l.user_id
  order by l.created_at desc;
end;
$$;

revoke all on function public.admin_support_threads() from public, anon;
grant execute on function public.admin_support_threads() to authenticated;

create or replace function public.admin_reply_support(p_user_id uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_admin();
  if p_body is null or char_length(btrim(p_body)) = 0 then
    raise exception 'empty reply' using errcode = '22023';
  end if;
  insert into public.support_messages (user_id, sender, body)
  values (p_user_id, 'support', left(btrim(p_body), 2000));
end;
$$;

revoke all on function public.admin_reply_support(uuid, text) from public, anon;
grant execute on function public.admin_reply_support(uuid, text) to authenticated;

-- Latest Pro requests with who made them.
create or replace function public.admin_pro_requests(p_limit integer default 50)
returns table (
  id uuid,
  user_id uuid,
  email text,
  plan text,
  amount integer,
  transfer_code text,
  status text,
  created_at timestamptz,
  paid_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_admin();
  return query
  select r.id, r.user_id, u.email::text, r.plan,
    coalesce(r.amount, public.pro_plan_price(r.plan)),
    r.transfer_code, r.status, r.created_at, r.paid_at
  from public.pro_upgrade_requests r
  left join auth.users u on u.id = r.user_id
  order by (r.status = 'pending') desc, r.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
end;
$$;

revoke all on function public.admin_pro_requests(integer) from public, anon;
grant execute on function public.admin_pro_requests(integer) to authenticated;

-- Latest bank transfers SePay reported.
create or replace function public.admin_payment_events(p_limit integer default 50)
returns table (
  id bigint,
  amount bigint,
  content text,
  status text,
  request_id uuid,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform public.require_admin();
  return query
  select e.id, e.amount, e.content, e.status, e.request_id, e.created_at
  from public.payment_events e
  order by e.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
end;
$$;

revoke all on function public.admin_payment_events(integer) from public, anon;
grant execute on function public.admin_payment_events(integer) to authenticated;

-- Approve or reject a pending request by hand (wrong transfer note, etc.).
create or replace function public.admin_review_pro_request(
  p_request_id uuid,
  p_approve boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_admin();
  if p_approve then
    update public.pro_upgrade_requests
    set paid_at = coalesce(paid_at, timezone('utc', now()))
    where id = p_request_id and status = 'pending';
    perform public.approve_pro_request(p_request_id, 'approved by admin');
  else
    update public.pro_upgrade_requests
    set status = 'rejected', reviewed_at = timezone('utc', now()),
      admin_note = 'rejected by admin'
    where id = p_request_id and status = 'pending';
    if not found then
      raise exception 'pending request not found';
    end if;
  end if;
end;
$$;

revoke all on function public.admin_review_pro_request(uuid, boolean) from public, anon;
grant execute on function public.admin_review_pro_request(uuid, boolean) to authenticated;

-- Totals for the top of the admin page. Revenue counts approved requests
-- in the current month (Vietnam time).
create or replace function public.admin_stats()
returns table (
  users integer,
  pro_users integer,
  month_revenue bigint,
  waiting_threads integer,
  pending_requests integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_month_start timestamptz :=
    date_trunc('month', now() at time zone 'Asia/Ho_Chi_Minh')
      at time zone 'Asia/Ho_Chi_Minh';
begin
  perform public.require_admin();
  return query
  select
    (select count(*)::integer from auth.users),
    (select count(*)::integer from public.user_entitlements e
      where e.plan = 'pro' and (e.pro_until is null or e.pro_until > now())),
    (select coalesce(sum(coalesce(r.amount, public.pro_plan_price(r.plan))), 0)::bigint
      from public.pro_upgrade_requests r
      where r.status = 'approved'
        and coalesce(r.paid_at, r.reviewed_at) >= v_month_start),
    (select count(*)::integer from (
      select m.user_id from public.support_messages m
      group by m.user_id
      having max(m.created_at) filter (where m.sender = 'user')
        > coalesce(max(m.created_at) filter (where m.sender = 'support'), '-infinity'::timestamptz)
    ) t),
    (select count(*)::integer from public.pro_upgrade_requests r
      where r.status = 'pending');
end;
$$;

revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;

commit;
