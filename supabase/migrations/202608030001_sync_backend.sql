-- Clinical Calendar synchronization backend.
-- The public schema contains only the two RPC entry points. Durable state is
-- private and accessible to authenticated Students only through RLS.

create schema if not exists clinical_calendar_sync;
revoke all on schema clinical_calendar_sync from public, anon, authenticated;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'clinical_calendar_sync_executor') then
    create role clinical_calendar_sync_executor nologin noinherit nosuperuser
      nocreatedb nocreaterole noreplication;
  end if;
end
$$;

-- Supabase's local migration role is intentionally not a superuser. Temporary
-- membership permits ownership transfer to the narrower executor role and is
-- revoked immediately after the owned functions are created.
grant clinical_calendar_sync_executor to postgres;

grant usage on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant usage on schema clinical_calendar_sync to authenticated;
grant usage on schema public to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

create table clinical_calendar_sync.records (
  entity_type text not null check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings'
  )),
  entity_id uuid not null,
  student_id uuid not null references auth.users(id) on delete cascade,
  revision bigint not null check (revision > 0),
  created_at_utc timestamptz not null,
  updated_at_utc timestamptz not null check (updated_at_utc >= created_at_utc),
  deleted_at_utc timestamptz,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  primary key (entity_type, entity_id),
  unique (student_id, entity_type, entity_id),
  check (deleted_at_utc is null or
    (deleted_at_utc >= created_at_utc and deleted_at_utc <= updated_at_utc))
);

create index records_student_active_type_idx
  on clinical_calendar_sync.records (student_id, entity_type, entity_id)
  where deleted_at_utc is null;
create index records_student_updated_idx
  on clinical_calendar_sync.records (student_id, updated_at_utc, entity_id);
create index records_payload_placement_idx
  on clinical_calendar_sync.records
    (student_id, ((payload -> 'value' ->> 'placement_id')::uuid), entity_type)
  where deleted_at_utc is null
    and entity_type in ('clinical_session', 'historical_hours_entry');

create table clinical_calendar_sync.feed_heads (
  student_id uuid primary key references auth.users(id) on delete cascade,
  last_cursor bigint not null default 0 check (last_cursor >= 0)
);

create table clinical_calendar_sync.change_feed (
  student_id uuid not null references auth.users(id) on delete cascade,
  cursor bigint not null check (cursor > 0),
  entity_type text not null,
  entity_id uuid not null,
  revision bigint not null check (revision > 0),
  operation_type text not null check (operation_type in ('upsert', 'delete', 'resolve_conflict')),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  accepted_at_utc timestamptz not null default clock_timestamp(),
  primary key (student_id, cursor),
  foreign key (entity_type, entity_id)
    references clinical_calendar_sync.records(entity_type, entity_id)
);

create index change_feed_student_entity_idx
  on clinical_calendar_sync.change_feed
    (student_id, entity_type, entity_id, cursor desc);
create index change_feed_entity_fk_idx
  on clinical_calendar_sync.change_feed (entity_type, entity_id);

create table clinical_calendar_sync.operation_receipts (
  student_id uuid not null references auth.users(id) on delete cascade,
  idempotency_key uuid not null,
  entity_type text not null,
  entity_id uuid not null,
  operation_type text not null,
  base_revision bigint not null check (base_revision >= 0),
  request_payload jsonb not null,
  result jsonb,
  received_at_utc timestamptz not null default clock_timestamp(),
  primary key (student_id, idempotency_key),
  check (operation_type in ('upsert', 'delete', 'resolve_conflict')),
  check (jsonb_typeof(request_payload) = 'object'),
  check (result is null or jsonb_typeof(result) = 'object')
);

create index operation_receipts_student_received_idx
  on clinical_calendar_sync.operation_receipts
    (student_id, received_at_utc, idempotency_key);

alter table clinical_calendar_sync.records enable row level security;
alter table clinical_calendar_sync.records force row level security;
alter table clinical_calendar_sync.feed_heads enable row level security;
alter table clinical_calendar_sync.feed_heads force row level security;
alter table clinical_calendar_sync.change_feed enable row level security;
alter table clinical_calendar_sync.change_feed force row level security;
alter table clinical_calendar_sync.operation_receipts enable row level security;
alter table clinical_calendar_sync.operation_receipts force row level security;

