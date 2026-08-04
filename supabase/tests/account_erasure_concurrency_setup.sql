\set ON_ERROR_STOP on

drop table if exists public.account_erasure_concurrency_results;
create table public.account_erasure_concurrency_results (
  session_name text primary key,
  result text not null
);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values (
  '00000000-0000-0000-0000-000000000000',
  '81600000-0000-4000-8000-000000000001',
  'authenticated', 'authenticated', 'erasure-race@example.invalid', '',
  now(), now(), now(), '{}', '{}'
);

insert into clinical_calendar_sync.account_erasure_jobs (
  student_id, status, backup_choice, requested_at_utc, purge_after_utc,
  requested_by_session_id
) values (
  '81600000-0000-4000-8000-000000000001', 'pending', 'skipped',
  '2026-07-01T00:00:00Z', '2026-07-31T00:00:00Z',
  '81700000-0000-4000-8000-000000000001'
);

insert into clinical_calendar_sync.records (
  entity_type, entity_id, student_id, revision, created_at_utc,
  updated_at_utc, payload
) values (
  'settings', '81800000-0000-4000-8000-000000000001',
  '81600000-0000-4000-8000-000000000001', 1,
  '2026-07-01T00:00:00Z', '2026-07-01T00:00:00Z', '{}'::jsonb
);
