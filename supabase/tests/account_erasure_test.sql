begin;

create extension if not exists pgtap with schema extensions;
select plan(36);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000',
   '81000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'erasure-a@example.invalid', '', now(), now(), now(), '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '81000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'erasure-b@example.invalid', '', now(), now(), now(), '{}', '{}');

insert into auth.sessions (id, user_id, created_at, updated_at, aal) values
  ('81100000-0000-4000-8000-000000000001',
   '81000000-0000-4000-8000-000000000001',
   clock_timestamp() - interval '10 minutes', clock_timestamp(), 'aal1'),
  ('81100000-0000-4000-8000-000000000002',
   '81000000-0000-4000-8000-000000000001',
   clock_timestamp(), clock_timestamp(), 'aal1'),
  ('81100000-0000-4000-8000-000000000003',
   '81000000-0000-4000-8000-000000000001',
   clock_timestamp(), clock_timestamp(), 'aal1'),
  ('81100000-0000-4000-8000-000000000004',
   '81000000-0000-4000-8000-000000000001',
   clock_timestamp(), clock_timestamp(), 'aal1');

set local role authenticated;
select set_config('request.jwt.claim.sub', '81000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.session_id', '81100000-0000-4000-8000-000000000001', true);

select ok(
  public.register_current_device(
    '81200000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  'registers a device before account erasure'
);
select is(
  public.request_account_erasure('skipped') ->> 'status',
  'reauthentication_required',
  'account erasure rejects a stale authentication proof'
);
select is(
  public.request_account_erasure('cancelled') ->> 'status',
  'backup_cancelled',
  'cancelling the optional backup seam does not schedule erasure'
);

reset role;
select is(
  (select count(*) from clinical_calendar_sync.account_erasure_jobs),
  0::bigint,
  'backup cancellation creates no erasure job'
);
set local role authenticated;
select set_config('request.jwt.claim.sub', '81000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.session_id', '81100000-0000-4000-8000-000000000002', true);
select public.register_current_device(
  '81200000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
);

select is(
  public.request_account_erasure('invalid') ->> 'status',
  'invalid_backup_choice',
  'only completed, skipped, or cancelled backup outcomes are accepted'
);
select is(
  public.request_account_erasure('skipped') ->> 'status',
  'pending',
  'fresh reauthentication schedules account erasure'
);
select is(
  public.request_account_erasure('skipped') ->> 'status',
  'pending',
  'retrying a lost request response returns the original pending job'
);
select is(
  public.register_current_device(
    '81200000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  false,
  'the requesting session cannot masquerade as a new sign-in to cancel'
);

reset role;
select is(
  (select status from clinical_calendar_sync.account_erasure_jobs
   where student_id = '81000000-0000-4000-8000-000000000001'),
  'pending',
  'the erasure job remains pending'
);
select is(
  (select purge_after_utc - requested_at_utc
   from clinical_calendar_sync.account_erasure_jobs
   where student_id = '81000000-0000-4000-8000-000000000001'),
  interval '30 days',
  'the recovery grace period is exactly 30 days'
);
select ok(
  not exists (
    select 1 from clinical_calendar_sync.connected_devices
    where student_id = '81000000-0000-4000-8000-000000000001'
      and revoked_at_utc is null
  ),
  'requesting account erasure revokes every synchronization device'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '81000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.session_id', '81100000-0000-4000-8000-000000000003', true);
select ok(
  public.register_current_device(
    '81200000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  'a genuinely new sign-in cancels deletion during the grace period'
);

reset role;
select is(
  (select status from clinical_calendar_sync.account_erasure_jobs
   where student_id = '81000000-0000-4000-8000-000000000001'),
  'cancelled',
  'new-sign-in cancellation is durable'
);
select ok(
  (select cancelled_at_utc is not null
   from clinical_calendar_sync.account_erasure_jobs
   where student_id = '81000000-0000-4000-8000-000000000001'),
  'cancellation records its time'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '81000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.session_id', '81100000-0000-4000-8000-000000000003', true);
select is(
  public.request_account_erasure('completed') ->> 'status',
  'pending',
  'a later request may record that portable backup completed'
);

reset role;
select is(
  (select backup_choice from clinical_calendar_sync.account_erasure_jobs
   where student_id = '81000000-0000-4000-8000-000000000001'),
  'completed',
  'the backup-first decision is retained'
);

-- Advance the job deterministically beyond its grace period and seed every
-- server-side account scope plus a detached encrypted recovery snapshot.
update clinical_calendar_sync.account_erasure_jobs
set requested_at_utc = current_timestamp - interval '31 days',
    purge_after_utc = current_timestamp - interval '1 day'
where student_id = '81000000-0000-4000-8000-000000000001';

insert into clinical_calendar_sync.records (
  entity_type, entity_id, student_id, revision, created_at_utc,
  updated_at_utc, deleted_at_utc, payload
) values (
  'settings', '81300000-0000-4000-8000-000000000001',
  '81000000-0000-4000-8000-000000000001', 1,
  current_timestamp - interval '2 days', current_timestamp - interval '1 day',
  current_timestamp - interval '1 day', '{}'::jsonb
);
insert into clinical_calendar_sync.feed_heads (student_id, last_cursor)
values ('81000000-0000-4000-8000-000000000001', 1);
insert into clinical_calendar_sync.change_feed (
  student_id, cursor, entity_type, entity_id, revision, operation_type, payload
) values (
  '81000000-0000-4000-8000-000000000001', 1, 'settings',
  '81300000-0000-4000-8000-000000000001', 1, 'delete', '{}'::jsonb
);
insert into clinical_calendar_sync.operation_receipts (
  student_id, idempotency_key, entity_type, entity_id, operation_type,
  base_revision, request_payload, result
) values (
  '81000000-0000-4000-8000-000000000001',
  '81400000-0000-4000-8000-000000000001', 'settings',
  '81300000-0000-4000-8000-000000000001', 'delete', 0, '{}'::jsonb, '{}'::jsonb
);
insert into clinical_calendar_sync.account_recovery_snapshots (
  snapshot_id, student_id, encryption_algorithm, key_reference, nonce,
  encrypted_payload, created_at_utc, expires_at_utc
) values (
  '81500000-0000-4000-8000-000000000001',
  '81000000-0000-4000-8000-000000000001', 'aes-256-gcm', 'vault:key:v1',
  decode(repeat('01', 12), 'hex'), decode(repeat('ab', 32), 'hex'),
  clock_timestamp() - interval '1 day', clock_timestamp() + interval '50 days'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '81000000-0000-4000-8000-000000000001', true);
select set_config('request.jwt.claim.session_id', '81100000-0000-4000-8000-000000000004', true);
select is(
  public.cancel_account_erasure(),
  'grace_expired',
  'explicit cancellation cannot extend an expired grace period'
);
select is(
  public.register_current_device(
    '81200000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  false,
  'sign-in registration cannot revive an account after grace expiry'
);

reset role;
select is(
  clinical_calendar_sync.purge_due_account_erasure(
    '81000000-0000-4000-8000-000000000001', clock_timestamp()
  ),
  'purged',
  'a trusted scheduler purges a due account'
);
select is(
  (select count(*) from auth.users
   where id = '81000000-0000-4000-8000-000000000001'),
  0::bigint,
  'purge deletes the Supabase Auth record'
);
select is(
  (select count(*) from clinical_calendar_sync.records
   where student_id = '81000000-0000-4000-8000-000000000001'),
  0::bigint,
  'purge deletes active records and Trash tombstones'
);
select is(
  (select count(*) from clinical_calendar_sync.change_feed
   where student_id = '81000000-0000-4000-8000-000000000001'),
  0::bigint,
  'purge deletes the durable synchronization feed'
);
select is(
  (select count(*) from clinical_calendar_sync.operation_receipts
   where student_id = '81000000-0000-4000-8000-000000000001'),
  0::bigint,
  'purge deletes idempotency receipts'
);
select is(
  (select count(*) from clinical_calendar_sync.connected_devices
   where student_id = '81000000-0000-4000-8000-000000000001'),
  0::bigint,
  'purge deletes every Connected Device registration'
);
select is(
  (select count(*) from clinical_calendar_sync.account_recovery_snapshots
   where student_id = '81000000-0000-4000-8000-000000000001'),
  1::bigint,
  'encrypted recovery snapshots survive the active-account cascade'
);
select ok(
  (select expires_at_utc <= completed_at_utc + interval '30 days'
   from clinical_calendar_sync.account_recovery_snapshots s
   join clinical_calendar_sync.account_erasure_jobs j using (student_id)
   where s.student_id = '81000000-0000-4000-8000-000000000001'),
  'residual encrypted snapshots expire within 30 additional days'
);
select is(
  clinical_calendar_sync.purge_due_account_erasure(
    '81000000-0000-4000-8000-000000000001', clock_timestamp() + interval '1 day'
  ),
  'complete',
  'retrying a completed purge is idempotent'
);
select is(
  clinical_calendar_sync.delete_expired_recovery_snapshots(
    clock_timestamp() + interval '31 days'
  ),
  1::bigint,
  'expiry cleanup deletes the residual encrypted snapshot'
);
select is(
  clinical_calendar_sync.delete_expired_recovery_snapshots(
    clock_timestamp() + interval '31 days'
  ),
  0::bigint,
  'snapshot expiry cleanup is safe to retry'
);

select ok(
  (select relrowsecurity and relforcerowsecurity from pg_class
   where oid = 'clinical_calendar_sync.account_erasure_jobs'::regclass),
  'account erasure jobs force RLS'
);
select ok(
  (select relrowsecurity and relforcerowsecurity from pg_class
   where oid = 'clinical_calendar_sync.account_recovery_snapshots'::regclass),
  'encrypted recovery snapshots force RLS'
);
select ok(
  not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.account_erasure_jobs', 'SELECT'
  ),
  'authenticated clients cannot read private erasure jobs directly'
);
select ok(
  not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.account_recovery_snapshots', 'SELECT'
  ),
  'authenticated clients cannot read encrypted snapshots directly'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'clinical_calendar_sync.purge_due_account_erasure(uuid,timestamptz)',
    'EXECUTE'
  ),
  'the app role cannot invoke privileged account purge'
);
select ok(
  not has_function_privilege(
    'anon', 'public.request_account_erasure(text)', 'EXECUTE'
  ),
  'anonymous clients cannot schedule account erasure'
);
select ok(
  has_function_privilege(
    'authenticated', 'public.request_account_erasure(text)', 'EXECUTE'
  ),
  'authenticated Students may invoke the guarded request RPC'
);

select * from finish();
rollback;
