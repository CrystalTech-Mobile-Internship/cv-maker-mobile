begin;

-- ---------------------------------------------------------------------------
-- Safer Pro payments.
--
-- 1. The webhook runs as service_role and must be able to read and update
--    Pro requests (a missing grant made the first SePay call fail).
-- 2. All matching happens in one locked transaction (`apply_sepay_payment`),
--    so a retry after a failure is processed again instead of being skipped.
-- 3. Paying again with a code already used (e.g. a saved QR) still adds the
--    plan's days instead of being lost.
-- 4. Buying a timed plan never shortens a lifetime plan.
-- ---------------------------------------------------------------------------

grant select, insert, update on table public.pro_upgrade_requests to service_role;
grant select, insert, update on table public.user_entitlements to service_role;
grant select, insert, update on table public.payment_events to service_role;

-- Adds a plan's days to an account, starting from the later of now or the
-- current end date. Lifetime stays lifetime.
create or replace function public.grant_pro_plan(p_user_id uuid, p_plan text)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_days integer := public.pro_plan_days(p_plan);
  v_current public.user_entitlements;
  v_until timestamptz;
begin
  select * into v_current from public.user_entitlements
  where user_id = p_user_id
  for update;

  if found and v_current.plan = 'pro' and v_current.pro_until is null then
    v_until := null; -- already lifetime
  elsif v_days is null then
    v_until := null; -- lifetime purchase
  else
    v_until := greatest(
      coalesce(case when v_current.plan = 'pro' then v_current.pro_until end, now()),
      now()
    ) + make_interval(days => v_days);
  end if;

  insert into public.user_entitlements (user_id, plan, pro_until, updated_at)
  values (p_user_id, 'pro', v_until, timezone('utc', now()))
  on conflict (user_id) do update
    set plan = 'pro', pro_until = excluded.pro_until, updated_at = excluded.updated_at;
  return v_until;
end;
$$;

revoke all on function public.grant_pro_plan(uuid, text) from public, anon, authenticated;
grant execute on function public.grant_pro_plan(uuid, text) to service_role;

create or replace function public.approve_pro_request(
  p_request_id uuid,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.pro_upgrade_requests;
begin
  select * into v_request from public.pro_upgrade_requests
  where id = p_request_id and status = 'pending'
  for update;
  if not found then
    raise exception 'pending request not found';
  end if;

  perform public.grant_pro_plan(v_request.user_id, v_request.plan);

  update public.pro_upgrade_requests
  set status = 'approved', reviewed_at = timezone('utc', now()), admin_note = p_note
  where id = p_request_id;
end;
$$;

revoke all on function public.approve_pro_request(uuid, text) from public, anon, authenticated;
grant execute on function public.approve_pro_request(uuid, text) to service_role;

-- Matches one recorded SePay event to a Pro purchase. Safe to call again
-- for the same event: only events still 'received' are processed.
-- Returns the event's final status.
create or replace function public.apply_sepay_payment(
  p_provider_id text,
  p_code text,
  p_ref text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.payment_events;
  v_request public.pro_upgrade_requests;
  v_plan text;
  v_price integer;
  v_owner uuid;
  v_owners integer;
begin
  select * into v_event from public.payment_events
  where provider = 'sepay' and provider_id = p_provider_id
  for update;
  if not found then
    raise exception 'event not recorded';
  end if;
  if v_event.status <> 'received' then
    return v_event.status;
  end if;

  if p_code is null then
    update public.payment_events set status = 'unmatched' where id = v_event.id;
    return 'unmatched';
  end if;

  -- 1. A checkout waiting for this code.
  select * into v_request from public.pro_upgrade_requests
  where transfer_code = p_code and status = 'pending'
  order by created_at desc
  limit 1
  for update;

  if found then
    if v_event.amount < coalesce(v_request.amount, public.pro_plan_price(v_request.plan)) then
      update public.payment_events
      set status = 'unmatched', request_id = v_request.id
      where id = v_event.id;
      return 'unmatched';
    end if;
    perform public.approve_pro_request(v_request.id, 'SePay');
    update public.pro_upgrade_requests
    set paid_at = timezone('utc', now()), payment_ref = left(p_ref, 120)
    where id = v_request.id;
    update public.payment_events
    set status = 'matched', request_id = v_request.id
    where id = v_event.id;
    return 'matched';
  end if;

  -- 2. No checkout waiting: the code was used before (saved QR, paid twice).
  --    Codes are tied to one account and one plan, so add that plan again.
  select count(distinct r.user_id), min(r.user_id::text)::uuid
  into v_owners, v_owner
  from public.pro_upgrade_requests r
  where r.transfer_code = p_code;

  v_plan := case substr(p_code, 6, 1)
    when 'M' then 'monthly'
    when 'Q' then 'quarterly'
  end;
  v_price := public.pro_plan_price(v_plan);

  if v_owners <> 1 or v_plan is null or v_event.amount < v_price then
    update public.payment_events set status = 'unmatched' where id = v_event.id;
    return 'unmatched';
  end if;

  perform public.grant_pro_plan(v_owner, v_plan);
  insert into public.pro_upgrade_requests (
    user_id, plan, transfer_code, amount, status, reviewed_at, paid_at,
    payment_ref, admin_note
  )
  values (
    v_owner, v_plan, p_code, v_price, 'approved', timezone('utc', now()),
    timezone('utc', now()), left(p_ref, 120), 'SePay (repeat payment)'
  )
  returning * into v_request;

  update public.payment_events
  set status = 'matched', request_id = v_request.id
  where id = v_event.id;
  return 'matched';
end;
$$;

revoke all on function public.apply_sepay_payment(text, text, text) from public, anon, authenticated;
grant execute on function public.apply_sepay_payment(text, text, text) to service_role;

commit;
