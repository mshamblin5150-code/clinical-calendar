begin;

create extension if not exists pgtap with schema extensions;
select plan(28);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000',
   '82000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'purge-a@example.invalid', '', now(), now(), now(), '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '82000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'purge-b@example.invalid', '', now(), now(), now(), '{}', '{}');

set local role authenticated;
set local request.jwt.claim.sub = '82000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '82100000-0000-4000-8000-000000000001';
select ok(
  public.register_current_device(
    '82200000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  'registers the owner device'
);

select ok(
  (public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000001',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:00:00Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'Private template contents')
    )
  ) ->> 'accepted')::boolean,
  'creates an ordinary synchronized entity'
);

select is(
  public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000002',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'purge', 1,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 2, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:02:00Z', 'deleted_at_utc', null,
      'purged_at_utc', '2026-08-04T12:02:00Z', 'value', '{}'::jsonb
    )
  ) #>> '{rejection,code}',
  'not_in_trash',
  'permanent purge requires an existing tombstone'
);

select ok(
  (public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000003',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'delete', 1,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 2, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:01:00Z',
      'deleted_at_utc', '2026-08-04T12:01:00Z',
      'value', jsonb_build_object('name', 'Private template contents')
    )
  ) ->> 'accepted')::boolean,
  'moves the entity into synchronized Trash'
);

select is(
  public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000004',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'purge', 2,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 3, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:03:00Z',
      'deleted_at_utc', '2026-08-04T12:01:00Z',
      'purged_at_utc', '2026-08-04T12:03:00Z',
      'value', jsonb_build_object('name', 'must not survive')
    )
  ) #>> '{rejection,field}',
  'purge_envelope',
  'purge rejects entity contents'
);

select is(
  public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000005',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'purge', 1,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 2, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:03:00Z',
      'deleted_at_utc', '2026-08-04T12:01:00Z',
      'purged_at_utc', '2026-08-04T12:03:00Z', 'value', '{}'::jsonb
    )
  ) #>> '{rejection,code}',
  'stale_revision',
  'purge rejects a stale tombstone revision'
);

select ok(
  (public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000006',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'purge', 2,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 3, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:03:00Z',
      'deleted_at_utc', '2026-08-04T12:01:00Z',
      'purged_at_utc', '2026-08-04T12:03:00Z', 'value', '{}'::jsonb
    )
  ) ->> 'accepted')::boolean,
  'accepts owner-authorized permanent purge of a tombstone'
);

reset role;
select is(
  (select count(*) from clinical_calendar_sync.records
   where entity_id = '82400000-0000-4000-8000-000000000001'),
  0::bigint,
  'accepted purge physically removes entity and tombstone contents'
);
select is(
  (select revision from clinical_calendar_sync.purge_markers
   where entity_id = '82400000-0000-4000-8000-000000000001'),
  3::bigint,
  'minimal convergence marker retains the monotonic revision'
);
select is(
  (select cursor from clinical_calendar_sync.purge_markers
   where entity_id = '82400000-0000-4000-8000-000000000001'),
  3::bigint,
  'purge consumes the next per-Student change-feed cursor'
);
select is(
  (select operation_type from clinical_calendar_sync.change_feed
   where student_id = '82000000-0000-4000-8000-000000000001' and cursor = 3),
  'purge',
  'change feed exposes the physical-removal operation'
);
select is(
  (select payload -> 'value' from clinical_calendar_sync.change_feed
   where student_id = '82000000-0000-4000-8000-000000000001' and cursor = 3),
  '{}'::jsonb,
  'purge feed payload contains no entity value'
);
select ok(
  (select payload::text not like '%Private template contents%'
   from clinical_calendar_sync.change_feed
   where student_id = '82000000-0000-4000-8000-000000000001' and cursor = 3),
  'purge feed does not retain deleted private contents'
);
select is(
  (select count(*) from clinical_calendar_sync.change_feed
   where student_id = '82000000-0000-4000-8000-000000000001'
     and entity_type = 'schedule_template'
     and entity_id = '82400000-0000-4000-8000-000000000001'),
  1::bigint,
  'purge removes every earlier payload-bearing feed row for the entity'
);
select ok(
  not exists (
    select 1 from clinical_calendar_sync.change_feed
    where student_id = '82000000-0000-4000-8000-000000000001'
      and payload::text like '%Private template contents%'
  ),
  'no retained feed payload contains the permanently purged value'
);
select ok(
  (select count(*) = 1
     and bool_and(request_payload::text not like '%Private template contents%'
       and request_payload::text not like '%must not survive%')
   from clinical_calendar_sync.operation_receipts
   where student_id = '82000000-0000-4000-8000-000000000001'
     and entity_type = 'schedule_template'
     and entity_id = '82400000-0000-4000-8000-000000000001'),
  'purge retains only its content-free idempotency receipt'
);

