-- Student Profile is account-owned synchronized data. The authenticated email
-- is supplied by the identity session; clients collect only the missing name.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

alter table clinical_calendar_sync.records
  drop constraint if exists records_entity_type_check;
alter table clinical_calendar_sync.records
  add constraint records_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state', 'student_profile'
  ));

alter table clinical_calendar_sync.purge_markers
  drop constraint if exists purge_markers_entity_type_check;
alter table clinical_calendar_sync.purge_markers
  add constraint purge_markers_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state', 'student_profile'
  ));

alter function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) rename to validate_snapshot_without_student_profile;

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
  v_display_name text;
  v_program text;
  v_account_identity text;
  v_avatar_base64 text;
begin
  if p_entity_type <> 'student_profile' then
    return clinical_calendar_sync.validate_snapshot_without_student_profile(
      p_student_id, p_entity_type, p_entity_id, p_operation_type, p_payload
    );
  end if;
  if p_entity_id <> p_student_id then
    return jsonb_build_object(
      'code', 'ownership_mismatch', 'field', 'student_profile_id'
    );
  end if;
  if jsonb_typeof(v) <> 'object' then
    return jsonb_build_object('code', 'invalid_payload', 'field', 'value');
  end if;
  if p_operation_type = 'delete' then return null; end if;
  if not (v ?& array[
    'display_name', 'program', 'account_identity', 'avatar_base64'
  ]) then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'student_profile'
    );
  end if;
  v_display_name := v ->> 'display_name';
  v_program := v ->> 'program';
  v_account_identity := v ->> 'account_identity';
  v_avatar_base64 := v ->> 'avatar_base64';
  if length(trim(v_display_name)) not between 1 and 160
    or (v_program is not null
      and length(trim(v_program)) not between 1 and 200)
    or (v_account_identity is not null and (
      length(trim(v_account_identity)) not between 3 and 320
      or v_account_identity !~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'
    ))
    or (v_avatar_base64 is not null and (
      length(v_avatar_base64) not between 1 and 6990508
      or v_avatar_base64 !~ '^[A-Za-z0-9+/]*={0,2}$'
    )) then
    return jsonb_build_object(
      'code', 'invalid_payload', 'field', 'student_profile'
    );
  end if;
  return null;
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

-- Extend the reviewed write/purge allowlists without duplicating their mature
-- security-definer implementations. Exact matching fails closed on drift.
do $$
declare
  v_definition text;
  v_updated text;
  v_needle text := '''evaluation_plan'', ''settings'', ''reminder_state''';
begin
  select pg_get_functiondef(
    'public.apply_sync_operation_for_active_device(uuid,text,uuid,text,bigint,jsonb)'::regprocedure
  ) into v_definition;
  v_updated := replace(
    v_definition,
    v_needle,
    '''evaluation_plan'', ''settings'', ''reminder_state'', ''student_profile'''
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
  v_needle text := '''evaluation_plan'', ''settings'', ''reminder_state''';
begin
  select pg_get_functiondef(
    'clinical_calendar_sync.apply_permanent_purge(uuid,uuid,text,uuid,bigint,jsonb)'::regprocedure
  ) into v_definition;
  v_updated := replace(
    v_definition,
    v_needle,
    '''evaluation_plan'', ''settings'', ''reminder_state'', ''student_profile'''
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
