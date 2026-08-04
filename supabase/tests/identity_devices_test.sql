begin;

create extension if not exists pgtap with schema extensions;
select plan(25);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000',
   '11000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'identity-a@example.invalid', '', now(), now(), now(), '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '11000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'identity-b@example.invalid', '', now(), now(), now(), '{}', '{}');

set local role authenticated;
set local request.jwt.claim.sub = '11000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000001';

select ok(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  'registers the current Auth session as a connected device'
);

select results_eq(
  $$ select device_name, platform, is_current, is_revoked
     from public.list_connected_devices() $$,
  $$ values ('Windows laptop'::text, 'windows'::text, true, false) $$,
  'lists only the signed-in Student device with truthful state'
);

select ok(public.mark_current_device_synchronized(), 'records a successful synchronization');

select ok(
  (select last_synchronized_at_utc is not null from public.list_connected_devices()),
  'exposes the last synchronization time'
);

set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000004';
select ok(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  'the same Student installation safely rebinds after reauthentication'
);
select is(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000099', 'Mismatched device', 'windows'
  ),
  false,
  'one Auth session cannot bind a second installation identifier'
);
set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000001';
select ok(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000001', 'Windows laptop', 'windows'
  ),
  'the persisted installation can bind back to another new session'
);

set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000002';
select ok(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000002', 'Android tablet', 'android'
  ),
  'registers another device session'
);

select is(
  public.revoke_connected_device('13000000-0000-4000-8000-000000000002'),
  'current_device',
  'requires local sign-out for the current device'
);

set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000001';
select is(
  public.revoke_connected_device('13000000-0000-4000-8000-000000000002'),
  'revoked',
  'another device can be revoked'
);
select is(
  public.revoke_connected_device('13000000-0000-4000-8000-000000000002'),
  'revoked',
  'revoking an already-revoked device is idempotent'
);

set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000002';
select is(
  public.apply_sync_operation(
    '14000000-0000-4000-8000-000000000001',
    'settings', '11000000-0000-4000-8000-000000000001', 'upsert', 0,
    jsonb_build_object('student_id', '11000000-0000-4000-8000-000000000001')
  ) #>> '{rejection,code}',
  'revoked_device',
  'revoked devices cannot push even with an unexpired JWT'
);

select throws_ok(
  $$ select * from public.pull_changes_after(0, 100) $$,
  'PT403',
  'revoked_device',
  'revoked devices cannot pull even with an unexpired JWT'
);

select is(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000099', 'Spoofed tablet', 'android'
  ),
  false,
  'a revoked session cannot re-register under another device identifier'
);
select is(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000002', 'Revoked tablet', 'android'
  ),
  false,
  'a revoked session cannot reactivate the same installation identifier'
);

select is(
  public.revoke_connected_device('13000000-0000-4000-8000-000000000001'),
  'revoked_device',
  'a revoked session cannot revoke another connected device'
);

set local request.jwt.claim.sub = '11000000-0000-4000-8000-000000000002';
set local request.jwt.claim.session_id = '12000000-0000-4000-8000-000000000003';
select ok(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000003', 'iPhone', 'ios'
  ),
  'another Student can register a device'
);

select results_eq(
  $$ select device_name from public.list_connected_devices() $$,
  $$ values ('iPhone'::text) $$,
  'RLS prevents cross-Student connected-device disclosure'
);

select ok(
  (select relrowsecurity and relforcerowsecurity
   from pg_class
   where oid = 'clinical_calendar_sync.connected_devices'::regclass),
  'connected devices force RLS'
);

select ok(
  not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.connected_devices', 'UPDATE'
  ),
  'authenticated clients cannot bypass device RPCs with direct writes'
);

select ok(
  not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.connected_devices', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.records', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.change_feed', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'clinical_calendar_sync.operation_receipts', 'SELECT'
  ),
  'authenticated clients cannot directly read private identity or sync tables'
);

select is(
  public.register_current_device(
    '13000000-0000-4000-8000-000000000001', 'Cross-Student spoof', 'ios'
  ),
  false,
  'another Student cannot reuse an installation identifier'
);

select ok(
  public.deactivate_current_device(),
  'device-local sign-out deactivates only the current server binding'
);
select ok(
  public.deactivate_current_device(),
  'device-local sign-out deactivation is safe to retry'
);
select is(
  public.mark_current_device_synchronized(),
  false,
  'a locally signed-out device cannot report later synchronization'
);

select * from finish();
rollback;
