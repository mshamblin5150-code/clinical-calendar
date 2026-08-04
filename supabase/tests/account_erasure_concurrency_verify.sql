\set ON_ERROR_STOP on
do $$
begin
  if (select count(*) from public.account_erasure_concurrency_results) <> 2 then
    raise exception 'expected two purge results';
  end if;
  if (select count(*) from public.account_erasure_concurrency_results
      where result = 'purged') <> 1 then
    raise exception 'expected exactly one purged result';
  end if;
  if (select count(*) from public.account_erasure_concurrency_results
      where result = 'complete') <> 1 then
    raise exception 'expected exactly one idempotent complete result';
  end if;
  if exists (select 1 from auth.users
      where id = '81600000-0000-4000-8000-000000000001') then
    raise exception 'Auth identity survived concurrent purge';
  end if;
  if exists (select 1 from clinical_calendar_sync.records
      where student_id = '81600000-0000-4000-8000-000000000001') then
    raise exception 'active data survived concurrent purge';
  end if;
end
$$;

select * from public.account_erasure_concurrency_results order by session_name;
