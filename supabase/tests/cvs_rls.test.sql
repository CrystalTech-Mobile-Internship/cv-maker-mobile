begin;

select plan(15);

insert into auth.users (id, email)
values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'other@example.com');

select has_table('public', 'profiles', 'profiles table exists');
select has_table('public', 'cvs', 'cvs table exists');

select ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'profiles has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.cvs'::regclass),
  'cvs has RLS enabled'
);

select ok(
  not has_table_privilege('anon', 'public.cvs', 'select,insert,update,delete'),
  'anon has no CV table privileges'
);
select ok(
  has_table_privilege(
    'authenticated',
    'public.cvs',
    'select,insert,update,delete'
  ),
  'authenticated has the CRUD grants filtered by RLS'
);

set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select results_eq(
  $$select id::text from public.profiles where id = '11111111-1111-1111-1111-111111111111'$$,
  array['11111111-1111-1111-1111-111111111111']::text[],
  'signup trigger creates a profile visible to its owner'
);

select results_eq(
  $$
    insert into public.cvs (
      id,
      user_id,
      title,
      template_id,
      payload,
      created_at,
      updated_at
    ) values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      '11111111-1111-1111-1111-111111111111',
      'CV của người sở hữu',
      'harvard_ats',
      '{}'::jsonb,
      '2026-10-06T08:00:00Z',
      '2026-10-06T08:00:00Z'
    )
    returning title
  $$,
  array['CV của người sở hữu']::text[],
  'owner creates their own CV'
);

select results_eq(
  $$select title from public.cvs where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  array['CV của người sở hữu']::text[],
  'owner reads their own CV'
);

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

select throws_ok(
  $$
    insert into public.cvs (
      id,
      user_id,
      title,
      template_id,
      payload,
      created_at,
      updated_at
    ) values (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      '11111111-1111-1111-1111-111111111111',
      'CV giả mạo',
      'harvard_ats',
      '{}'::jsonb,
      '2026-10-06T08:00:00Z',
      '2026-10-06T08:00:00Z'
    )
  $$,
  '42501',
  null,
  'another user cannot create a CV for the owner'
);

select is_empty(
  $$select id from public.cvs$$,
  'another user reads no owner CVs'
);

select is_empty(
  $$
    update public.cvs
    set title = 'Đã bị sửa'
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    returning id
  $$,
  'another user updates no owner CVs'
);

set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select results_eq(
  $$select title from public.cvs where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  array['CV của người sở hữu']::text[],
  'denied update leaves the owner CV intact'
);

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

select is_empty(
  $$
    delete from public.cvs
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    returning id
  $$,
  'another user deletes no owner CVs'
);

set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select results_eq(
  $$
    delete from public.cvs
    where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    returning title
  $$,
  array['CV của người sở hữu']::text[],
  'owner deletes their own CV'
);

select * from finish();
rollback;
