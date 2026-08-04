\set ON_ERROR_STOP on
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '71000000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'revoke-race@example.invalid', '',
  now(), now(), now(), '{}', '{}'
) on conflict (id) do nothing;

begin;
set local role authenticated;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '72000000-0000-4000-8000-000000000001';
select public.register_current_device(
  '73000000-0000-4000-8000-000000000001', 'Owner device', 'windows'
);
set local request.jwt.claim.session_id = '72000000-0000-4000-8000-000000000002';
select public.register_current_device(
  '73000000-0000-4000-8000-000000000002', 'Device to revoke', 'android'
);
select public.apply_sync_operation(
  '74000000-0000-4000-8000-000000000001',
  'settings', '71000000-0000-4000-8000-000000000001', 'upsert', 0,
  jsonb_build_object(
    'schema_version', 1, 'entity_type', 'settings',
    'entity_id', '71000000-0000-4000-8000-000000000001',
    'student_id', '71000000-0000-4000-8000-000000000001',
    'revision', 1, 'created_at_utc', '2026-08-04T12:00:00.000Z',
    'updated_at_utc', '2026-08-04T12:00:00.000Z', 'deleted_at_utc', null,
    'value', jsonb_build_object(
      'week_start', 7, 'time_display', 'military', 'theme', 'variant-f',
      'synchronization_mode', 'enabled',
      'notification_preferences_json', '{}', 'active_placement_id', null
    )
  )
);
commit;
