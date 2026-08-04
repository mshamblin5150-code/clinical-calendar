\set ON_ERROR_STOP on

drop table if exists public.permanent_purge_concurrency_results;
create table public.permanent_purge_concurrency_results (
  session_name text primary key,
  accepted boolean not null,
  result_code text
);
grant insert on public.permanent_purge_concurrency_results to authenticated;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '82500000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'purge-race@example.invalid', '',
  now(), now(), now(), '{}', '{}'
);
insert into clinical_calendar_sync.connected_devices (
  device_id, student_id, session_id, device_name, platform
) values (
  '82600000-0000-4000-8000-000000000001',
  '82500000-0000-4000-8000-000000000001',
  '82700000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
);
insert into clinical_calendar_sync.records (
  entity_type, entity_id, student_id, revision, created_at_utc,
  updated_at_utc, deleted_at_utc, payload
) values (
  'schedule_template', '82800000-0000-4000-8000-000000000001',
  '82500000-0000-4000-8000-000000000001', 2,
  '2026-08-04T12:00:00Z', '2026-08-04T12:01:00Z',
  '2026-08-04T12:01:00Z',
  jsonb_build_object(
    'schema_version', 1, 'entity_type', 'schedule_template',
    'entity_id', '82800000-0000-4000-8000-000000000001',
    'student_id', '82500000-0000-4000-8000-000000000001',
    'revision', 2, 'created_at_utc', '2026-08-04T12:00:00Z',
    'updated_at_utc', '2026-08-04T12:01:00Z',
    'deleted_at_utc', '2026-08-04T12:01:00Z',
    'value', jsonb_build_object('name', 'Sensitive old value')
  )
);
insert into clinical_calendar_sync.feed_heads (student_id, last_cursor)
values ('82500000-0000-4000-8000-000000000001', 2);
