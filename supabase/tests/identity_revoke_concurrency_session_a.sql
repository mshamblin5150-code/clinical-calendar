\set ON_ERROR_STOP on
begin;
set local role authenticated;
set local request.jwt.claim.sub = '71000000-0000-4000-8000-000000000001';
set local request.jwt.claim.session_id = '72000000-0000-4000-8000-000000000001';
select public.revoke_connected_device(
  '73000000-0000-4000-8000-000000000002'
);
select pg_sleep(2);
commit;
