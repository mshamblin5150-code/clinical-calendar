-- Academic Assignments are Student-owned course deliverables. They are
-- synchronized independently from Clinical Placement assignments.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

alter table clinical_calendar_sync.records
  drop constraint if exists records_entity_type_check;
alter table clinical_calendar_sync.records
  add constraint records_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state', 'student_profile',
    'academic_assignment'
  ));

alter table clinical_calendar_sync.purge_markers
  drop constraint if exists purge_markers_entity_type_check;
alter table clinical_calendar_sync.purge_markers
  add constraint purge_markers_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state', 'student_profile',
    'academic_assignment'
  ));

alter function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) rename to validate_snapshot_without_academic_assignment;

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
  v_due_date date;
begin
  if p_entity_type <> 'academic_assignment' then
    return clinical_calendar_sync.validate_snapshot_without_academic_assignment(
      p_student_id, p_entity_type, p_entity_id, p_operation_type, p_payload
    );
  end if;
  if jsonb_typeof(v) <> 'object' then
    return jsonb_build_object('code', 'invalid_payload', 'field', 'value');
  end if;
  if p_operation_type = 'delete' then return null; end if;
  if not (v ?& array['title', 'course', 'due_date', 'status']) then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'academic_assignment'
    );
  end if;
  if jsonb_typeof(v -> 'title') <> 'string'
    or jsonb_typeof(v -> 'course') <> 'string'
    or jsonb_typeof(v -> 'due_date') <> 'string'
    or jsonb_typeof(v -> 'status') <> 'string' then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'academic_assignment'
    );
  end if;
  if length(trim(v ->> 'title')) not between 1 and 200
    or length(trim(v ->> 'course')) not between 1 and 120
    or (v ->> 'title') ~ '[[:cntrl:]]'
    or (v ->> 'course') ~ '[[:cntrl:]]'
    or v ->> 'status' not in ('pending', 'completed') then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'academic_assignment'
    );
  end if;
  v_due_date := (v ->> 'due_date')::date;
  if to_char(v_due_date, 'YYYY-MM-DD') <> v ->> 'due_date' then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'academic_assignment'
    );
  end if;
  return null;
exception when invalid_text_representation or datetime_field_overflow then
  return jsonb_build_object(
    'code', 'invalid_payload', 'field', 'academic_assignment'
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

do $$
declare
  v_definition text;
  v_updated text;
  v_needle text := '''reminder_state'', ''student_profile''';
begin
  select pg_get_functiondef(
    'public.apply_sync_operation_for_active_device(uuid,text,uuid,text,bigint,jsonb)'::regprocedure
  ) into v_definition;
  v_updated := replace(
    v_definition,
    v_needle,
    '''reminder_state'', ''student_profile'', ''academic_assignment'''
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
  v_needle text := '''reminder_state'', ''student_profile''';
begin
  select pg_get_functiondef(
    'clinical_calendar_sync.apply_permanent_purge(uuid,uuid,text,uuid,bigint,jsonb)'::regprocedure
  ) into v_definition;
  v_updated := replace(
    v_definition,
    v_needle,
    '''reminder_state'', ''student_profile'', ''academic_assignment'''
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
