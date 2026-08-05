-- Reminder snooze and resolution truth is Student-owned synchronization data.
-- Native delivery/dismissal history remains device-local.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

alter table clinical_calendar_sync.records
  drop constraint if exists records_entity_type_check;
alter table clinical_calendar_sync.records
  add constraint records_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state'
  ));

alter table clinical_calendar_sync.purge_markers
  drop constraint if exists purge_markers_entity_type_check;
alter table clinical_calendar_sync.purge_markers
  add constraint purge_markers_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state'
  ));

alter function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) rename to validate_snapshot_without_reminder_state;

create function clinical_calendar_sync.validate_snapshot(
  p_student_id uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_operation_type text,
  p_payload jsonb
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v jsonb := p_payload -> 'value';
  v_scheduled timestamptz;
  v_snoozed timestamptz;
  v_resolved timestamptz;
begin
  if p_entity_type <> 'reminder_state' then
    return clinical_calendar_sync.validate_snapshot_without_reminder_state(
      p_student_id, p_entity_type, p_entity_id, p_operation_type, p_payload
    );
  end if;
  if jsonb_typeof(v) <> 'object' then
    return jsonb_build_object('code', 'invalid_payload', 'field', 'value');
  end if;
  if p_operation_type = 'delete' then return null; end if;
  if not (v ?& array[
    'reminder_type', 'subject_entity_id', 'scheduled_for_utc',
    'snoozed_until_utc', 'resolved_at_utc', 'resolution_source',
    'occurrence_key'
  ]) then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'reminder_state'
    );
  end if;
  if v ->> 'reminder_type' not in (
    'upcomingWorkShift', 'upcomingClinicalSession', 'clinicalConfirmation',
    'protectedDayPlanning', 'initialSelfAssessment', 'interimReview',
    'finalSelfAssessment', 'finalPlacementReview', 'weeklySummary',
    'deadlineRisk', 'portableBackup', 'syncConflict', 'syncFailure',
    'unsynchronizedChanges'
  ) or length(trim(v ->> 'subject_entity_id')) not between 1 and 255
    or length(trim(v ->> 'occurrence_key')) not between 1 and 512 then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'reminder_state'
    );
  end if;
  v_scheduled := (v ->> 'scheduled_for_utc')::timestamptz;
  if v ->> 'snoozed_until_utc' is not null then
    v_snoozed := (v ->> 'snoozed_until_utc')::timestamptz;
  end if;
  if v ->> 'resolved_at_utc' is not null then
    v_resolved := (v ->> 'resolved_at_utc')::timestamptz;
  end if;
  if v_scheduled is null
    or ((v_resolved is null) <> (v ->> 'resolution_source' is null))
    or (v ->> 'resolution_source' is not null
      and length(trim(v ->> 'resolution_source')) not between 1 and 255) then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'reminder_state'
    );
  end if;
  return null;
exception when invalid_text_representation or datetime_field_overflow then
  return jsonb_build_object(
    'code', 'invalid_payload', 'field', 'reminder_state'
  );
end
$$;

alter function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) owner to clinical_calendar_sync_executor;
revoke all on function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) from public, anon, authenticated;
grant execute on function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) to clinical_calendar_sync_executor;

-- Keep the mature audited write/purge implementations intact while extending
-- their closed entity allowlists. Fail the migration if their exact definitions
-- no longer match the reviewed predecessor.
do $$
declare
  v_definition text;
  v_updated text;
  v_needle text := '''evaluation_plan'', ''settings''';
begin
  select pg_get_functiondef(
    'public.apply_sync_operation_for_active_device(uuid,text,uuid,text,bigint,jsonb)'::regprocedure
  ) into v_definition;
  v_updated := replace(
    v_definition,
    v_needle,
    '''evaluation_plan'', ''settings'', ''reminder_state'''
  );
  if v_updated = v_definition then
    raise exception 'sync operation entity allowlist did not match';
  end if;
  execute v_updated;
end
$$;

do $$
declare
  v_definition text;
  v_updated text;
  v_needle text := '''evaluation_plan'', ''settings''';
begin
  select pg_get_functiondef(
    'clinical_calendar_sync.apply_permanent_purge(uuid,uuid,text,uuid,bigint,jsonb)'::regprocedure
  ) into v_definition;
  v_updated := replace(
    v_definition,
    v_needle,
    '''evaluation_plan'', ''settings'', ''reminder_state'''
  );
  if v_updated = v_definition then
    raise exception 'permanent purge entity allowlist did not match';
  end if;
  execute v_updated;
end
$$;

revoke create on schema clinical_calendar_sync from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
revoke clinical_calendar_sync_executor from postgres;