set local role authenticated;
set local request.jwt.claim.sub = '82000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '82100000-0000-4000-8000-000000000001';
select is(
  (public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000006',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'purge', 2,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 3, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:03:00Z',
      'deleted_at_utc', '2026-08-04T12:01:00Z',
      'purged_at_utc', '2026-08-04T12:03:00Z', 'value', '{}'::jsonb
    )
  ) ->> 'cursor')::bigint,
  3::bigint,
  'identical idempotency retry returns the original cursor'
);
select is(
  (public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000007',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'purge', 2,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 3, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:03:00Z',
      'deleted_at_utc', '2026-08-04T12:01:00Z',
      'purged_at_utc', '2026-08-04T12:03:00Z', 'value', '{}'::jsonb
    )
  ) ->> 'cursor')::bigint,
  3::bigint,
  'different-key semantic retry reuses the marker cursor'
);
select is(
  public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000008',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'upsert', 3,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 4, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:04:00Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'stale resurrection')
    )
  ) #>> '{rejection,code}',
  'permanently_purged',
  'later upsert cannot resurrect a permanently purged identity'
);
select is(
  public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000009',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'upsert', 99,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000001',
      'revision', 100, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:05:00Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'future resurrection')
    )
  ) #>> '{rejection,code}',
  'permanently_purged',
  'inventing a higher revision cannot reuse a permanently purged identity'
);
reset role;
select ok(
  not exists (
    select 1 from clinical_calendar_sync.operation_receipts
    where student_id = '82000000-0000-4000-8000-000000000001'
      and entity_type = 'schedule_template'
      and entity_id = '82400000-0000-4000-8000-000000000001'
      and (request_payload::text like '%stale resurrection%'
        or request_payload::text like '%future resurrection%')
  ),
  'rejected post-purge operations do not recreate private receipt payloads'
);
set local role authenticated;
set local request.jwt.claim.sub = '82000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '82100000-0000-4000-8000-000000000003';
select ok(
  public.register_current_device(
    '82200000-0000-4000-8000-000000000003', 'Replacement iPhone', 'ios'
  ),
  'registers a newly connected owner device after permanent purge'
);
select results_eq(
  $$select operation_type from public.pull_changes_after(2, 100)$$,
  $$values ('purge'::text)$$,
  'a newly connected device receives the purge and cannot recreate Trash'
);

set local request.jwt.claim.sub = '82000000-0000-4000-8000-000000000002';
set local request.jwt.claim.session_id = '82100000-0000-4000-8000-000000000002';
select ok(
  public.register_current_device(
    '82200000-0000-4000-8000-000000000002', 'Android tablet', 'android'
  ),
  'registers another Student device'
);
select is(
  public.apply_sync_operation(
    '82300000-0000-4000-8000-000000000010',
    'schedule_template', '82400000-0000-4000-8000-000000000001',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'schedule_template',
      'entity_id', '82400000-0000-4000-8000-000000000001',
      'student_id', '82000000-0000-4000-8000-000000000002',
      'revision', 1, 'created_at_utc', '2026-08-04T12:00:00Z',
      'updated_at_utc', '2026-08-04T12:00:00Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'identity theft')
    )
  ) #>> '{rejection,code}',
  'ownership_violation',
  'another Student cannot reuse the globally purged identity'
);

reset role;
select ok(
  (select relrowsecurity and relforcerowsecurity from pg_class
   where oid = 'clinical_calendar_sync.purge_markers'::regclass),
  'purge markers force RLS'
);
select ok(
  not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.purge_markers', 'SELECT'
  ),
  'authenticated clients cannot read convergence markers directly'
);
select is(
  (select count(*) from clinical_calendar_sync.operation_receipts
   where result is null),
  0::bigint,
  'every persisted purge-related receipt has a durable result'
);

select * from finish();
rollback;
