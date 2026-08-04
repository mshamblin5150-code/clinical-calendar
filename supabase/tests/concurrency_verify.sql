-- After the two sessions finish, this query must return one revision-2 record,
-- one accepted revision-2 receipt, and one stale_revision receipt.
select revision, payload -> 'value' ->> 'name' as winning_name
from clinical_calendar_sync.records
where entity_type = 'preceptor'
  and entity_id = '30000000-0000-4000-8000-000000000001';

select result ->> 'accepted' as accepted,
  result #>> '{rejection,code}' as rejection_code,
  count(*)
from clinical_calendar_sync.operation_receipts
where idempotency_key in (
  '21000000-0000-4000-8000-000000000001',
  '21000000-0000-4000-8000-000000000002'
)
group by 1, 2
order by 1, 2;

do $$
declare
  v_revision bigint;
  v_receipt_count integer;
  v_accepted_count integer;
  v_stale_count integer;
begin
  select revision into v_revision
  from clinical_calendar_sync.records
  where entity_type = 'preceptor'
    and entity_id = '30000000-0000-4000-8000-000000000001';

  select count(*),
    count(*) filter (where (result ->> 'accepted')::boolean is true),
    count(*) filter (where result #>> '{rejection,code}' = 'stale_revision')
  into v_receipt_count, v_accepted_count, v_stale_count
  from clinical_calendar_sync.operation_receipts
  where idempotency_key in (
    '21000000-0000-4000-8000-000000000001',
    '21000000-0000-4000-8000-000000000002'
  );

  if v_revision is distinct from 2
    or v_receipt_count <> 2
    or v_accepted_count <> 1
    or v_stale_count <> 1 then
    raise exception 'concurrency contract failed: revision=%, receipts=%, accepted=%, stale=%',
      v_revision, v_receipt_count, v_accepted_count, v_stale_count;
  end if;
end
$$;
