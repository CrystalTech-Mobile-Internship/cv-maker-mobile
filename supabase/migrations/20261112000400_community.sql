begin;

-- Community feed: discussions, job sharing and CV review requests.
-- Signed-in users only. Authors control their own content; reports hide
-- abusive posts automatically for moderation.

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  author_name text not null default 'Thành viên',
  kind text not null default 'discussion',
  title text not null,
  body text not null,
  tags text[] not null default '{}',
  job_company text,
  job_location text,
  job_url text,
  job_salary text,
  like_count integer not null default 0,
  comment_count integer not null default 0,
  report_count integer not null default 0,
  is_hidden boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint community_posts_kind check (kind in ('discussion', 'job', 'cv_review')),
  constraint community_posts_title_length check (char_length(trim(title)) between 5 and 140),
  constraint community_posts_body_length check (char_length(trim(body)) between 10 and 4000),
  constraint community_posts_author_name_length check (char_length(author_name) between 1 and 60),
  constraint community_posts_tags_count check (cardinality(tags) <= 5),
  constraint community_posts_job_url check (job_url is null or job_url ~* '^https?://'),
  constraint community_posts_job_fields check (
    coalesce(char_length(job_company), 0) <= 120
    and coalesce(char_length(job_location), 0) <= 120
    and coalesce(char_length(job_salary), 0) <= 60
    and coalesce(char_length(job_url), 0) <= 500
  )
);

create index if not exists community_posts_feed_idx
  on public.community_posts (is_hidden, created_at desc);
create index if not exists community_posts_kind_idx
  on public.community_posts (kind, created_at desc);
create index if not exists community_posts_author_idx
  on public.community_posts (author_id, created_at desc);

create table if not exists public.community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  author_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  author_name text not null default 'Thành viên',
  body text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint community_comments_body_length check (char_length(trim(body)) between 1 and 1500),
  constraint community_comments_author_name_length check (char_length(author_name) between 1 and 60)
);

create index if not exists community_comments_post_idx
  on public.community_comments (post_id, created_at);

create table if not exists public.community_likes (
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (post_id, user_id)
);

create table if not exists public.community_reports (
  post_id uuid not null references public.community_posts (id) on delete cascade,
  reporter_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (post_id, reporter_id),
  constraint community_reports_reason_length check (char_length(reason) between 3 and 300)
);

alter table public.community_posts enable row level security;
alter table public.community_comments enable row level security;
alter table public.community_likes enable row level security;
alter table public.community_reports enable row level security;

revoke all on table public.community_posts from anon, authenticated;
revoke all on table public.community_comments from anon, authenticated;
revoke all on table public.community_likes from anon, authenticated;
revoke all on table public.community_reports from anon, authenticated;

grant select, delete on table public.community_posts to authenticated;
grant insert (author_name, kind, title, body, tags, job_company, job_location, job_url, job_salary)
  on table public.community_posts to authenticated;
grant update (title, body, tags, job_company, job_location, job_url, job_salary)
  on table public.community_posts to authenticated;
grant select, delete on table public.community_comments to authenticated;
grant insert (post_id, author_name, body) on table public.community_comments to authenticated;
grant select, insert, delete on table public.community_likes to authenticated;
grant insert (post_id, reason) on table public.community_reports to authenticated;

-- Posts: everyone signed in sees visible posts; authors also see their own.
drop policy if exists community_posts_select on public.community_posts;
create policy community_posts_select on public.community_posts
for select to authenticated
using (not is_hidden or (select auth.uid()) = author_id);

drop policy if exists community_posts_insert_own on public.community_posts;
create policy community_posts_insert_own on public.community_posts
for insert to authenticated
with check ((select auth.uid()) = author_id);

drop policy if exists community_posts_update_own on public.community_posts;
create policy community_posts_update_own on public.community_posts
for update to authenticated
using ((select auth.uid()) = author_id)
with check ((select auth.uid()) = author_id);

drop policy if exists community_posts_delete_own on public.community_posts;
create policy community_posts_delete_own on public.community_posts
for delete to authenticated
using ((select auth.uid()) = author_id);