create policy records_executor_owner on clinical_calendar_sync.records
  for all to clinical_calendar_sync_executor
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid))
  with check (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));
create policy records_student_read on clinical_calendar_sync.records
  for select to authenticated
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));

create policy feed_heads_executor_owner on clinical_calendar_sync.feed_heads
  for all to clinical_calendar_sync_executor
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid))
  with check (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));

create policy change_feed_executor_owner on clinical_calendar_sync.change_feed
  for all to clinical_calendar_sync_executor
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid))
  with check (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));
create policy change_feed_student_read on clinical_calendar_sync.change_feed
  for select to authenticated
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));

create policy receipts_executor_owner on clinical_calendar_sync.operation_receipts
  for all to clinical_calendar_sync_executor
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid))
  with check (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));
create policy receipts_student_read on clinical_calendar_sync.operation_receipts
  for select to authenticated
  using (student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid));

revoke all on all tables in schema clinical_calendar_sync from public, anon, authenticated;
grant select on clinical_calendar_sync.records,
  clinical_calendar_sync.change_feed,
  clinical_calendar_sync.operation_receipts to authenticated;
grant select, insert, update on clinical_calendar_sync.records,
  clinical_calendar_sync.feed_heads,
  clinical_calendar_sync.change_feed,
  clinical_calendar_sync.operation_receipts to clinical_calendar_sync_executor;

