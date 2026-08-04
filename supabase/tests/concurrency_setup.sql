-- Committed fixture for the two-session concurrency test. Run only against a
-- disposable `supabase start` database.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '10000000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'concurrency@example.invalid', '',
  now(), now(), now(), '{}', '{}'
) on conflict (id) do nothing;

begin;
set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '15000000-0000-4000-8000-000000000010';
select public.register_current_device(
  '16000000-0000-4000-8000-000000000010', 'Concurrency device', 'windows'
);
select public.apply_sync_operation(
  '20000000-0000-4000-8000-000000000001',
  'preceptor', '30000000-0000-4000-8000-000000000001', 'upsert', 0,
  jsonb_build_object(
    'schema_version', 1, 'entity_type', 'preceptor',
    'entity_id', '30000000-0000-4000-8000-000000000001',
    'student_id', '10000000-0000-4000-8000-000000000001',
    'revision', 1, 'created_at_utc', '2026-08-03T12:00:00.000Z',
    'updated_at_utc', '2026-08-03T12:00:00.000Z', 'deleted_at_utc', null,
    'value', jsonb_build_object('name', 'Concurrent Preceptor')
  )
);
commit;
