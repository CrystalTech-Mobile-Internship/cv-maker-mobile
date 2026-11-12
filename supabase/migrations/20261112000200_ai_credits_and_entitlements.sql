begin;

-- Plan per user. Only the service role (billing back office) writes here;
-- users can read their own row.
create table if not exists public.user_entitlements (
  user_id uuid primary key references auth.users (id) on delete cascade,
  plan text not null default 'free',
  pro_until timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  constraint user_entitlements_plan check (plan in ('free', 'pro'))
);

-- One row per user per UTC day. Written only through the security definer
-- functions below so clients cannot reset their own usage.
create table if not exists public.ai_usage_daily (
  user_id uuid not null references auth.users (id) on delete cascade,
  usage_date date not null default (timezone('utc', now()))::date,
  credits_used integer not null default 0,
  request_count integer not null default 0,
  last_request_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, usage_date),
  constraint ai_usage_daily_non_negative
    check (credits_used >= 0 and request_count >= 0)
);

alter table public.user_entitlements enable row level security;
alter table public.ai_usage_daily enable row level security;

revoke all on table public.user_entitlements from anon, authenticated;
revoke all on table public.ai_usage_daily from anon, authenticated;
grant select on table public.user_entitlements to authenticated;
grant select on table public.ai_usage_daily to authenticated;

drop policy if exists user_entitlements_select_own on public.user_entitlements;
create policy user_entitlements_select_own on public.user_entitlements
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists ai_usage_daily_select_own on public.ai_usage_daily;
create policy ai_usage_daily_select_own on public.ai_usage_daily
for select to authenticated
using ((select auth.uid()) = user_id);

-- Daily credit budget per plan. Adjust here, never in the client.
create or replace function public.ai_daily_credit_limit(p_plan text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case when p_plan = 'pro' then 200 else 15 end;
$$;

create or replace function public.current_ai_plan(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select case
        when e.plan = 'pro' and (e.pro_until is null or e.pro_until > now())
          then 'pro'
        else 'free'
      end
      from public.user_entitlements e
      where e.user_id = p_user_id
    ),
    'free'
  );
$$;

-- Returns the caller's quota without consuming anything.
create or replace function public.get_ai_quota()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_plan text;
  v_used integer;
  v_limit integer;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  v_plan := public.current_ai_plan(v_user);
  v_limit := public.ai_daily_credit_limit(v_plan);
  select coalesce(credits_used, 0) into v_used
  from public.ai_usage_daily
  where user_id = v_user
    and usage_date = (timezone('utc', now()))::date;
  v_used := coalesce(v_used, 0);
  return jsonb_build_object(
    'plan', v_plan,
    'used', v_used,
    'limit', v_limit,
    'remaining', greatest(v_limit - v_used, 0)
  );
end;
$$;

-- Atomically reserves p_cost credits for the caller. Returns the quota with
-- `allowed = false` (and consumes nothing) when the budget is exhausted.
create or replace function public.consume_ai_credits(p_cost integer)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
  v_plan text;
  v_limit integer;
  v_used integer;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_cost is null or p_cost < 1 or p_cost > 10 then
    raise exception 'invalid cost' using errcode = '22023';
  end if;

  v_plan := public.current_ai_plan(v_user);
  v_limit := public.ai_daily_credit_limit(v_plan);

  insert into public.ai_usage_daily (user_id, usage_date)
  values (v_user, v_today)
  on conflict (user_id, usage_date) do nothing;

  update public.ai_usage_daily
  set credits_used = credits_used + p_cost,
      request_count = request_count + 1,
      last_request_at = timezone('utc', now())
  where user_id = v_user
    and usage_date = v_today
    and credits_used + p_cost <= v_limit
  returning credits_used into v_used;

  if v_used is null then
    select credits_used into v_used
    from public.ai_usage_daily
    where user_id = v_user and usage_date = v_today;
    return jsonb_build_object(
      'allowed', false,
      'plan', v_plan,
      'used', v_used,
      'limit', v_limit,
      'remaining', greatest(v_limit - v_used, 0)
    );
  end if;

  return jsonb_build_object(
    'allowed', true,
    'plan', v_plan,
    'used', v_used,
    'limit', v_limit,
    'remaining', greatest(v_limit - v_used, 0)
  );
end;
$$;

-- Gives credits back when the AI provider failed after a reservation.
create or replace function public.refund_ai_credits(p_cost integer)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or p_cost is null or p_cost < 1 or p_cost > 10 then
    return;
  end if;
  update public.ai_usage_daily
  set credits_used = greatest(credits_used - p_cost, 0)
  where user_id = auth.uid()
    and usage_date = (timezone('utc', now()))::date;
end;
$$;

revoke all on function public.current_ai_plan(uuid) from public, anon, authenticated;
revoke all on function public.get_ai_quota() from public, anon;
revoke all on function public.consume_ai_credits(integer) from public, anon;
revoke all on function public.refund_ai_credits(integer) from public, anon;
grant execute on function public.get_ai_quota() to authenticated;
grant execute on function public.consume_ai_credits(integer) to authenticated;
grant execute on function public.refund_ai_credits(integer) to authenticated;

commit;
