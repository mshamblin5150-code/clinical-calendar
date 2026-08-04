\set ON_ERROR_STOP on
select pg_sleep(0.25);
begin;
set local role authenticated;
set local request.jwt.claim.sub = '82500000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '82700000-0000-4000-8000-000000000001';
insert into public.permanent_purge_concurrency_results (
  session_name, accepted, result_code
)
select 'B', (result ->> 'accepted')::boolean, result #>> '{rejection,code}'
from (
  select public.apply_sync_operation(
    '82900000-0000-4000-8000-000000000002',
    'schedule_template', '82800000-0000-4000-8000-000000000001',
    'upsert', 2,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82800000-0000-4000-8000-000000000001',
      'student_id', '82500000-0000-4000-8000-000000000001',
      'revision', 3, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:04:00Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Concurrent resurrection')
    )
  ) result
) operation;
commit;
