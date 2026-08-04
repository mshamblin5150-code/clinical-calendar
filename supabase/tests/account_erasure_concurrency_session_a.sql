\set ON_ERROR_STOP on
begin;
insert into public.account_erasure_concurrency_results (session_name, result)
select 'A', clinical_calendar_sync.purge_due_account_erasure(
  '81600000-0000-4000-8000-000000000001', '2026-08-01T00:00:00Z'
);
select pg_sleep(2);
commit;
