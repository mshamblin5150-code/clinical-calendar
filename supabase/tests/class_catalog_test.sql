begin;

create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '71000000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'catalog@example.invalid', '',
  now(), now(), now(), '{}', '{}'
);

set local role authenticated;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '72000000-0000-4000-8000-000000000001';
select public.register_current_device(
  '73000000-0000-4000-8000-000000000001', 'Catalog test device', 'windows'
);

select ok(
  (public.apply_sync_operation(
    '74000000-0000-4000-8000-000000000001',
    'class_catalog_entry', '75000000-0000-4000-8000-000000000001',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'class_catalog_entry',
      'entity_id', '75000000-0000-4000-8000-000000000001',
      'student_id', '71000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-11T12:00:00.000Z',
      'updated_at_utc', '2026-08-11T12:00:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'NURS 702', 'archived', false)
    )
  ) ->> 'accepted')::boolean,
  'accepts a valid class catalog entry'
);

select ok(
  (public.apply_sync_operation(
    '74000000-0000-4000-8000-000000000002',
    'academic_assignment', '76000000-0000-4000-8000-000000000001',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'academic_assignment',
      'entity_id', '76000000-0000-4000-8000-000000000001',
      'student_id', '71000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-11T12:01:00.000Z',
      'updated_at_utc', '2026-08-11T12:01:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'title', 'Evidence review', 'course', 'NURS 702',
        'course_id', '75000000-0000-4000-8000-000000000001',
        'due_date', '2026-09-14', 'status', 'pending'
      )
    )
  ) ->> 'accepted')::boolean,
  'accepts an Academic Assignment linked to a stored class'
);

select is(
  public.apply_sync_operation(
    '74000000-0000-4000-8000-000000000003',
    'class_catalog_entry', '75000000-0000-4000-8000-000000000002',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'class_catalog_entry',
      'entity_id', '75000000-0000-4000-8000-000000000002',
      'student_id', '71000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-11T12:02:00.000Z',
      'updated_at_utc', '2026-08-11T12:02:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object('name', 'NURS 703', 'archived', 'no')
    )
  ) #>> '{rejection,code}',
  'invalid_payload',
  'rejects a non-boolean archived state'
);

select is(
  public.apply_sync_operation(
    '74000000-0000-4000-8000-000000000004',
    'academic_assignment', '76000000-0000-4000-8000-000000000002',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'academic_assignment',
      'entity_id', '76000000-0000-4000-8000-000000000002',
      'student_id', '71000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-08-11T12:03:00.000Z',
      'updated_at_utc', '2026-08-11T12:03:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'title', 'Evidence review', 'course', 'NURS 702',
        'course_id', 'not-a-uuid',
        'due_date', '2026-09-14', 'status', 'pending'
      )
    )
  ) #>> '{rejection,code}',
  'invalid_payload',
  'rejects an invalid catalog identity on an Academic Assignment'
);

select * from finish();
rollback;
