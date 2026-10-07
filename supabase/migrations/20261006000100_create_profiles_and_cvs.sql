begin;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length
    check (display_name is null or char_length(trim(display_name)) between 1 and 100)
);

create table public.cvs (
  id uuid primary key,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  title text not null,
  template_id text not null default 'harvard_ats',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  server_updated_at timestamptz not null default now(),
  constraint cvs_title_length
    check (char_length(trim(title)) between 1 and 160),
  constraint cvs_template_id
    check (template_id in ('harvard_ats', 'modern_minimalist')),
  constraint cvs_payload_is_object
    check (jsonb_typeof(payload) = 'object'),
  constraint cvs_timestamp_order
    check (created_at <= updated_at)
);

create index cvs_user_id_idx on public.cvs using btree (user_id);
create index cvs_user_updated_at_idx
  on public.cvs using btree (user_id, updated_at desc);

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''))
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.touch_updated_at()
  from public, anon, authenticated;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute procedure public.touch_updated_at();

create function public.touch_server_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.server_updated_at = now();
  return new;
end;
$$;

revoke all on function public.touch_server_updated_at()
  from public, anon, authenticated;

create trigger cvs_touch_server_updated_at
  before update on public.cvs
  for each row execute procedure public.touch_server_updated_at();

alter table public.profiles enable row level security;
alter table public.cvs enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.cvs from anon, authenticated;

grant select, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.cvs to authenticated;

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id);

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id)
with check ((select auth.uid()) is not null and (select auth.uid()) = id);

create policy "cvs_select_own"
on public.cvs
for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "cvs_insert_own"
on public.cvs
for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "cvs_update_own"
on public.cvs
for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "cvs_delete_own"
on public.cvs
for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

commit;
