\set ON_ERROR_STOP on
do $$
begin
  if not exists (
    select 1 from public.permanent_purge_concurrency_results
    where session_name = 'A' and accepted and result_code is null
  ) then
    raise exception 'permanent purge did not win';
  end if;
  if not exists (
    select 1 from public.permanent_purge_concurrency_results
    where session_name = 'B' and not accepted
      and result_code = 'permanently_purged'
  ) then
    raise exception 'concurrent stale upsert was not rejected by marker';
  end if;
  if exists (
    select 1 from clinical_calendar_sync.records
    where entity_id = '82800000-0000-4000-8000-000000000001'
  ) then
    raise exception 'concurrent operation resurrected purged contents';
  end if;
  if (select count(*) from clinical_calendar_sync.purge_markers
      where entity_id = '82800000-0000-4000-8000-000000000001') <> 1 then
    raise exception 'expected one minimal convergence marker';
  end if;
  if exists (
    select 1 from clinical_calendar_sync.operation_receipts
    where entity_id = '82800000-0000-4000-8000-000000000001'
      and request_payload::text like '%Concurrent resurrection%'
  ) then
    raise exception 'concurrent rejected payload survived in receipts';
  end if;
end
$$;

select * from public.permanent_purge_concurrency_results order by session_name;
