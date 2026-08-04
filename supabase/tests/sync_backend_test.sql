begin;

create extension if not exists pgtap with schema extensions;
select plan(28);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'student-a@example.invalid', '', now(), now(), now(), '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'student-b@example.invalid', '', now(), now(), now(), '{}', '{}');

set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';

select ok(
  (public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000001',
    'preceptor', '30000000-0000-4000-8000-000000000001', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'preceptor',
      'entity_id', '30000000-0000-4000-8000-000000000001',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:00:00.000Z',
      'updated_at_utc', '2026-08-03T12:00:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Primary Preceptor')
    )
  ) ->> 'accepted')::boolean,
  'accepts an owned Preceptor'
);

select is(
  (public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000001',
    'preceptor', '30000000-0000-4000-8000-000000000001', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'preceptor',
      'entity_id', '30000000-0000-4000-8000-000000000001',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:00:00.000Z',
      'updated_at_utc', '2026-08-03T12:00:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Primary Preceptor')
    )
  ) ->> 'cursor')::bigint,
  1::bigint,
  'an identical idempotency key returns the original cursor'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000001',
    'preceptor', '30000000-0000-4000-8000-000000000099', 'upsert', 0, '{}'::jsonb
  ) #>> '{rejection,code}',
  'idempotency_conflict',
  'an idempotency key cannot be reused for different input'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000002',
    'preceptor', '30000000-0000-4000-8000-000000000001', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'preceptor',
      'entity_id', '30000000-0000-4000-8000-000000000001',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:00:00.000Z',
      'updated_at_utc', '2026-08-03T12:01:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Changed')
    )
  ) #>> '{rejection,code}',
  'stale_revision',
  'a stale base revision is rejected'
);

select is(
  (select count(*) from clinical_calendar_sync.records
    where student_id = nullif(current_setting('request.jwt.claim.sub', true), '')::uuid),
  1::bigint,
  'a rejected mutation writes no record'
);
select is(
  (select count(*) from clinical_calendar_sync.change_feed
    where student_id = nullif(current_setting('request.jwt.claim.sub', true), '')::uuid),
  1::bigint,
  'a rejected mutation writes no change event'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000010',
    'settings', '30000000-0000-4000-8000-000000000010', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'settings',
      'entity_id', '30000000-0000-4000-8000-000000000010',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:00:00.000Z',
      'updated_at_utc', '2026-08-03T12:00:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'week_start', 7, 'time_display', 'military',
        'theme', 'variant-f', 'synchronization_mode', 'enabled',
        'notification_preferences_json', '{}', 'active_placement_id', null
      )
    )
  ) #>> '{rejection,field}',
  'settings_identity',
  'Settings identity must equal the authenticated Student identity'
);

select ok(
  (public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000003',
    'clinical_placement', '30000000-0000-4000-8000-000000000002', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'clinical_placement',
      'entity_id', '30000000-0000-4000-8000-000000000002',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:02:00.000Z',
      'updated_at_utc', '2026-08-03T12:02:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'name', 'Family Medicine', 'target_minutes', 16200,
        'start_date', '2026-08-01', 'completion_deadline', '2026-12-31',
        'lifecycle_state', 'active',
        'primary_preceptor_id', '30000000-0000-4000-8000-000000000001',
        'attached_preceptor_ids', jsonb_build_array('30000000-0000-4000-8000-000000000001'),
        'evaluation_plan_id', '30000000-0000-4000-8000-000000000003'
      )
    )
  ) ->> 'accepted')::boolean,
  'accepts a Clinical Placement with one attached Primary Preceptor'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000004',
    'clinical_session', '30000000-0000-4000-8000-000000000004', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'clinical_session',
      'entity_id', '30000000-0000-4000-8000-000000000004',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:03:00.000Z',
      'updated_at_utc', '2026-08-03T12:03:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'commitment_type', 'clinical_session', 'lifecycle_state', 'scheduled',
        'placement_id', '30000000-0000-4000-8000-000000000002',
        'preceptor_id', '30000000-0000-4000-8000-000000000099',
        'planned_start_date', '2026-08-10', 'planned_end_date', '2026-08-10',
        'planned_start_minutes', 540, 'planned_end_minutes', 600,
        'time_zone', 'America/New_York',
        'planned_start_offset_minutes', -240, 'planned_end_offset_minutes', -240,
        'planned_start_utc', '2026-08-10T13:00:00.000Z',
        'planned_end_utc', '2026-08-10T14:00:00.000Z'
      )
    )
  ) #>> '{rejection,relationship}',
  'attached_preceptor',
  'rejects a Clinical Session assigned to a detached Preceptor'
);

