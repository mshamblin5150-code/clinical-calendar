\set ON_ERROR_STOP on
select pg_sleep(0.25);
insert into public.account_erasure_concurrency_results (session_name, result)
select 'B', clinical_calendar_sync.purge_due_account_erasure(
  '81600000-0000-4000-8000-000000000001', '2026-08-01T00:00:01Z'
);
