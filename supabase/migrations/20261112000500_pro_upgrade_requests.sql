begin;

-- Manual bank-transfer upgrade flow: the user submits a request with a
-- per-account transfer code, an administrator verifies the payment and
-- approves it with public.approve_pro_request() from the SQL editor.

create table if not exists public.pro_upgrade_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  plan text not null,
  transfer_code text not null,
  status text not null default 'pending',
  admin_note text,
  created_at timestamptz not null default timezone('utc', now()),
  reviewed_at timestamptz,
  constraint pro_upgrade_requests_plan check (plan in ('monthly', 'lifetime')),
  constraint pro_upgrade_requests_status check (status in ('pending', 'approved', 'rejected')),
  constraint pro_upgrade_requests_code check (transfer_code ~ '^CVPRO-[A-Z0-9-]{4,40}$')
);

-- At most one pending request per user.
create unique index if not exists pro_upgrade_requests_one_pending
  on public.pro_upgrade_requests (user_id) where status = 'pending';

alter table public.pro_upgrade_requests enable row level security;
revoke all on table public.pro_upgrade_requests from anon, authenticated;
grant select on table public.pro_upgrade_requests to authenticated;
grant insert (plan, transfer_code) on table public.pro_upgrade_requests to authenticated;

drop policy if exists pro_upgrade_requests_select_own on public.pro_upgrade_requests;
create policy pro_upgrade_requests_select_own on public.pro_upgrade_requests
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists pro_upgrade_requests_insert_own on public.pro_upgrade_requests;
create policy pro_upgrade_requests_insert_own on public.pro_upgrade_requests
for insert to authenticated
with check ((select auth.uid()) = user_id);

-- Administrator action (service role / SQL editor only).
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
  v_until timestamptz;
begin
  select * into v_request from public.pro_upgrade_requests
  where id = p_request_id and status = 'pending'
  for update;
  if not found then
    raise exception 'pending request not found';
  end if;

  if v_request.plan = 'monthly' then
    select greatest(coalesce(e.pro_until, now()), now()) + interval '30 days'
    into v_until
    from (select 1) one
    left join public.user_entitlements e on e.user_id = v_request.user_id;
  else
    v_until := null; -- lifetime
  end if;

  insert into public.user_entitlements (user_id, plan, pro_until, updated_at)
  values (v_request.user_id, 'pro', v_until, timezone('utc', now()))
  on conflict (user_id) do update
    set plan = 'pro', pro_until = excluded.pro_until, updated_at = excluded.updated_at;

  update public.pro_upgrade_requests
  set status = 'approved', reviewed_at = timezone('utc', now()), admin_note = p_note
  where id = p_request_id;
end;
$$;

create or replace function public.reject_pro_request(
  p_request_id uuid,
  p_note text default null
)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.pro_upgrade_requests
  set status = 'rejected', reviewed_at = timezone('utc', now()), admin_note = p_note
  where id = p_request_id and status = 'pending';
$$;

revoke all on function public.approve_pro_request(uuid, text) from public, anon, authenticated;
revoke all on function public.reject_pro_request(uuid, text) from public, anon, authenticated;
grant execute on function public.approve_pro_request(uuid, text) to service_role;
grant execute on function public.reject_pro_request(uuid, text) to service_role;

commit;
