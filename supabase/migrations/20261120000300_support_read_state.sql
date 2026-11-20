begin;

-- ---------------------------------------------------------------------------
-- Read state for support conversations.
--
-- One row per account: when support last opened that conversation. The
-- admin inbox uses it for the unread count; the user sees "Seen" under
-- their last message.
-- ---------------------------------------------------------------------------

create table if not exists public.support_reads (
  user_id uuid primary key references auth.users (id) on delete cascade,
  read_at timestamptz not null default timezone('utc', now())
);

alter table public.support_reads enable row level security;
revoke all on table public.support_reads from anon, authenticated;
grant select on table public.support_reads to authenticated;
grant all on table public.support_reads to service_role;

drop policy if exists support_reads_select_own on public.support_reads;
create policy support_reads_select_own on public.support_reads
for select to authenticated
using ((select auth.uid()) = user_id or (select public.is_admin()));

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'support_reads'
  ) then
    alter publication supabase_realtime add table public.support_reads;
  end if;
end;
$$;

create or replace function public.admin_mark_support_read(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_admin();
  insert into public.support_reads (user_id, read_at)
  values (p_user_id, timezone('utc', now()))
  on conflict (user_id) do update set read_at = excluded.read_at;
end;
$$;

revoke all on function public.admin_mark_support_read(uuid) from public, anon;
grant execute on function public.admin_mark_support_read(uuid) to authenticated;

-- Adds `unread`: user messages newer than both the last reply and the last
-- time support opened the conversation.
drop function if exists public.admin_support_threads();
create function public.admin_support_threads()
returns table (
  user_id uuid,
  display_name text,
  email text,
  last_body text,
  last_sender text,
  last_at timestamptz,
  waiting integer,
  unread integer
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
    ),
    (
      select count(*)::integer from public.support_messages w
      where w.user_id = l.user_id and w.sender = 'user'
        and w.created_at > greatest(
          coalesce(r.at, '-infinity'::timestamptz),
          coalesce(s.read_at, '-infinity'::timestamptz)
        )
    )
  from latest l
  left join last_reply r on r.user_id = l.user_id
  left join public.support_reads s on s.user_id = l.user_id
  left join auth.users u on u.id = l.user_id
  left join public.profiles p on p.id = l.user_id
  order by l.created_at desc;
end;
$$;

revoke all on function public.admin_support_threads() from public, anon;
grant execute on function public.admin_support_threads() to authenticated;

commit;