-- Returns null when the proposed snapshot respects the server-side mirror of
-- the hard ownership, relationship, and scheduling invariants. Otherwise it
-- returns a stable structured rejection object.
create or replace function clinical_calendar_sync.validate_snapshot(
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
  v_placement clinical_calendar_sync.records%rowtype;
  v_start timestamptz;
  v_end timestamptz;
  v_start_date date;
  v_end_date date;
  v_start_minutes integer;
  v_end_minutes integer;
  v_preceptor_id uuid;
begin
  if jsonb_typeof(v) <> 'object' then
    return jsonb_build_object('code', 'invalid_payload', 'field', 'value');
  end if;

  if p_operation_type = 'delete' then
    if p_entity_type = 'preceptor' and exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id and r.deleted_at_utc is null
        and ((r.entity_type = 'clinical_placement'
              and (r.payload -> 'value' -> 'attached_preceptor_ids') ? p_entity_id::text)
          or (r.entity_type in ('clinical_session', 'historical_hours_entry', 'schedule_template')
              and r.payload -> 'value' ->> 'preceptor_id' = p_entity_id::text))
    ) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'referenced_preceptor');
    elsif p_entity_type = 'clinical_placement' and exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id and r.deleted_at_utc is null
        and r.entity_type in ('clinical_session', 'historical_hours_entry')
        and r.payload -> 'value' ->> 'placement_id' = p_entity_id::text
    ) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'nonempty_clinical_placement');
    end if;
    return null;
  end if;

  if p_entity_type in ('work_shift', 'clinical_session') then
    if not (v ?& array['commitment_type', 'lifecycle_state',
      'planned_start_date', 'planned_end_date', 'planned_start_minutes',
      'planned_end_minutes', 'planned_start_utc', 'planned_end_utc',
      'time_zone', 'planned_start_offset_minutes',
      'planned_end_offset_minutes']) then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'commitment');
    end if;
    if (p_entity_type = 'work_shift' and v ->> 'commitment_type' <> 'work_shift')
      or (p_entity_type = 'clinical_session' and v ->> 'commitment_type' <> 'clinical_session') then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'commitment_type');
    end if;
    v_start := (v ->> 'planned_start_utc')::timestamptz;
    v_end := (v ->> 'planned_end_utc')::timestamptz;
    if v_end <= v_start
      or (v ->> 'planned_start_minutes')::integer not between 0 and 1439
      or (v ->> 'planned_end_minutes')::integer not between 0 and 1439
      or (v ->> 'planned_start_offset_minutes')::integer not between -840 and 840
      or (v ->> 'planned_end_offset_minutes')::integer not between -840 and 840
      or length(trim(v ->> 'time_zone')) not between 1 and 255 then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'planned_interval');
    end if;

    if p_entity_type = 'work_shift' and (
      v ->> 'lifecycle_state' <> 'scheduled'
      or v ->> 'placement_id' is not null
      or v ->> 'preceptor_id' is not null
    ) then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'work_shift');
    end if;

    if p_entity_type = 'clinical_session' then
      if not (v ?& array['placement_id', 'preceptor_id']) then
        return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_session_assignment');
      end if;
      select * into v_placement from clinical_calendar_sync.records
       where student_id = p_student_id and entity_type = 'clinical_placement'
         and entity_id = (v ->> 'placement_id')::uuid and deleted_at_utc is null;
      if not found then
        return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_placement');
      end if;
      if v ->> 'lifecycle_state' not in (
        'scheduled', 'awaiting_confirmation', 'completed', 'cancelled', 'missed'
      ) then
        return jsonb_build_object('code', 'invalid_payload', 'field', 'lifecycle_state');
      end if;
      if (v ->> 'lifecycle_state' = 'completed') <> (v ->> 'actual_start_utc' is not null)
        or ((v ->> 'actual_start_utc' is null) <> (v ->> 'actual_end_utc' is null)) then
        return jsonb_build_object('code', 'invalid_payload', 'field', 'actual_interval');
      end if;
      v_preceptor_id := (v ->> 'preceptor_id')::uuid;
      if not coalesce((v_placement.payload -> 'value' -> 'attached_preceptor_ids') ? v_preceptor_id::text, false) then
        return jsonb_build_object('code', 'relationship_violation', 'relationship', 'attached_preceptor');
      end if;
      if (v ->> 'planned_start_date')::date < (v_placement.payload -> 'value' ->> 'start_date')::date
        or (v ->> 'planned_end_date')::date > (v_placement.payload -> 'value' ->> 'completion_deadline')::date then
        return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_placement_window');
      end if;
    end if;

    if v ->> 'lifecycle_state' not in ('cancelled', 'missed') then
      if v ->> 'lifecycle_state' = 'completed' then
        v_start := (v ->> 'actual_start_utc')::timestamptz;
        v_end := (v ->> 'actual_end_utc')::timestamptz;
        v_start_date := (v ->> 'actual_start_date')::date;
        v_end_date := (v ->> 'actual_end_date')::date;
        v_start_minutes := (v ->> 'actual_start_minutes')::integer;
        v_end_minutes := (v ->> 'actual_end_minutes')::integer;
      else
        v_start_date := (v ->> 'planned_start_date')::date;
        v_end_date := (v ->> 'planned_end_date')::date;
        v_start_minutes := (v ->> 'planned_start_minutes')::integer;
        v_end_minutes := (v ->> 'planned_end_minutes')::integer;
      end if;

      if exists (
        select 1 from clinical_calendar_sync.records r
        where r.student_id = p_student_id and r.entity_id <> p_entity_id
          and r.entity_type in ('work_shift', 'clinical_session')
          and r.deleted_at_utc is null
          and r.payload -> 'value' ->> 'lifecycle_state' not in ('cancelled', 'missed')
          and tstzrange(
            case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed'
              then (r.payload -> 'value' ->> 'actual_start_utc')::timestamptz
              else (r.payload -> 'value' ->> 'planned_start_utc')::timestamptz end,
            case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed'
              then (r.payload -> 'value' ->> 'actual_end_utc')::timestamptz
              else (r.payload -> 'value' ->> 'planned_end_utc')::timestamptz end,
            '[)'
          ) && tstzrange(v_start, v_end, '[)')
      ) then
        return jsonb_build_object('code', 'schedule_conflict');
      end if;

      if exists (
        select 1 from clinical_calendar_sync.records r
        where r.student_id = p_student_id and r.entity_type = 'protected_day'
          and r.deleted_at_utc is null
          and ((r.payload -> 'value' ->> 'local_date')::date > v_start_date
            or ((r.payload -> 'value' ->> 'local_date')::date = v_start_date and v_start_minutes < 1440))
          and ((r.payload -> 'value' ->> 'local_date')::date < v_end_date
            or ((r.payload -> 'value' ->> 'local_date')::date = v_end_date and v_end_minutes > 0))
      ) then
        return jsonb_build_object('code', 'protected_day_violation');
      end if;
    end if;
  elsif p_entity_type = 'protected_day' then
    v_start_date := (v ->> 'local_date')::date;
    if v_start_date - (v ->> 'week_start_date')::date not between 0 and 6 then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'week_start_date');
    end if;
    if exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id and r.entity_type = 'protected_day'
        and r.entity_id <> p_entity_id and r.deleted_at_utc is null
        and r.payload -> 'value' ->> 'week_start_date' = v ->> 'week_start_date'
    ) then
      return jsonb_build_object('code', 'protected_day_violation', 'reason', 'multiple_in_week');
    end if;
    if exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id
        and r.entity_type in ('work_shift', 'clinical_session')
        and r.deleted_at_utc is null
        and r.payload -> 'value' ->> 'lifecycle_state' not in ('cancelled', 'missed')
        and ((r.payload -> 'value' ->> case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed' then 'actual_start_date' else 'planned_start_date' end)::date < v_start_date
          or ((r.payload -> 'value' ->> case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed' then 'actual_start_date' else 'planned_start_date' end)::date = v_start_date
            and (r.payload -> 'value' ->> case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed' then 'actual_start_minutes' else 'planned_start_minutes' end)::integer < 1440))
        and ((r.payload -> 'value' ->> case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed' then 'actual_end_date' else 'planned_end_date' end)::date > v_start_date
          or ((r.payload -> 'value' ->> case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed' then 'actual_end_date' else 'planned_end_date' end)::date = v_start_date
            and (r.payload -> 'value' ->> case when r.payload -> 'value' ->> 'lifecycle_state' = 'completed' then 'actual_end_minutes' else 'planned_end_minutes' end)::integer > 0))
    ) then
      return jsonb_build_object('code', 'protected_day_violation', 'reason', 'commitment_touches_day');
    end if;
  elsif p_entity_type = 'clinical_placement' then
    if jsonb_typeof(v -> 'attached_preceptor_ids') <> 'array'
      or not ((v -> 'attached_preceptor_ids') ? (v ->> 'primary_preceptor_id')) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'primary_preceptor');
    end if;
    if exists (
      select 1 from jsonb_array_elements_text(v -> 'attached_preceptor_ids') a(id)
      where not exists (
        select 1 from clinical_calendar_sync.records r
        where r.student_id = p_student_id and r.entity_type = 'preceptor'
          and r.entity_id = a.id::uuid and r.deleted_at_utc is null
      )
    ) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'attached_preceptor');
    end if;
    if (v ->> 'completion_deadline')::date < (v ->> 'start_date')::date then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'clinical_placement_window');
    end if;
    if (v ->> 'target_minutes')::integer <= 0
      or v ->> 'lifecycle_state' not in ('active', 'ready_to_complete', 'completed') then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'clinical_placement');
    end if;
    if exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id and r.entity_type = 'clinical_session'
        and r.deleted_at_utc is null and r.payload -> 'value' ->> 'placement_id' = p_entity_id::text
        and ((r.payload -> 'value' ->> 'planned_start_date')::date < (v ->> 'start_date')::date
          or (r.payload -> 'value' ->> 'planned_end_date')::date > (v ->> 'completion_deadline')::date)
    ) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_placement_window');
    end if;
  elsif p_entity_type in ('historical_hours_entry', 'schedule_template')
    and v ->> 'placement_id' is not null then
    select * into v_placement from clinical_calendar_sync.records
      where student_id = p_student_id and entity_type = 'clinical_placement'
        and entity_id = (v ->> 'placement_id')::uuid and deleted_at_utc is null;
    if not found then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_placement');
    end if;
    if v ->> 'preceptor_id' is not null
      and not coalesce((v_placement.payload -> 'value' -> 'attached_preceptor_ids') ? (v ->> 'preceptor_id'), false) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'attached_preceptor');
    end if;
    if p_entity_type = 'historical_hours_entry'
      and (v ->> 'completed_minutes')::integer <= 0 then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'completed_minutes');
    end if;
    if p_entity_type = 'schedule_template' and (
      v ->> 'commitment_type' <> 'clinical_session'
      or (v ->> 'start_minutes')::integer not between 0 and 1439
      or (v ->> 'end_minutes')::integer not between 0 and 1439
      or (v ->> 'start_minutes')::integer = (v ->> 'end_minutes')::integer
    ) then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'schedule_template');
    end if;
  elsif p_entity_type = 'schedule_template' then
    if v ->> 'commitment_type' <> 'work_shift'
      or v ->> 'placement_id' is not null or v ->> 'preceptor_id' is not null
      or (v ->> 'start_minutes')::integer not between 0 and 1439
      or (v ->> 'end_minutes')::integer not between 0 and 1439
      or (v ->> 'start_minutes')::integer = (v ->> 'end_minutes')::integer then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'schedule_template');
    end if;
  elsif p_entity_type = 'historical_hours_entry' then
    return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_placement');
  elsif p_entity_type = 'evaluation_plan' then
    if not exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id and r.entity_type = 'clinical_placement'
        and r.deleted_at_utc is null
        and r.payload -> 'value' ->> 'evaluation_plan_id' = p_entity_id::text
    ) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'clinical_placement_evaluation_plan');
    end if;
    if (v -> 'configuration' ->> 'interim_review_cadence_minutes')::integer <= 0
      or jsonb_typeof(v -> 'requirements') <> 'array' then
      return jsonb_build_object('code', 'invalid_payload', 'field', 'evaluation_plan');
    end if;
  elsif p_entity_type = 'settings' and v ->> 'active_placement_id' is not null then
    if not exists (
      select 1 from clinical_calendar_sync.records r
      where r.student_id = p_student_id and r.entity_type = 'clinical_placement'
        and r.entity_id = (v ->> 'active_placement_id')::uuid and r.deleted_at_utc is null
    ) then
      return jsonb_build_object('code', 'relationship_violation', 'relationship', 'active_clinical_placement');
    end if;
  elsif p_entity_type = 'preceptor' and length(trim(v ->> 'name')) not between 1 and 120 then
    return jsonb_build_object('code', 'invalid_payload', 'field', 'preceptor_name');
  end if;
  return null;
