begin;

create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '81000000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'feed-model@example.invalid', '',
  now(), now(), now(), '{}', '{}'
);

set local role authenticated;
set local request.jwt.claim.sub = '81000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '82000000-0000-4000-8000-000000000001';
select public.register_current_device(
  '83000000-0000-4000-8000-000000000001', 'Feed model test device', 'windows'
);

select ok(
  (public.apply_sync_operation(
    47,
    '84000000-0000-4000-8000-000000000001',
    'work_schedule_feed', '85000000-0000-4000-8000-000000000001',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_schedule_feed',
      'entity_id', '85000000-0000-4000-8000-000000000001',
      'student_id', '81000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:00:00.000Z',
      'updated_at_utc', '2026-09-27T12:00:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'name', 'Emergency Department',
        'feed_url', 'webcal://calendar.example/private-token.ics',
        'skip_words_json', '["meeting","education"]',
        'last_checked_at_utc', '2026-09-27T12:00:00.000Z',
        'last_successful_update_at_utc', '2026-09-27T12:00:00.000Z',
        'not_imported_json', '[]', 'held_reason', null
      )
    )
  ) ->> 'accepted')::boolean,
  'accepts a synchronized Work Schedule Feed'
);

select ok(
  (public.apply_sync_operation(
    47,
    '84000000-0000-4000-8000-000000000002',
    'work_shift', '86000000-0000-4000-8000-000000000001',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_shift',
      'entity_id', '86000000-0000-4000-8000-000000000001',
      'student_id', '81000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:01:00.000Z',
      'updated_at_utc', '2026-09-27T12:01:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'commitment_type', 'work_shift', 'lifecycle_state', 'scheduled',
        'placement_id', null, 'preceptor_id', null,
        'work_schedule_feed_id', '85000000-0000-4000-8000-000000000001',
        'work_schedule_feed_name', 'Emergency Department',
        'source_event_uid', 'shift-2026-09-28@example.invalid',
        'planned_start_date', '2026-09-28', 'planned_end_date', '2026-09-28',
        'planned_start_minutes', 420, 'planned_end_minutes', 1140,
        'time_zone', 'America/New_York',
        'planned_start_offset_minutes', -240,
        'planned_end_offset_minutes', -240,
        'planned_start_utc', '2026-09-28T11:00:00.000Z',
        'planned_end_utc', '2026-09-28T23:00:00.000Z'
      )
    )
  ) ->> 'accepted')::boolean,
  'accepts an imported read-only Work Shift linked to its feed'
);

select is(
  public.apply_sync_operation(
    47,
    '84000000-0000-4000-8000-000000000003',
    'work_schedule_feed', '85000000-0000-4000-8000-000000000002',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_schedule_feed',
      'entity_id', '85000000-0000-4000-8000-000000000002',
      'student_id', '81000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:02:00.000Z',
      'updated_at_utc', '2026-09-27T12:02:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'name', 'Broken', 'feed_url', 'file:///tmp/private.ics',
        'skip_words_json', '[]',
        'last_checked_at_utc', '2026-09-27T12:02:00.000Z',
        'last_successful_update_at_utc', '2026-09-27T12:02:00.000Z',
        'not_imported_json', '[]'
      )
    )
  ) #>> '{rejection,code}',
  'invalid_payload',
  'rejects a non-web calendar credential URL'
);

select is(
  public.apply_sync_operation(
    47,
    '84000000-0000-4000-8000-000000000005',
    'work_schedule_feed', '85000000-0000-4000-8000-000000000003',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_schedule_feed',
      'entity_id', '85000000-0000-4000-8000-000000000003',
      'student_id', '81000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:02:00.000Z',
      'updated_at_utc', '2026-09-27T12:02:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'name', null, 'feed_url', 'https://example.invalid/feed.ics',
        'skip_words_json', '[]',
        'last_checked_at_utc', '2026-09-27T12:02:00.000Z',
        'last_successful_update_at_utc', '2026-09-27T12:02:00.000Z',
        'not_imported_json', '[]'
      )
    )
  ) #>> '{rejection,code}',
  'invalid_payload',
  'rejects null required feed fields'
);

select is(
  public.apply_sync_operation(
    47,
    '84000000-0000-4000-8000-000000000004',
    'work_shift', '86000000-0000-4000-8000-000000000002',
    'upsert', 0,
    jsonb_build_object(
      'schema_version', 1, 'entity_type', 'work_shift',
      'entity_id', '86000000-0000-4000-8000-000000000002',
      'student_id', '81000000-0000-4000-8000-000000000001',
      'revision', 1, 'created_at_utc', '2026-09-27T12:03:00.000Z',
      'updated_at_utc', '2026-09-27T12:03:00.000Z', 'deleted_at_utc', null,
      'value', jsonb_build_object(
        'commitment_type', 'work_shift', 'lifecycle_state', 'scheduled',
        'placement_id', null, 'preceptor_id', null,
        'work_schedule_feed_id', '85000000-0000-4000-8000-000000000099',
        'work_schedule_feed_name', 'Missing feed',
        'source_event_uid', 'missing@example.invalid',
        'planned_start_date', '2026-09-29', 'planned_end_date', '2026-09-29',
        'planned_start_minutes', 420, 'planned_end_minutes', 1140,
        'time_zone', 'America/New_York',
        'planned_start_offset_minutes', -240,
        'planned_end_offset_minutes', -240,
        'planned_start_utc', '2026-09-29T11:00:00.000Z',
        'planned_end_utc', '2026-09-29T23:00:00.000Z'
      )
    )
  ) #>> '{rejection,relationship}',
  'work_schedule_feed',
  'rejects an imported Work Shift whose feed is absent'
);

select * from finish();
rollback;
