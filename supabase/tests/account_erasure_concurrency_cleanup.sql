\set ON_ERROR_STOP on
delete from clinical_calendar_sync.account_recovery_snapshots
where student_id = '81600000-0000-4000-8000-000000000001';
delete from clinical_calendar_sync.account_erasure_jobs
where student_id = '81600000-0000-4000-8000-000000000001';
delete from auth.users where id = '81600000-0000-4000-8000-000000000001';
drop table if exists public.account_erasure_concurrency_results;
