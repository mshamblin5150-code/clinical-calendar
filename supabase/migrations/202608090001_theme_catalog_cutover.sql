-- Preserve every account that predates the atomic theme-catalog cutover on
-- Containment Drone 47-Alpha. Accounts created after this migration receive
-- the Graphite default from the application when their Settings are created.
do $$
declare
  v_student record;
  v_existing clinical_calendar_sync.records%rowtype;
  v_payload jsonb;
  v_cursor bigint;
  v_revision bigint;
  v_now timestamptz;
  v_emit boolean;
begin
  for v_student in
    select id, created_at
    from auth.users
    order by created_at, id
  loop
    v_emit := false;
    v_now := clock_timestamp();

    select * into v_existing
    from clinical_calendar_sync.records
    where entity_type = 'settings'
      and entity_id = v_student.id
    for update;

    if not found then
      v_revision := 1;
      v_payload := jsonb_build_object(
        'schema_version', 1,
        'entity_type', 'settings',
        'entity_id', v_student.id,
        'student_id', v_student.id,
        'revision', v_revision,
        'created_at_utc', v_student.created_at,
        'updated_at_utc', v_student.created_at,
        'deleted_at_utc', null,
        'value', jsonb_build_object(
          'week_start', 7,
          'time_display', 'military',
          'theme', 'variant-f',
          'enhanced_accessibility', false,
          'synchronization_mode', 'enabled',
          'notification_preferences_json', '{}',
          'active_placement_id', null
        )
      );

      insert into clinical_calendar_sync.records (
        entity_type, entity_id, student_id, revision,
        created_at_utc, updated_at_utc, deleted_at_utc, payload
      ) values (
        'settings', v_student.id, v_student.id, v_revision,
        v_student.created_at, v_student.created_at, null, v_payload
      )
      on conflict (entity_type, entity_id) do nothing;
      if found then
        v_emit := true;
      else
        select * into strict v_existing
        from clinical_calendar_sync.records
        where entity_type = 'settings'
          and entity_id = v_student.id
        for update;
      end if;
    end if;

    if not v_emit and v_existing.deleted_at_utc is null and (
      v_existing.payload -> 'value' ->> 'theme' = 'borg_tactical'
      or length(trim(coalesce(
        v_existing.payload -> 'value' ->> 'theme', ''
      ))) = 0
      or not (v_existing.payload -> 'value' ? 'enhanced_accessibility')
    ) then
      v_revision := v_existing.revision + 1;
      v_payload := v_existing.payload;
      if v_payload -> 'value' ->> 'theme' = 'borg_tactical'
          or length(trim(coalesce(v_payload -> 'value' ->> 'theme', ''))) = 0
      then
        v_payload := jsonb_set(
          v_payload,
          '{value,theme}',
          to_jsonb('variant-f'::text),
          true
        );
      end if;
      if not (v_payload -> 'value' ? 'enhanced_accessibility') then
        v_payload := jsonb_set(
          v_payload,
          '{value,enhanced_accessibility}',
          'false'::jsonb,
          true
        );
      end if;
      v_payload := jsonb_set(
        jsonb_set(
          v_payload,
          '{revision}',
          to_jsonb(v_revision),
          true
        ),
        '{updated_at_utc}',
        to_jsonb(v_now),
        true
      );

      update clinical_calendar_sync.records
      set revision = v_revision,
          updated_at_utc = v_now,
          payload = v_payload
      where entity_type = 'settings'
        and entity_id = v_student.id
        and revision = v_existing.revision;
      if not found then
        raise exception 'Concurrent settings revision changed during catalog cutover';
      end if;
      v_emit := true;
    end if;

    if v_emit then
      insert into clinical_calendar_sync.feed_heads (student_id, last_cursor)
      values (v_student.id, 0)
      on conflict (student_id) do nothing;

      update clinical_calendar_sync.feed_heads
      set last_cursor = last_cursor + 1
      where student_id = v_student.id
      returning last_cursor into v_cursor;

      insert into clinical_calendar_sync.change_feed (
        student_id, cursor, entity_type, entity_id, revision,
        operation_type, payload
      ) values (
        v_student.id, v_cursor, 'settings', v_student.id, v_revision,
        'upsert', v_payload
      );
    end if;
  end loop;
end
$$;
