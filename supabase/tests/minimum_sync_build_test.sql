begin;

create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '91000000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'minimum-build@example.invalid', '',
  now(), now(), now(), '{}', '{}'
);

set local role authenticated;
set local request.jwt.claim.sub = '91000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '92000000-0000-4000-8000-000000000001';
select public.register_current_device(
  '93000000-0000-4000-8000-000000000001',
  'Minimum build test device',
  'windows'
);

select ok(
  (public.apply_sync_operation(
    46,
    '94000000-0000-4000-8000-000000000001',
    'preceptor', '95000000-0000-4000-8000-000000000001', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'preceptor',
      'entity_id', '95000000-0000-4000-8000-000000000001',
      'student_id', '91000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:00:00.000Z',
      'updated_at_utc', '2026-09-27T12:00:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Current Build Preceptor')
    )
  ) ->> 'accepted')::boolean,
  'a build at the minimum can push'
);

select is(
  public.apply_sync_operation(
    45,
    '94000000-0000-4000-8000-000000000002',
    'preceptor', '95000000-0000-4000-8000-000000000002', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'preceptor',
      'entity_id', '95000000-0000-4000-8000-000000000002',
      'student_id', '91000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:01:00.000Z',
      'updated_at_utc', '2026-09-27T12:01:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Old Build Preceptor')
    )
  ) #>> '{rejection,code}',
  'minimum_sync_build_required',
  'a build below the minimum receives the stable rejection code'
);

select is(
  public.apply_sync_operation(
    45,
    '94000000-0000-4000-8000-000000000003',
    'preceptor', '95000000-0000-4000-8000-000000000003', 'upsert', 0,
    '{}'::jsonb
  ) #>> '{rejection,minimum_build}',
  '46',
  'the rejection tells the client which build is required'
);

select is(
  (select count(*) from public.pull_changes_after(45, 0, 100)),
  1::bigint,
  'a build below the minimum can still pull'
);

select * from finish();
rollback;
