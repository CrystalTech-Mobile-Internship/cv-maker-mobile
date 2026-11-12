-- Smart CV Maker - initial database schema
-- Run this file once in Supabase Dashboard > SQL Editor.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.templates (
  id text primary key,
  name text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

insert into public.templates (id, name, description)
values
  ('harvard_ats', 'Harvard ATS', 'Một cột, ưu tiên hệ thống ATS'),
  ('modern_minimalist', 'Modern Minimalist', 'Hiện đại và tối giản'),
  ('minimalist_clean', 'Minimalist Clean', 'Sạch, phù hợp nhiều ngành'),
  ('creative_tech', 'Creative Tech', 'Dành cho công nghệ và sáng tạo'),
  ('professional_sidebar', 'Professional Sidebar', 'Bố cục 1/3 và 2/3'),
  ('executive_navy', 'Executive Navy', 'Doanh nghiệp, quản lý và kinh doanh'),
  ('academic_classic', 'Academic Classic', 'Giáo dục và nghiên cứu'),
  ('fresh_profile', 'Fresh Profile', 'Marketing, dịch vụ và hồ sơ có ảnh')
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  is_active = true;

create table if not exists public.cvs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'CV chưa đặt tên',
  template_id text references public.templates(id) on delete set null,
  primary_color text not null default '#1E293B',
  font_size_scale numeric(4, 2) not null default 1.0
    check (font_size_scale between 0.5 and 2.0),
  summary text,
  personal_info jsonb not null default '{}'::jsonb,
  layout_settings jsonb not null default '{}'::jsonb,
  is_public boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.cv_sections (
  id uuid primary key default gen_random_uuid(),
  cv_id uuid not null references public.cvs(id) on delete cascade,
  section_type text not null check (
    section_type in (
      'education', 'experience', 'skills', 'projects', 'certifications'
    )
  ),
  title text not null,
  order_index integer not null default 0,
  is_visible boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (cv_id, section_type)
);

create table if not exists public.cv_items (
  id uuid primary key default gen_random_uuid(),
  cv_id uuid not null references public.cvs(id) on delete cascade,
  section_id uuid not null references public.cv_sections(id) on delete cascade,
  item_type text not null,
  payload jsonb not null default '{}'::jsonb,
  order_index integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists cvs_user_id_idx on public.cvs(user_id);
create index if not exists cv_sections_cv_id_idx on public.cv_sections(cv_id);
create index if not exists cv_items_cv_id_idx on public.cv_items(cv_id);
create index if not exists cv_items_section_id_idx on public.cv_items(section_id);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists templates_set_updated_at on public.templates;
create trigger templates_set_updated_at
before update on public.templates
for each row execute function public.set_updated_at();

drop trigger if exists cvs_set_updated_at on public.cvs;
create trigger cvs_set_updated_at
before update on public.cvs
for each row execute function public.set_updated_at();

drop trigger if exists cv_sections_set_updated_at on public.cv_sections;
create trigger cv_sections_set_updated_at
before update on public.cv_sections
for each row execute function public.set_updated_at();

drop trigger if exists cv_items_set_updated_at on public.cv_items;
create trigger cv_items_set_updated_at
before update on public.cv_items
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.email));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.templates enable row level security;
alter table public.cvs enable row level security;
alter table public.cv_sections enable row level security;
alter table public.cv_items enable row level security;

-- Profiles: a user can only access their own profile.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select using (id = auth.uid());

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
for insert with check (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own on public.profiles
for delete using (id = auth.uid());

-- Templates are read-only reference data for authenticated users.
drop policy if exists templates_select_active on public.templates;
create policy templates_select_active on public.templates
for select using (auth.role() = 'authenticated' and is_active = true);

-- CVs: ownership is explicit and enforced by both using and with check.
drop policy if exists cvs_select_own on public.cvs;
create policy cvs_select_own on public.cvs
for select using (user_id = auth.uid());

drop policy if exists cvs_insert_own on public.cvs;
create policy cvs_insert_own on public.cvs
for insert with check (user_id = auth.uid());

drop policy if exists cvs_update_own on public.cvs;
create policy cvs_update_own on public.cvs
for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists cvs_delete_own on public.cvs;
create policy cvs_delete_own on public.cvs
for delete using (user_id = auth.uid());

-- Sections and items inherit ownership from their parent CV.
drop policy if exists cv_sections_select_own on public.cv_sections;
create policy cv_sections_select_own on public.cv_sections
for select using (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_sections.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_sections_insert_own on public.cv_sections;
create policy cv_sections_insert_own on public.cv_sections
for insert with check (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_sections.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_sections_update_own on public.cv_sections;
create policy cv_sections_update_own on public.cv_sections
for update using (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_sections.cv_id and cvs.user_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_sections.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_sections_delete_own on public.cv_sections;
create policy cv_sections_delete_own on public.cv_sections
for delete using (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_sections.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_items_select_own on public.cv_items;
create policy cv_items_select_own on public.cv_items
for select using (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_items.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_items_insert_own on public.cv_items;
create policy cv_items_insert_own on public.cv_items
for insert with check (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_items.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_items_update_own on public.cv_items;
create policy cv_items_update_own on public.cv_items
for update using (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_items.cv_id and cvs.user_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_items.cv_id and cvs.user_id = auth.uid()
  )
);

drop policy if exists cv_items_delete_own on public.cv_items;
create policy cv_items_delete_own on public.cv_items
for delete using (
  exists (
    select 1 from public.cvs
    where cvs.id = cv_items.cv_id and cvs.user_id = auth.uid()
  )
);
