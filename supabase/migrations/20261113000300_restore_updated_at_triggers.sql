-- Restores the triggers that keep updated_at current on CV tables.
-- Sync between devices keeps the newest copy by updated_at; without these
-- triggers an edit saved on one device never looks newer to the others.
-- Safe to run more than once.

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

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
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
