begin;

create extension if not exists pgtap with schema extensions;
select plan(11);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, last_sign_in_at, created_at, updated_at,
  email_change, raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'stale-unconfirmed@example.invalid', '', null, null,
   clock_timestamp() - interval '8 days', clock_timestamp(), '', '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'recent-unconfirmed@example.invalid', '', null, null,
   clock_timestamp() - interval '6 days', clock_timestamp(), '', '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated',
   'confirmed@example.invalid', '', clock_timestamp() - interval '8 days', null,
   clock_timestamp() - interval '9 days', clock_timestamp(), '', '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated',
   'signed-in@example.invalid', '', null, clock_timestamp() - interval '1 day',
   clock_timestamp() - interval '8 days', clock_timestamp(), '', '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated',
   'connected@example.invalid', '', null, null,
   clock_timestamp() - interval '8 days', clock_timestamp(), '', '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated',
   'original-confirmed@example.invalid', '',
   clock_timestamp() - interval '8 days', null,
   clock_timestamp() - interval '9 days', clock_timestamp(),
   'pending-address@example.invalid', '{}', '{}');

insert into clinical_calendar_sync.connected_devices (
  device_id, student_id, session_id, device_name, platform
) values (
  '85100000-0000-4000-8000-000000000001',
  '85000000-0000-4000-8000-000000000005',
  '85200000-0000-4000-8000-000000000001',
  'Protected browser', 'web'
);

select is(
  clinical_calendar_sync.delete_never_confirmed_auth_users(),
  1::bigint,
  'cleanup deletes exactly the stale never-confirmed account'
);
select ok(
  not exists (
    select 1 from auth.users
    where id = '85000000-0000-4000-8000-000000000001'
  ),
  'an unconfirmed eight-day-old account without a device is deleted'
);
select ok(
  exists (
    select 1 from auth.users
    where id = '85000000-0000-4000-8000-000000000002'
  ),
  'an unconfirmed six-day-old account is kept'
);
select ok(
  exists (
    select 1 from auth.users
    where id = '85000000-0000-4000-8000-000000000003'
  ),
  'a confirmed account is kept'
);
select ok(
  exists (
    select 1 from auth.users
    where id = '85000000-0000-4000-8000-000000000004'
  ),
  'an account that has signed in is kept'
);
select ok(
  exists (
    select 1 from auth.users
    where id = '85000000-0000-4000-8000-000000000005'
  ),
  'an account with a Connected Device is kept'
);
select ok(
  exists (
    select 1 from auth.users
    where id = '85000000-0000-4000-8000-000000000006'
  ),
  'a confirmed account with a pending email change is kept'
);
select ok(
  not has_function_privilege(
    'anon',
    'clinical_calendar_sync.delete_never_confirmed_auth_users()',
    'EXECUTE'
  ),
  'anonymous clients cannot invoke unconfirmed-account cleanup'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'clinical_calendar_sync.delete_never_confirmed_auth_users()',
    'EXECUTE'
  ),
  'authenticated clients cannot invoke unconfirmed-account cleanup'
);
select ok(
  exists (
    select 1
    from cron.job
    where jobname = 'clinical-calendar-delete-never-confirmed-auth-users'
      and schedule = '0 3 * * *'
      and command =
        'select clinical_calendar_sync.delete_never_confirmed_auth_users()'
  ),
  'the cleanup function is scheduled once a day'
);
select is(
  clinical_calendar_sync.delete_never_confirmed_auth_users(),
  0::bigint,
  'cleanup is safe to retry when no additional account is eligible'
);

select * from finish();
rollback;
