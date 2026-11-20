begin;

-- Lifetime members have nothing left to buy: refuse a new checkout so no
-- one can pay for time they would never get.
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
  if p_plan not in ('monthly', 'quarterly') then
    raise exception 'unknown plan' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.user_entitlements e
    where e.user_id = v_user and e.plan = 'pro' and e.pro_until is null
  ) then
    raise exception 'already lifetime' using errcode = '22023';
  end if;

  v_code := 'CVPRO'
    || case p_plan when 'monthly' then 'M' else 'Q' end
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

commit;