exception when invalid_text_representation or datetime_field_overflow or numeric_value_out_of_range then
  return jsonb_build_object('code', 'invalid_payload', 'field', 'typed_value');
end
$$;

alter function clinical_calendar_sync.validate_snapshot(uuid, text, uuid, text, jsonb)
  owner to clinical_calendar_sync_executor;

-- The only write RPC. It serializes operations for one Student before taking
-- the idempotency and entity locks. That stable order prevents deadlocks and
-- makes the per-Student cursor reflect commit order, unlike a sequence.
create or replace function public.apply_sync_operation(
  p_idempotency_key uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_operation_type text,
  p_base_revision bigint,
  p_payload jsonb
) returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
set statement_timeout = '5s'
set lock_timeout = '2s'
as $$
declare
  v_student_id uuid := nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
  v_existing clinical_calendar_sync.records%rowtype;
  v_receipt clinical_calendar_sync.operation_receipts%rowtype;
  v_revision bigint;
  v_created_at timestamptz;
  v_updated_at timestamptz;
  v_deleted_at timestamptz;
  v_rejection jsonb;
  v_result jsonb;
  v_cursor bigint;
begin
  if v_student_id is null then
    return jsonb_build_object(
      'accepted', false,
      'rejection', jsonb_build_object('code', 'unauthenticated')
    );
  end if;
  if p_idempotency_key is null or p_entity_type is null or p_entity_id is null
    or p_operation_type is null or p_base_revision is null or p_payload is null
    or p_entity_type not in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings'
  ) or p_operation_type not in ('upsert', 'delete', 'resolve_conflict')
    or p_base_revision < 0 or jsonb_typeof(p_payload) <> 'object' then
    return jsonb_build_object(
      'accepted', false,
      'rejection', jsonb_build_object('code', 'invalid_request')
    );
  end if;

  -- All accepted/rejected operations for this Student acquire locks in this
  -- order: Student advisory lock, receipt, record, feed head.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );

  insert into clinical_calendar_sync.operation_receipts (
    student_id, idempotency_key, entity_type, entity_id, operation_type,
    base_revision, request_payload
  ) values (
    v_student_id, p_idempotency_key, p_entity_type, p_entity_id,
    p_operation_type, p_base_revision, p_payload
  ) on conflict (student_id, idempotency_key) do nothing;

  if not found then
    select * into strict v_receipt
      from clinical_calendar_sync.operation_receipts
      where student_id = v_student_id and idempotency_key = p_idempotency_key
      for update;
    if v_receipt.entity_type <> p_entity_type
      or v_receipt.entity_id <> p_entity_id
      or v_receipt.operation_type <> p_operation_type
      or v_receipt.base_revision <> p_base_revision
      or v_receipt.request_payload <> p_payload then
      return jsonb_build_object(
        'accepted', false,
        'rejection', jsonb_build_object('code', 'idempotency_conflict')
      );
    end if;
    return v_receipt.result;
  end if;

  if (p_payload ->> 'schema_version') <> '1'
    or p_payload ->> 'entity_type' <> p_entity_type
    or p_payload ->> 'entity_id' <> p_entity_id::text
    or p_payload ->> 'student_id' <> v_student_id::text
    or not (p_payload ?& array[
      'revision', 'created_at_utc', 'updated_at_utc', 'deleted_at_utc', 'value'
    ]) then
    v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'envelope');
  elsif p_entity_type = 'settings' and p_entity_id <> v_student_id then
    v_rejection := jsonb_build_object(
      'code', 'invalid_payload', 'field', 'settings_identity'
    );
  else
    begin
      v_revision := (p_payload ->> 'revision')::bigint;
      v_created_at := (p_payload ->> 'created_at_utc')::timestamptz;
      v_updated_at := (p_payload ->> 'updated_at_utc')::timestamptz;
      v_deleted_at := case when p_payload ->> 'deleted_at_utc' is null
        then null else (p_payload ->> 'deleted_at_utc')::timestamptz end;
    exception when invalid_text_representation or datetime_field_overflow
      or numeric_value_out_of_range then
      v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'envelope_type');
    end;
  end if;

  select * into v_existing
    from clinical_calendar_sync.records
    where entity_type = p_entity_type and entity_id = p_entity_id
    for update;

  if v_rejection is null and found and v_existing.student_id <> v_student_id then
    v_rejection := jsonb_build_object('code', 'ownership_violation');
  elsif v_rejection is null
    and coalesce(v_existing.revision, 0) <> p_base_revision then
    v_rejection := jsonb_build_object(
      'code', 'stale_revision',
      'current_revision', coalesce(v_existing.revision, 0)
    );
  elsif v_rejection is null and p_operation_type = 'delete' and not found then
    v_rejection := jsonb_build_object('code', 'not_found');
  elsif v_rejection is null and v_revision <> p_base_revision + 1 then
    v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'revision');
  elsif v_rejection is null and v_updated_at < v_created_at then
    v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'timestamps');
  elsif v_rejection is null and found and v_created_at <> v_existing.created_at_utc then
    v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'created_at_utc');
  elsif v_rejection is null and p_operation_type = 'delete' and v_deleted_at is null then
    v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'deleted_at_utc');
  elsif v_rejection is null and p_operation_type = 'upsert' and v_deleted_at is not null then
    v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'deleted_at_utc');
  end if;

  if v_rejection is null then
    begin
      v_rejection := clinical_calendar_sync.validate_snapshot(
        v_student_id, p_entity_type, p_entity_id, p_operation_type, p_payload
      );
    exception when others then
      v_rejection := jsonb_build_object('code', 'invalid_payload', 'field', 'value');
    end;
  end if;

  if v_rejection is not null then
    v_result := jsonb_build_object(
      'accepted', false,
      'entity_type', p_entity_type,
      'entity_id', p_entity_id,
      'rejection', v_rejection
    );
    update clinical_calendar_sync.operation_receipts
      set result = v_result
      where student_id = v_student_id and idempotency_key = p_idempotency_key;
    return v_result;
  end if;

  begin
    insert into clinical_calendar_sync.records (
      entity_type, entity_id, student_id, revision, created_at_utc,
      updated_at_utc, deleted_at_utc, payload
    ) values (
      p_entity_type, p_entity_id, v_student_id, v_revision, v_created_at,
      v_updated_at, v_deleted_at, p_payload
    ) on conflict (entity_type, entity_id) do update set
      revision = excluded.revision,
      updated_at_utc = excluded.updated_at_utc,
      deleted_at_utc = excluded.deleted_at_utc,
      payload = excluded.payload
    where clinical_calendar_sync.records.student_id = excluded.student_id;
    if not found then
      raise unique_violation;
    end if;
  exception when unique_violation then
    v_result := jsonb_build_object(
      'accepted', false,
      'entity_type', p_entity_type,
      'entity_id', p_entity_id,
      'rejection', jsonb_build_object('code', 'ownership_violation')
    );
    update clinical_calendar_sync.operation_receipts set result = v_result
      where student_id = v_student_id and idempotency_key = p_idempotency_key;
    return v_result;
  end;

  insert into clinical_calendar_sync.feed_heads (student_id, last_cursor)
    values (v_student_id, 0)
    on conflict (student_id) do nothing;
  update clinical_calendar_sync.feed_heads
    set last_cursor = last_cursor + 1
    where student_id = v_student_id
    returning last_cursor into v_cursor;

  insert into clinical_calendar_sync.change_feed (
    student_id, cursor, entity_type, entity_id, revision,
    operation_type, payload
  ) values (
    v_student_id, v_cursor, p_entity_type, p_entity_id, v_revision,
    p_operation_type, p_payload
  );

  v_result := jsonb_build_object(
    'accepted', true,
    'cursor', v_cursor,
    'entity_type', p_entity_type,
    'entity_id', p_entity_id,
    'revision', v_revision
  );
  update clinical_calendar_sync.operation_receipts
    set result = v_result
    where student_id = v_student_id and idempotency_key = p_idempotency_key;
  return v_result;