-- Comments: readable on visible posts; write/delete own.
drop policy if exists community_comments_select on public.community_comments;
create policy community_comments_select on public.community_comments
for select to authenticated
using (exists (
  select 1 from public.community_posts p
  where p.id = post_id and (not p.is_hidden or p.author_id = (select auth.uid()))
));

drop policy if exists community_comments_insert_own on public.community_comments;
create policy community_comments_insert_own on public.community_comments
for insert to authenticated
with check (
  (select auth.uid()) = author_id
  and exists (select 1 from public.community_posts p where p.id = post_id and not p.is_hidden)
);

drop policy if exists community_comments_delete_own on public.community_comments;
create policy community_comments_delete_own on public.community_comments
for delete to authenticated
using ((select auth.uid()) = author_id);

-- Likes: users manage only their own like rows.
drop policy if exists community_likes_select on public.community_likes;
create policy community_likes_select on public.community_likes
for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists community_likes_insert_own on public.community_likes;
create policy community_likes_insert_own on public.community_likes
for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists community_likes_delete_own on public.community_likes;
create policy community_likes_delete_own on public.community_likes
for delete to authenticated
using ((select auth.uid()) = user_id);

-- Reports: insert only (one per user per post); moderators use the dashboard.
drop policy if exists community_reports_insert_own on public.community_reports;
create policy community_reports_insert_own on public.community_reports
for insert to authenticated
with check ((select auth.uid()) = reporter_id);

-- Counters, auto-hide and rate limits (security definer, fixed search_path).
create or replace function public.community_bump_counter()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_post uuid := coalesce(new.post_id, old.post_id);
  v_delta integer := case when tg_op = 'INSERT' then 1 else -1 end;
begin
  if tg_table_name = 'community_likes' then
    update public.community_posts
    set like_count = greatest(like_count + v_delta, 0) where id = v_post;
  elsif tg_table_name = 'community_comments' then
    update public.community_posts
    set comment_count = greatest(comment_count + v_delta, 0) where id = v_post;
  elsif tg_table_name = 'community_reports' then
    update public.community_posts
    set report_count = report_count + 1,
        is_hidden = is_hidden or report_count + 1 >= 3
    where id = v_post;
  end if;
  return null;
end;
$$;

revoke all on function public.community_bump_counter() from public, anon, authenticated;

drop trigger if exists community_likes_count on public.community_likes;
create trigger community_likes_count
  after insert or delete on public.community_likes
  for each row execute function public.community_bump_counter();

drop trigger if exists community_comments_count on public.community_comments;
create trigger community_comments_count
  after insert or delete on public.community_comments
  for each row execute function public.community_bump_counter();

drop trigger if exists community_reports_count on public.community_reports;
create trigger community_reports_count
  after insert on public.community_reports
  for each row execute function public.community_bump_counter();

create or replace function public.community_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_recent integer;
begin
  if tg_table_name = 'community_posts' then
    select count(*) into v_recent from public.community_posts
    where author_id = new.author_id
      and created_at > timezone('utc', now()) - interval '1 hour';
    if v_recent >= 5 then
      raise exception 'community_rate_limited' using errcode = 'P0001';
    end if;
  else
    select count(*) into v_recent from public.community_comments
    where author_id = new.author_id
      and created_at > timezone('utc', now()) - interval '10 minutes';
    if v_recent >= 20 then
      raise exception 'community_rate_limited' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;

revoke all on function public.community_rate_limit() from public, anon, authenticated;

drop trigger if exists community_posts_rate_limit on public.community_posts;
create trigger community_posts_rate_limit
  before insert on public.community_posts
  for each row execute function public.community_rate_limit();

drop trigger if exists community_comments_rate_limit on public.community_comments;
create trigger community_comments_rate_limit
  before insert on public.community_comments
  for each row execute function public.community_rate_limit();

drop trigger if exists community_posts_set_updated_at on public.community_posts;
create trigger community_posts_set_updated_at
  before update on public.community_posts
  for each row execute function public.set_updated_at();

commit;
