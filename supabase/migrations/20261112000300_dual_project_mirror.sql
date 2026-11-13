begin;

-- Tombstones so deletions can be replicated to the mirror project.
create table if not exists public.cv_deletions (
  cv_id uuid primary key,
  user_id uuid not null,
  deleted_at timestamptz not null default timezone('utc', now())
);

alter table public.cv_deletions enable row level security;
revoke all on table public.cv_deletions from anon, authenticated;

create index if not exists cv_deletions_deleted_at_idx
  on public.cv_deletions (deleted_at);

create or replace function public.log_cv_deletion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.cv_deletions (cv_id, user_id, deleted_at)
  values (old.id, old.user_id, timezone('utc', now()))
  on conflict (cv_id) do update set deleted_at = excluded.deleted_at;
  return old;
end;
$$;

revoke all on function public.log_cv_deletion() from public, anon, authenticated;

drop trigger if exists cvs_log_deletion on public.cvs;
create trigger cvs_log_deletion
  after delete on public.cvs
  for each row execute function public.log_cv_deletion();

-- A CV that is re-created with the same id is no longer deleted.
create or replace function public.clear_cv_tombstone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.cv_deletions where cv_id = new.id;
  return new;
end;
$$;

revoke all on function public.clear_cv_tombstone() from public, anon, authenticated;

drop trigger if exists cvs_clear_tombstone on public.cvs;
create trigger cvs_clear_tombstone
  after insert on public.cvs
  for each row execute function public.clear_cv_tombstone();

-- Replication checkpoint per target project and kind ('cvs', 'deletions').
create table if not exists public.mirror_checkpoints (
  target text not null,
  kind text not null,
  last_synced_at timestamptz not null default 'epoch',
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (target, kind)
);

-- Source user id -> mirror user id, resolved by verified email.
create table if not exists public.mirror_user_map (
  target text not null,
  source_user_id uuid not null,
  target_user_id uuid not null,
  email text not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (target, source_user_id)
);

alter table public.mirror_checkpoints enable row level security;
alter table public.mirror_user_map enable row level security;
revoke all on table public.mirror_checkpoints from anon, authenticated;
revoke all on table public.mirror_user_map from anon, authenticated;

-- Lets the mirror function (service role only) find an account by email.
create or replace function public.mirror_find_user_id(p_email text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from auth.users
  where lower(email) = lower(trim(p_email))
  limit 1;
$$;

revoke all on function public.mirror_find_user_id(text)
  from public, anon, authenticated;
grant execute on function public.mirror_find_user_id(text) to service_role;

commit;
