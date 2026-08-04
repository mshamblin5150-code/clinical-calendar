\set ON_ERROR_STOP on
begin;
set local role authenticated;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '72000000-0000-4000-8000-000000000002';
select public.apply_sync_operation(
  '74000000-0000-4000-8000-000000000002',
  'settings', '71000000-0000-4000-8000-000000000001', 'upsert', 1,
  jsonb_build_object(
    'schema_version', 1, 'entity_type', 'settings',
    'entity_id', '71000000-0000-4000-8000-000000000001',
    'student_id', '71000000-0000-4000-8000-000000000001',
    'revision', 2, 'created_at_utc', '2026-08-04T12:00:00.000Z',
    'updated_at_utc', '2026-08-04T12:01:00.000Z', 'deleted_at_utc', null,
    'value', jsonb_build_object(
      'week_start', 1, 'time_display', 'military', 'theme', 'variant-f',
      'synchronization_mode', 'enabled',
      'notification_preferences_json', '{}', 'active_placement_id', null
    )
  )
);
commit;
