-- Releases an active device session on intentional sign-out.
-- When a user explicitly signs out, their device session record is removed
-- so a subsequent sign-in on the same device does not conflict with its
-- own previous session. If a session_id is provided, only that matching
-- session is deleted so a replaced device never clears a newer session.

create or replace function public.release_device_session(
  p_platform text,
  p_session_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_session uuid := coalesce(p_session_id, nullif(auth.jwt() ->> 'session_id', '')::uuid);
begin
  if v_user is null then
    return;
  end if;
  if p_platform not in ('web', 'mobile') then
    raise exception 'invalid_platform';
  end if;

  if v_session is not null then
    delete from public.user_device_sessions
    where user_id = v_user and platform = p_platform and session_id = v_session;
  else
    delete from public.user_device_sessions
    where user_id = v_user and platform = p_platform;
  end if;
end;
$$;

revoke all on function public.release_device_session(text, uuid) from public, anon;
grant execute on function public.release_device_session(text, uuid) to authenticated;

-- Allow authenticated users to delete their own session rows as fallback
drop policy if exists user_device_sessions_delete_own on public.user_device_sessions;
create policy user_device_sessions_delete_own on public.user_device_sessions
for delete to authenticated
using ((select auth.uid()) = user_id);
