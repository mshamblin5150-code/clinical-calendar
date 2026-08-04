\set ON_ERROR_STOP on
delete from auth.users where id = '82500000-0000-4000-8000-000000000001';
drop table if exists public.permanent_purge_concurrency_results;
