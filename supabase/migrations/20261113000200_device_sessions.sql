-- One signed-in browser and one signed-in phone per account.
-- Signing in on another device of the same kind replaces the older session:
-- its refresh token is revoked here and the app on that device signs out as
-- soon as it sees the change (live) or on its next start.

create table if not exists public.user_device_sessions (
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('web', 'mobile')),
  session_id uuid not null,
  device_label text,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, platform)
);

alter table public.user_device_sessions enable row level security;

revoke all on table public.user_device_sessions from anon, authenticated;
grant select on table public.user_device_sessions to authenticated;

drop policy if exists user_device_sessions_select_own on public.user_device_sessions;
create policy user_device_sessions_select_own on public.user_device_sessions
for select to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.claim_device_session(
  p_platform text,
  p_device_label text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_session uuid := nullif(auth.jwt() ->> 'session_id', '')::uuid;
  v_previous uuid;
begin
  if v_user is null or v_session is null then
    raise exception 'not_authenticated';
  end if;
  if p_platform not in ('web', 'mobile') then
    raise exception 'invalid_platform';
  end if;

  select session_id into v_previous
  from public.user_device_sessions
  where user_id = v_user and platform = p_platform
  for update;

  if v_previous is not null and v_previous <> v_session then
    begin
      -- Revokes the older device's refresh token (cascades to refresh_tokens).
      delete from auth.sessions where id = v_previous and user_id = v_user;
    exception when insufficient_privilege then
      null; -- the app still signs the older device out
    end;
  end if;

  insert into public.user_device_sessions as s
    (user_id, platform, session_id, device_label, updated_at)
  values
    (v_user, p_platform, v_session, left(p_device_label, 80), timezone('utc', now()))
  on conflict (user_id, platform) do update
    set session_id = excluded.session_id,
        device_label = excluded.device_label,
        updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.claim_device_session(text, text) from public, anon;
grant execute on function public.claim_device_session(text, text) to authenticated;

do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'user_device_sessions'
  ) then
    alter publication supabase_realtime add table public.user_device_sessions;
  end if;
end
$$;
