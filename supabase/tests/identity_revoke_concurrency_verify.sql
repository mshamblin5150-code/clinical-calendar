\set ON_ERROR_STOP on
do $$
begin
  if not exists (
    select 1 from clinical_calendar_sync.connected_devices
    where device_id = '73000000-0000-4000-8000-000000000002'
      and revoked_at_utc is not null
  ) then
    raise exception 'the target device was not revoked';
  end if;
  if (select revision from clinical_calendar_sync.records
      where student_id = '71000000-0000-4000-8000-000000000001'
        and entity_id = '71000000-0000-4000-8000-000000000001') <> 1 then
    raise exception 'a synchronization write committed after revocation';
  end if;
end
$$;