select ok(
  (public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000005',
    'work_shift', '30000000-0000-4000-8000-000000000005', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_shift',
      'entity_id', '30000000-0000-4000-8000-000000000005',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:04:00.000Z',
      'updated_at_utc', '2026-08-03T12:04:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'commitment_type', 'work_shift', 'lifecycle_state', 'scheduled',
        'planned_start_date', '2026-08-10', 'planned_end_date', '2026-08-10',
        'planned_start_minutes', 540, 'planned_end_minutes', 600,
        'time_zone', 'America/New_York',
        'planned_start_offset_minutes', -240, 'planned_end_offset_minutes', -240,
        'planned_start_utc', '2026-08-10T13:00:00.000Z',
        'planned_end_utc', '2026-08-10T14:00:00.000Z'
      )
    )
  ) ->> 'accepted')::boolean,
  'accepts a nonconflicting Work Shift'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000006',
    'work_shift', '30000000-0000-4000-8000-000000000006', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_shift',
      'entity_id', '30000000-0000-4000-8000-000000000006',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:05:00.000Z',
      'updated_at_utc', '2026-08-03T12:05:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'commitment_type', 'work_shift', 'lifecycle_state', 'scheduled',
        'planned_start_date', '2026-08-10', 'planned_end_date', '2026-08-10',
        'planned_start_minutes', 570, 'planned_end_minutes', 630,
        'time_zone', 'America/New_York',
        'planned_start_offset_minutes', -240, 'planned_end_offset_minutes', -240,
        'planned_start_utc', '2026-08-10T13:30:00.000Z',
        'planned_end_utc', '2026-08-10T14:30:00.000Z'
      )
    )
  ) #>> '{rejection,code}',
  'schedule_conflict',
  'rejects an overlapping Work Shift'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000007',
    'protected_day', '30000000-0000-4000-8000-000000000007', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'protected_day',
      'entity_id', '30000000-0000-4000-8000-000000000007',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-03T12:06:00.000Z',
      'updated_at_utc', '2026-08-03T12:06:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('local_date', '2026-08-10', 'week_start_date', '2026-08-09')
    )
  ) #>> '{rejection,code}',
  'protected_day_violation',
  'rejects a Protected Day touched by a commitment'
);

select is(
  (select count(*) from public.pull_changes_after(0, 100)),
  3::bigint,
  'pull returns only accepted changes'
);
select results_eq(
  $$select cursor from public.pull_changes_after(0, 100)$$,
  $$values (1::bigint), (2::bigint), (3::bigint)$$,
  'pull is completely ordered by the per-Student cursor'
);
select results_eq(
  $$select cursor from public.pull_changes_after(1, 1)$$,
  $$values (2::bigint)$$,
  'pull uses cursor keyset pagination'
);
select results_eq(
  $$select cursor from public.pull_changes_after(2, 100)$$,
  $$values (3::bigint)$$,
  'retrying after the last durable cursor is stable'
);

select ok(
  (public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000008',
    'work_shift', '30000000-0000-4000-8000-000000000005', 'delete', 1,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_shift',
      'entity_id', '30000000-0000-4000-8000-000000000005',
      'student_id', '10000000-0000-4000-8000-000000000001',
      'revision', 2, 'created_at_utc', '2026-08-03T12:04:00.000Z',
      'updated_at_utc', '2026-08-03T12:07:00.000Z',
      'deleted_at_utc', '2026-08-03T12:07:00.000Z',
      'value', jsonb_build_object(
        'commitment_type', 'work_shift', 'lifecycle_state', 'scheduled',
        'planned_start_date', '2026-08-10', 'planned_end_date', '2026-08-10',
        'planned_start_minutes', 540, 'planned_end_minutes', 600,
        'planned_start_utc', '2026-08-10T13:00:00.000Z',
        'planned_end_utc', '2026-08-10T14:00:00.000Z'
      )
    )
  ) ->> 'accepted')::boolean,
  'accepts a valid deletion tombstone'
);
select is(
  (select operation_type from public.pull_changes_after(3, 100)),
  'delete',
  'pull includes tombstones'
);

set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000002';
select is(
  (select count(*) from clinical_calendar_sync.records),
  0::bigint,
  'RLS hides another Student records'
);
select is(
  (select count(*) from public.pull_changes_after(0, 100)),
  0::bigint,
  'RLS hides another Student change feed'
);

select is(
  public.apply_sync_operation(
    '20000000-0000-4000-8000-000000000009',
    'preceptor', '30000000-0000-4000-8000-000000000001', 'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'preceptor',
      'entity_id', '30000000-0000-4000-8000-000000000001',
      'student_id', '10000000-0000-4000-8000-000000000002',
      'revision', 1, 'created_at_utc', '2026-08-03T12:08:00.000Z',
      'updated_at_utc', '2026-08-03T12:08:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Collision')
    )
  ) #>> '{rejection,code}',
  'ownership_violation',
  'a globally owned entity identity cannot be claimed by another Student'
);

select is(
  (select count(*) from clinical_calendar_sync.operation_receipts
   where result is null),
  0::bigint,
  'every persisted operation receipt has a durable result'
);

select ok(
  (select relrowsecurity and relforcerowsecurity
   from pg_class where oid = 'clinical_calendar_sync.records'::regclass),
  'records force RLS'
);
select ok(
  (select relrowsecurity and relforcerowsecurity
   from pg_class where oid = 'clinical_calendar_sync.change_feed'::regclass),
  'change feed forces RLS'
);
select ok(
  not has_table_privilege('authenticated', 'clinical_calendar_sync.records', 'INSERT'),
  'authenticated receives no direct record write privilege'
);
select ok(
  not has_table_privilege('anon', 'clinical_calendar_sync.records', 'SELECT'),
  'anonymous clients receive no record privilege'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.apply_sync_operation(uuid,text,uuid,text,bigint,jsonb)',
    'EXECUTE'
  ),
  'authenticated may execute only the write RPC'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.apply_sync_operation(uuid,text,uuid,text,bigint,jsonb)',
    'EXECUTE'
  ),
  'anonymous clients cannot execute the write RPC'
);

select * from finish();
rollback;