end
$$;

alter function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  owner to clinical_calendar_sync_executor;

revoke create on schema clinical_calendar_sync from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;

-- Keyset pagination over the durable per-Student cursor. Tombstones are not
-- filtered: deletion is a synchronization event.
create or replace function public.pull_changes_after(
  p_after_cursor bigint default 0,
  p_limit integer default 100
) returns table (
  cursor bigint,
  entity_type text,
  entity_id uuid,
  revision bigint,
  operation_type text,
  payload jsonb,
  accepted_at_utc timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $$
  select f.cursor, f.entity_type, f.entity_id, f.revision,
    f.operation_type, f.payload, f.accepted_at_utc
  from clinical_calendar_sync.change_feed f
  where f.student_id = (select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid)
    and f.cursor > greatest(p_after_cursor, 0)
  order by f.cursor
  limit least(greatest(p_limit, 1), 500)
$$;

revoke all on function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  from public, anon;
revoke all on function public.pull_changes_after(bigint, integer)
  from public, anon;
grant execute on function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  to authenticated;
grant execute on function public.pull_changes_after(bigint, integer)
  to authenticated;

revoke all on function clinical_calendar_sync.validate_snapshot(uuid, text, uuid, text, jsonb)
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.validate_snapshot(uuid, text, uuid, text, jsonb)
  to clinical_calendar_sync_executor;

revoke clinical_calendar_sync_executor from postgres;

alter default privileges in schema clinical_calendar_sync
  revoke all on tables from public, anon, authenticated;
alter default privileges in schema clinical_calendar_sync
  revoke all on functions from public, anon, authenticated;
