-- Synchronize Work Schedule Feeds and accept their read-only Imported Work
-- Shifts without applying the hand-entered conflict rejection rules.

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
    'academic_assignment', 'class_catalog_entry', 'work_schedule_feed'
  ));

alter table clinical_calendar_sync.purge_markers
  drop constraint if exists purge_markers_entity_type_check;
alter table clinical_calendar_sync.purge_markers
  add constraint purge_markers_entity_type_check check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings', 'reminder_state', 'student_profile',
    'academic_assignment', 'class_catalog_entry', 'work_schedule_feed'
  ));

alter function clinical_calendar_sync.validate_snapshot(
  uuid, text, uuid, text, jsonb
) rename to validate_snapshot_without_work_schedule_feed;

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
  v_feed_id uuid;
  v_start timestamptz;
  v_end timestamptz;
begin
  if p_operation_type = 'delete' then
    return clinical_calendar_sync.validate_snapshot_without_work_schedule_feed(
      p_student_id, p_entity_type, p_entity_id, p_operation_type, p_payload
    );
  end if;

  if p_entity_type = 'work_schedule_feed' then
    if jsonb_typeof(v) is distinct from 'object'
      or not (v ?& array[
        'name', 'feed_url', 'skip_words_json', 'last_checked_at_utc',
        'last_successful_update_at_utc', 'not_imported_json'
      ])
      or jsonb_typeof(v -> 'name') is distinct from 'string'
      or length(trim(v ->> 'name')) not between 1 and 128
      or jsonb_typeof(v -> 'feed_url') is distinct from 'string'
      or length(v ->> 'feed_url') not between 1 and 4096
      or (v ->> 'feed_url') !~ '^(https|webcal)://'
      or jsonb_typeof(v -> 'skip_words_json') is distinct from 'string'
      or jsonb_typeof((v ->> 'skip_words_json')::jsonb) <> 'array'
      or jsonb_typeof(v -> 'not_imported_json') is distinct from 'string'
      or jsonb_typeof((v ->> 'not_imported_json')::jsonb) <> 'array'
      or jsonb_typeof(v -> 'last_checked_at_utc') is distinct from 'string'
      or jsonb_typeof(v -> 'last_successful_update_at_utc')
         is distinct from 'string'
      or (v ->> 'last_successful_update_at_utc')::timestamptz >
         (v ->> 'last_checked_at_utc')::timestamptz
      or (v -> 'held_reason') is not null
         and jsonb_typeof(v -> 'held_reason') not in ('string', 'null') then
      return jsonb_build_object(
        'code', 'invalid_payload', 'field', 'work_schedule_feed'
      );
    end if;
    return null;
  end if;

  if p_entity_type = 'work_shift'
    and v ->> 'work_schedule_feed_id' is not null then
    if jsonb_typeof(v) is distinct from 'object'
      or not (v ?& array[
        'commitment_type', 'lifecycle_state', 'planned_start_date',
        'planned_end_date', 'planned_start_minutes', 'planned_end_minutes',
        'planned_start_utc', 'planned_end_utc', 'time_zone',
        'planned_start_offset_minutes', 'planned_end_offset_minutes',
        'work_schedule_feed_id', 'work_schedule_feed_name', 'source_event_uid'
      ])
      or jsonb_typeof(v -> 'commitment_type') is distinct from 'string'
      or jsonb_typeof(v -> 'lifecycle_state') is distinct from 'string'
      or jsonb_typeof(v -> 'work_schedule_feed_id') is distinct from 'string'
      or jsonb_typeof(v -> 'work_schedule_feed_name') is distinct from 'string'
      or jsonb_typeof(v -> 'source_event_uid') not in ('string', 'null')
      or jsonb_typeof(v -> 'planned_start_date') is distinct from 'string'
      or jsonb_typeof(v -> 'planned_end_date') is distinct from 'string'
      or jsonb_typeof(v -> 'planned_start_minutes') is distinct from 'number'
      or jsonb_typeof(v -> 'planned_end_minutes') is distinct from 'number'
      or jsonb_typeof(v -> 'planned_start_utc') is distinct from 'string'
      or jsonb_typeof(v -> 'planned_end_utc') is distinct from 'string'
      or jsonb_typeof(v -> 'time_zone') is distinct from 'string'
      or jsonb_typeof(v -> 'planned_start_offset_minutes')
         is distinct from 'number'
      or jsonb_typeof(v -> 'planned_end_offset_minutes')
         is distinct from 'number'
      or v ->> 'commitment_type' <> 'work_shift'
      or v ->> 'lifecycle_state' <> 'scheduled'
      or v ->> 'placement_id' is not null
      or v ->> 'preceptor_id' is not null
      or length(trim(v ->> 'work_schedule_feed_name')) not between 1 and 128
      or (v ->> 'source_event_uid') is not null and
         length(trim(v ->> 'source_event_uid')) not between 1 and 1024
      or (v ->> 'planned_start_minutes')::integer not between 0 and 1439
      or (v ->> 'planned_end_minutes')::integer not between 0 and 1439
      or (v ->> 'planned_start_offset_minutes')::integer not between -840 and 840
      or (v ->> 'planned_end_offset_minutes')::integer not between -840 and 840
      or length(trim(v ->> 'time_zone')) not between 1 and 255 then
      return jsonb_build_object(
        'code', 'invalid_payload', 'field', 'imported_work_shift'
      );
    end if;
    v_start := (v ->> 'planned_start_utc')::timestamptz;
    v_end := (v ->> 'planned_end_utc')::timestamptz;
    v_feed_id := (v ->> 'work_schedule_feed_id')::uuid;
    if v_end <= v_start or not exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id
        and r.entity_type = 'work_schedule_feed'
        and r.entity_id = v_feed_id
        and r.deleted_at_utc is null
    ) then
      return jsonb_build_object(
        'code', 'relationship_violation', 'relationship', 'work_schedule_feed'
      );
    end if;
    return null;
  end if;

  return clinical_calendar_sync.validate_snapshot_without_work_schedule_feed(
    p_student_id, p_entity_type, p_entity_id, p_operation_type, p_payload
  );
exception when invalid_text_representation or datetime_field_overflow
  or numeric_value_out_of_range then
  return jsonb_build_object(
    'code', 'invalid_payload', 'field', 'work_schedule_feed'
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
  v_needle text := '''class_catalog_entry''';
  v_target regprocedure;
begin
  foreach v_target in array array[
    'public.apply_sync_operation_for_active_device(uuid,text,uuid,text,bigint,jsonb)'::regprocedure,
    'clinical_calendar_sync.apply_permanent_purge(uuid,uuid,text,uuid,bigint,jsonb)'::regprocedure
  ] loop
    select pg_get_functiondef(v_target) into v_definition;
    v_updated := replace(
      v_definition,
      v_needle,
      '''class_catalog_entry'', ''work_schedule_feed'''
    );
    if v_updated = v_definition then
      raise exception 'entity allowlist did not match for %', v_target;
    end if;
    execute v_updated;
  end loop;
end
$$;

update clinical_calendar_sync.sync_configuration
set minimum_sync_build = 47,
    updated_at_utc = clock_timestamp()
where singleton;

revoke create on schema clinical_calendar_sync from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
revoke clinical_calendar_sync_executor from postgres;
