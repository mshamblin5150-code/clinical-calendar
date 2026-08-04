-- Run concurrently with concurrency_session_b.sql after sync_backend_test.sql
-- fixture setup is adapted to COMMIT rather than ROLLBACK. Both operations use
-- the same Student and base revision. Exactly one must be accepted.
begin;
set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '15000000-0000-4000-8000-000000000010';
select public.apply_sync_operation(
  '21000000-0000-4000-8000-000000000001',
  'preceptor', '30000000-0000-4000-8000-000000000001', 'upsert', 1,
  jsonb_build_object(
    'schema_version', 1, 'entity_type', 'preceptor',
    'entity_id', '30000000-0000-4000-8000-000000000001',
    'student_id', '10000000-0000-4000-8000-000000000001',
    'revision', 2, 'created_at_utc', '2026-08-03T12:00:00.000Z',
    'updated_at_utc', '2026-08-03T13:00:00.000Z', 'deleted_at_utc', null,
    'value', jsonb_build_object('name', 'Concurrent A')
  )
);
commit;
