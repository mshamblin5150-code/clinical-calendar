-- Guarded account erasure and residual encrypted recovery-snapshot retention.
-- Authenticated clients can request or cancel erasure only through the public
-- RPCs. Final purge functions remain private and are never granted to an app
-- role; a trusted scheduled backend invokes them after the grace period.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;
grant delete on clinical_calendar_sync.change_feed,
  clinical_calendar_sync.operation_receipts to clinical_calendar_sync_executor;

-- Permanent Trash purge is a synchronization operation, but the deleted
-- entity contents must not survive merely to prevent stale resurrection.
alter table clinical_calendar_sync.change_feed
  drop constraint change_feed_entity_type_entity_id_fkey;
alter table clinical_calendar_sync.change_feed
  drop constraint change_feed_operation_type_check;
alter table clinical_calendar_sync.change_feed
  add constraint change_feed_operation_type_check check (
    operation_type in ('upsert', 'delete', 'resolve_conflict', 'purge')
  );
alter table clinical_calendar_sync.operation_receipts
  drop constraint operation_receipts_operation_type_check;
alter table clinical_calendar_sync.operation_receipts
  add constraint operation_receipts_operation_type_check check (
    operation_type in ('upsert', 'delete', 'resolve_conflict', 'purge')
  );

create table clinical_calendar_sync.purge_markers (
  entity_type text not null check (entity_type in (
    'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
    'preceptor', 'clinical_placement', 'historical_hours_entry',
    'evaluation_plan', 'settings'
  )),
  entity_id uuid not null,
  student_id uuid not null references auth.users(id) on delete cascade,
  revision bigint not null check (revision > 1),
  created_at_utc timestamptz not null,
  purged_at_utc timestamptz not null check (purged_at_utc >= created_at_utc),
  cursor bigint not null check (cursor > 0),
  primary key (entity_type, entity_id),
  unique (student_id, cursor),
  unique (student_id, entity_type, entity_id)
);

create index purge_markers_student_entity_idx
  on clinical_calendar_sync.purge_markers
    (student_id, entity_type, entity_id, revision);

alter table clinical_calendar_sync.purge_markers enable row level security;
alter table clinical_calendar_sync.purge_markers force row level security;
create policy purge_markers_executor_owner
  on clinical_calendar_sync.purge_markers
  for all to clinical_calendar_sync_executor
  using (student_id = (select clinical_calendar_sync.current_student_id()))
  with check (student_id = (select clinical_calendar_sync.current_student_id()));
create policy purge_markers_backend
  on clinical_calendar_sync.purge_markers
  for all to postgres using (true) with check (true);

revoke all on clinical_calendar_sync.purge_markers
  from public, anon, authenticated;
grant select, insert on clinical_calendar_sync.purge_markers
  to clinical_calendar_sync_executor;
grant delete on clinical_calendar_sync.records
  to clinical_calendar_sync_executor;

create table clinical_calendar_sync.account_erasure_jobs (
  student_id uuid primary key,
  status text not null check (status in ('pending', 'cancelled', 'complete')),
  backup_choice text not null check (backup_choice in ('completed', 'skipped')),
  requested_at_utc timestamptz not null,
  purge_after_utc timestamptz not null,
  cancelled_at_utc timestamptz,
  completed_at_utc timestamptz,
  requested_by_session_id uuid not null,
  check (purge_after_utc = requested_at_utc + interval '30 days'),
  check ((status = 'pending' and cancelled_at_utc is null and completed_at_utc is null)
    or (status = 'cancelled' and cancelled_at_utc is not null and completed_at_utc is null)
    or (status = 'complete' and completed_at_utc is not null))
);

create index account_erasure_jobs_due_idx
  on clinical_calendar_sync.account_erasure_jobs (purge_after_utc, student_id)
  where status = 'pending';

-- Snapshot bytes are encrypted outside PostgreSQL with a key unavailable to
-- ordinary database readers. Deliberately no auth.users FK: the encrypted
-- recovery copy must survive account deletion for its separately bounded
-- residual-retention window.
create table clinical_calendar_sync.account_recovery_snapshots (
  snapshot_id uuid primary key,
  student_id uuid not null,
  encryption_algorithm text not null check (encryption_algorithm = 'aes-256-gcm'),
  key_reference text not null check (length(trim(key_reference)) between 1 and 255),
  nonce bytea not null check (octet_length(nonce) = 12),
  encrypted_payload bytea not null check (octet_length(encrypted_payload) > 16),
  created_at_utc timestamptz not null,
  expires_at_utc timestamptz not null,
  check (expires_at_utc > created_at_utc),
  check (expires_at_utc <= created_at_utc + interval '60 days')
);

create index account_recovery_snapshots_expiry_idx
  on clinical_calendar_sync.account_recovery_snapshots (expires_at_utc, snapshot_id);
create index account_recovery_snapshots_student_idx
  on clinical_calendar_sync.account_recovery_snapshots
    (student_id, created_at_utc desc);

alter table clinical_calendar_sync.account_erasure_jobs enable row level security;
alter table clinical_calendar_sync.account_erasure_jobs force row level security;
alter table clinical_calendar_sync.account_recovery_snapshots enable row level security;
alter table clinical_calendar_sync.account_recovery_snapshots force row level security;

create policy account_erasure_jobs_executor_owner
  on clinical_calendar_sync.account_erasure_jobs
  for all to clinical_calendar_sync_executor
  using (student_id = (select clinical_calendar_sync.current_student_id()))
  with check (student_id = (select clinical_calendar_sync.current_student_id()));
create policy account_erasure_jobs_backend
  on clinical_calendar_sync.account_erasure_jobs
  for all to postgres using (true) with check (true);
create policy account_recovery_snapshots_backend
  on clinical_calendar_sync.account_recovery_snapshots
  for all to postgres using (true) with check (true);

revoke all on clinical_calendar_sync.account_erasure_jobs,
  clinical_calendar_sync.account_recovery_snapshots
  from public, anon, authenticated;
grant select, insert, update on clinical_calendar_sync.account_erasure_jobs
  to clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.purge_marker_owner(
  p_entity_type text,
  p_entity_id uuid
) returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.student_id
  from clinical_calendar_sync.purge_markers m
  where m.entity_type = p_entity_type and m.entity_id = p_entity_id
$$;

alter function clinical_calendar_sync.purge_marker_owner(text, uuid)
  owner to postgres;
revoke all on function clinical_calendar_sync.purge_marker_owner(text, uuid)
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.purge_marker_owner(text, uuid)
  to clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.reject_permanently_purged_operation(
  p_student_id uuid,
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
as $$
declare
  v_marker clinical_calendar_sync.purge_markers%rowtype;
  v_result jsonb;
begin
  select * into strict v_marker
  from clinical_calendar_sync.purge_markers
  where student_id = p_student_id
    and entity_type = p_entity_type and entity_id = p_entity_id;
  v_result := jsonb_build_object(
    'accepted', false,
    'entity_type', p_entity_type,
    'entity_id', p_entity_id,
    'rejection', jsonb_build_object(
      'code', 'permanently_purged',
      'current_revision', v_marker.revision
    )
  );
  return v_result;
end
$$;

alter function clinical_calendar_sync.reject_permanently_purged_operation(
  uuid, uuid, text, uuid, text, bigint, jsonb
) owner to clinical_calendar_sync_executor;
revoke all on function clinical_calendar_sync.reject_permanently_purged_operation(
  uuid, uuid, text, uuid, text, bigint, jsonb
) from public, anon, authenticated;
grant execute on function clinical_calendar_sync.reject_permanently_purged_operation(
  uuid, uuid, text, uuid, text, bigint, jsonb
) to clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.apply_permanent_purge(
  p_student_id uuid,
  p_idempotency_key uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_base_revision bigint,
  p_payload jsonb
) returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_receipt clinical_calendar_sync.operation_receipts%rowtype;
  v_existing clinical_calendar_sync.records%rowtype;
  v_marker clinical_calendar_sync.purge_markers%rowtype;
  v_marker_owner uuid;
  v_revision bigint;
  v_created_at timestamptz;
  v_updated_at timestamptz;
  v_deleted_at timestamptz;
  v_purged_at timestamptz;
  v_result jsonb;
  v_rejection jsonb;
  v_cursor bigint;
  v_feed_payload jsonb;
begin
  if p_idempotency_key is null or p_entity_type is null or p_entity_id is null
    or p_base_revision is null or p_payload is null or p_base_revision < 1
    or jsonb_typeof(p_payload) <> 'object'
    or p_entity_type not in (
      'work_shift', 'clinical_session', 'protected_day', 'schedule_template',
      'preceptor', 'clinical_placement', 'historical_hours_entry',
      'evaluation_plan', 'settings'
    ) then
    return jsonb_build_object(
      'accepted', false,
      'rejection', jsonb_build_object('code', 'invalid_request')
    );
  end if;

  insert into clinical_calendar_sync.operation_receipts (
    student_id, idempotency_key, entity_type, entity_id, operation_type,
    base_revision, request_payload
  ) values (
    p_student_id, p_idempotency_key, p_entity_type, p_entity_id,
    'purge', p_base_revision, p_payload
  ) on conflict (student_id, idempotency_key) do nothing;
  if not found then
    select * into strict v_receipt
    from clinical_calendar_sync.operation_receipts
    where student_id = p_student_id and idempotency_key = p_idempotency_key
    for update;
    if v_receipt.entity_type <> p_entity_type
      or v_receipt.entity_id <> p_entity_id
      or v_receipt.operation_type <> 'purge'
      or v_receipt.base_revision <> p_base_revision
      or v_receipt.request_payload <> p_payload then
      return jsonb_build_object(
        'accepted', false,
        'rejection', jsonb_build_object('code', 'idempotency_conflict')
      );
    end if;
    return v_receipt.result;
  end if;

  v_marker_owner := clinical_calendar_sync.purge_marker_owner(
    p_entity_type, p_entity_id
  );
  if v_marker_owner is not null and v_marker_owner <> p_student_id then
    v_rejection := jsonb_build_object('code', 'ownership_violation');
  end if;

  if v_rejection is null and (
    (p_payload ->> 'schema_version') <> '1'
    or p_payload ->> 'entity_type' <> p_entity_type
    or p_payload ->> 'entity_id' <> p_entity_id::text
    or p_payload ->> 'student_id' <> p_student_id::text
    or not (p_payload ?& array[
      'revision', 'created_at_utc', 'updated_at_utc', 'deleted_at_utc',
      'purged_at_utc', 'value'
    ])
    or (select count(*) from jsonb_object_keys(p_payload)) <> 10
    or p_payload -> 'value' <> '{}'::jsonb
  ) then
    v_rejection := jsonb_build_object(
      'code', 'invalid_payload', 'field', 'purge_envelope'
    );
  end if;

  if v_rejection is null then
    begin
      v_revision := (p_payload ->> 'revision')::bigint;
      v_created_at := (p_payload ->> 'created_at_utc')::timestamptz;
      v_updated_at := (p_payload ->> 'updated_at_utc')::timestamptz;
      v_deleted_at := (p_payload ->> 'deleted_at_utc')::timestamptz;
      v_purged_at := (p_payload ->> 'purged_at_utc')::timestamptz;
    exception when invalid_text_representation or datetime_field_overflow
      or numeric_value_out_of_range then
      v_rejection := jsonb_build_object(
        'code', 'invalid_payload', 'field', 'purge_envelope_type'
      );
    end;
  end if;

  if v_rejection is null and v_marker_owner = p_student_id then
    select * into strict v_marker
    from clinical_calendar_sync.purge_markers
    where student_id = p_student_id
      and entity_type = p_entity_type and entity_id = p_entity_id;
    if p_base_revision <> v_marker.revision - 1
      or v_revision <> v_marker.revision
      or v_created_at <> v_marker.created_at_utc
      or v_purged_at <> v_marker.purged_at_utc
      or v_updated_at <> v_purged_at then
      v_rejection := jsonb_build_object(
        'code', 'invalid_payload', 'field', 'purge_retry'
      );
    else
      v_result := jsonb_build_object(
        'accepted', true,
        'cursor', v_marker.cursor,
        'entity_type', p_entity_type,
        'entity_id', p_entity_id,
        'revision', v_marker.revision
      );
      update clinical_calendar_sync.operation_receipts set result = v_result
      where student_id = p_student_id and idempotency_key = p_idempotency_key;
      return v_result;
    end if;
  end if;

  select * into v_existing from clinical_calendar_sync.records
  where entity_type = p_entity_type and entity_id = p_entity_id
  for update;
  if v_rejection is null and not found then
    v_rejection := jsonb_build_object('code', 'not_found');
  elsif v_rejection is null and v_existing.student_id <> p_student_id then
    v_rejection := jsonb_build_object('code', 'ownership_violation');
  elsif v_rejection is null and v_existing.deleted_at_utc is null then
    v_rejection := jsonb_build_object('code', 'not_in_trash');
  elsif v_rejection is null and v_existing.revision <> p_base_revision then
    v_rejection := jsonb_build_object(
      'code', 'stale_revision', 'current_revision', v_existing.revision
    );
  elsif v_rejection is null and v_revision <> p_base_revision + 1 then
    v_rejection := jsonb_build_object(
      'code', 'invalid_payload', 'field', 'revision'
    );
  elsif v_rejection is null and v_created_at <> v_existing.created_at_utc then
    v_rejection := jsonb_build_object(
      'code', 'invalid_payload', 'field', 'created_at_utc'
    );
  elsif v_rejection is null and v_deleted_at <> v_existing.deleted_at_utc then
    v_rejection := jsonb_build_object(
      'code', 'invalid_payload', 'field', 'deleted_at_utc'
    );
  elsif v_rejection is null and (
    v_updated_at <> v_purged_at or v_purged_at < v_deleted_at
  ) then
    v_rejection := jsonb_build_object(
      'code', 'invalid_payload', 'field', 'purged_at_utc'
    );
  end if;

  if v_rejection is not null then
    v_result := jsonb_build_object(
      'accepted', false,
      'entity_type', p_entity_type,
      'entity_id', p_entity_id,
      'rejection', v_rejection
    );
    update clinical_calendar_sync.operation_receipts set result = v_result
    where student_id = p_student_id and idempotency_key = p_idempotency_key;
    return v_result;
  end if;

  insert into clinical_calendar_sync.feed_heads (student_id, last_cursor)
  values (p_student_id, 0) on conflict (student_id) do nothing;
  update clinical_calendar_sync.feed_heads set last_cursor = last_cursor + 1
  where student_id = p_student_id returning last_cursor into v_cursor;

  v_feed_payload := jsonb_build_object(
    'schema_version', 1,
    'entity_type', p_entity_type,
    'entity_id', p_entity_id,
    'student_id', p_student_id,
    'revision', v_revision,
    'created_at_utc', v_created_at,
    'updated_at_utc', v_purged_at,
    'deleted_at_utc', v_deleted_at,
    'purged_at_utc', v_purged_at,
    'value', '{}'::jsonb
  );
  insert into clinical_calendar_sync.purge_markers (
    entity_type, entity_id, student_id, revision, created_at_utc,
    purged_at_utc, cursor
  ) values (
    p_entity_type, p_entity_id, p_student_id, v_revision, v_created_at,
    v_purged_at, v_cursor
  );
  delete from clinical_calendar_sync.change_feed
  where student_id = p_student_id
    and entity_type = p_entity_type and entity_id = p_entity_id;
  delete from clinical_calendar_sync.operation_receipts
  where student_id = p_student_id
    and entity_type = p_entity_type and entity_id = p_entity_id
    and idempotency_key <> p_idempotency_key;
  delete from clinical_calendar_sync.records
  where student_id = p_student_id
    and entity_type = p_entity_type and entity_id = p_entity_id;
  insert into clinical_calendar_sync.change_feed (
    student_id, cursor, entity_type, entity_id, revision,
    operation_type, payload
  ) values (
    p_student_id, v_cursor, p_entity_type, p_entity_id, v_revision,
    'purge', v_feed_payload
  );
  v_result := jsonb_build_object(
    'accepted', true,
    'cursor', v_cursor,
    'entity_type', p_entity_type,
    'entity_id', p_entity_id,
    'revision', v_revision
  );
  update clinical_calendar_sync.operation_receipts set result = v_result
  where student_id = p_student_id and idempotency_key = p_idempotency_key;
  return v_result;
end
$$;

alter function clinical_calendar_sync.apply_permanent_purge(
  uuid, uuid, text, uuid, bigint, jsonb
) owner to clinical_calendar_sync_executor;
revoke all on function clinical_calendar_sync.apply_permanent_purge(
  uuid, uuid, text, uuid, bigint, jsonb
) from public, anon, authenticated;
grant execute on function clinical_calendar_sync.apply_permanent_purge(
  uuid, uuid, text, uuid, bigint, jsonb
) to clinical_calendar_sync_executor;

-- Replace the Connected Device wrapper from migration 002. It keeps the same
-- public signature while routing purge and stale-resurrection attempts through
-- the marker-aware path; all ordinary operations retain the audited engine.
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
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_marker_owner uuid;
begin
  perform set_config('request.jwt.claim.sub', v_student_id::text, true);
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  if not clinical_calendar_sync.current_device_is_active() then
    return jsonb_build_object(
      'accepted', false,
      'rejection', jsonb_build_object('code', 'revoked_device')
    );
  end if;
  if p_operation_type = 'purge' then
    return clinical_calendar_sync.apply_permanent_purge(
      v_student_id, p_idempotency_key, p_entity_type, p_entity_id,
      p_base_revision, p_payload
    );
  end if;

  if p_operation_type in ('upsert', 'delete', 'resolve_conflict')
    and p_idempotency_key is not null and p_entity_type is not null
    and p_entity_id is not null and p_base_revision is not null
    and p_payload is not null and jsonb_typeof(p_payload) = 'object'
    and not exists (
      select 1 from clinical_calendar_sync.operation_receipts r
      where r.student_id = v_student_id
        and r.idempotency_key = p_idempotency_key
    ) then
    v_marker_owner := clinical_calendar_sync.purge_marker_owner(
      p_entity_type, p_entity_id
    );
    if v_marker_owner is not null then
      if v_marker_owner <> v_student_id then
        return jsonb_build_object(
          'accepted', false,
          'entity_type', p_entity_type,
          'entity_id', p_entity_id,
          'rejection', jsonb_build_object('code', 'ownership_violation')
        );
      end if;
      return clinical_calendar_sync.reject_permanently_purged_operation(
        v_student_id, p_idempotency_key, p_entity_type, p_entity_id,
        p_operation_type, p_base_revision, p_payload
      );
    end if;
  end if;
  return public.apply_sync_operation_for_active_device(
    p_idempotency_key, p_entity_type, p_entity_id, p_operation_type,
    p_base_revision, p_payload
  );
end
$$;

alter function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  owner to clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.has_fresh_reauthentication(
  p_now_utc timestamptz,
  p_max_age interval default interval '5 minutes'
) returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from auth.sessions s
    where s.id = clinical_calendar_sync.current_session_id()
      and s.user_id = clinical_calendar_sync.current_student_id()
      and s.created_at between p_now_utc - p_max_age
        and p_now_utc + interval '30 seconds'
  )
$$;

alter function clinical_calendar_sync.has_fresh_reauthentication(timestamptz, interval)
  owner to postgres;
revoke all on function clinical_calendar_sync.has_fresh_reauthentication(timestamptz, interval)
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.has_fresh_reauthentication(timestamptz, interval)
  to clinical_calendar_sync_executor;

create function public.request_account_erasure(p_backup_choice text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_session_id uuid := clinical_calendar_sync.current_session_id();
  v_now timestamptz := clock_timestamp();
  v_job clinical_calendar_sync.account_erasure_jobs%rowtype;
begin
  if v_student_id is null or v_session_id is null then
    return jsonb_build_object('status', 'unauthenticated');
  end if;
  if p_backup_choice = 'cancelled' then
    return jsonb_build_object('status', 'backup_cancelled');
  end if;
  if p_backup_choice not in ('completed', 'skipped') then
    return jsonb_build_object('status', 'invalid_backup_choice');
  end if;
  if not clinical_calendar_sync.has_fresh_reauthentication(v_now) then
    return jsonb_build_object('status', 'reauthentication_required');
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  select * into v_job
  from clinical_calendar_sync.account_erasure_jobs
  where student_id = v_student_id
  for update;

  if found and v_job.status = 'pending' then
    return jsonb_build_object(
      'status', 'pending',
      'requested_at_utc', v_job.requested_at_utc,
      'purge_after_utc', v_job.purge_after_utc
    );
  end if;
  if not clinical_calendar_sync.current_device_is_active() then
    return jsonb_build_object('status', 'inactive_device');
  end if;

  insert into clinical_calendar_sync.account_erasure_jobs (
    student_id, status, backup_choice, requested_at_utc, purge_after_utc,
    cancelled_at_utc, completed_at_utc, requested_by_session_id
  ) values (
    v_student_id, 'pending', p_backup_choice, v_now,
    v_now + interval '30 days', null, null, v_session_id
  )
  on conflict (student_id) do update set
    status = excluded.status,
    backup_choice = excluded.backup_choice,
    requested_at_utc = excluded.requested_at_utc,
    purge_after_utc = excluded.purge_after_utc,
    cancelled_at_utc = null,
    completed_at_utc = null,
    requested_by_session_id = excluded.requested_by_session_id
  returning * into v_job;

  -- Scheduling account deletion terminates app-data access on every registered
  -- device. A genuinely new sign-in can cancel during the grace period.
  update clinical_calendar_sync.connected_devices
  set revoked_at_utc = coalesce(revoked_at_utc, v_now)
  where student_id = v_student_id;

  return jsonb_build_object(
    'status', 'pending',
    'requested_at_utc', v_job.requested_at_utc,
    'purge_after_utc', v_job.purge_after_utc
  );
end
$$;

alter function public.request_account_erasure(text)
  owner to clinical_calendar_sync_executor;

create function public.cancel_account_erasure()
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_now timestamptz := clock_timestamp();
  v_job clinical_calendar_sync.account_erasure_jobs%rowtype;
begin
  if v_student_id is null or clinical_calendar_sync.current_session_id() is null then
    return 'unauthenticated';
  end if;
  if not clinical_calendar_sync.has_fresh_reauthentication(v_now) then
    return 'reauthentication_required';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  select * into v_job from clinical_calendar_sync.account_erasure_jobs
  where student_id = v_student_id for update;
  if not found or v_job.status = 'cancelled' then return 'not_pending'; end if;
  if v_job.status = 'complete' or v_now >= v_job.purge_after_utc then
    return 'grace_expired';
  end if;
  update clinical_calendar_sync.account_erasure_jobs
  set status = 'cancelled', cancelled_at_utc = v_now
  where student_id = v_student_id;
  return 'cancelled';
end
$$;

alter function public.cancel_account_erasure()
  owner to clinical_calendar_sync_executor;

-- A successful new passwordless sign-in is represented by a fresh session_id
-- followed by device registration. Wrap the existing registration contract so
-- that this action cancels a still-live grace period, but never a due purge.
alter function public.register_current_device(uuid, text, text)
  rename to register_current_device_without_erasure_recovery;
revoke all on function public.register_current_device_without_erasure_recovery(uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.register_current_device_without_erasure_recovery(uuid, text, text)
  to clinical_calendar_sync_executor;

create function public.register_current_device(
  p_device_id uuid,
  p_device_name text,
  p_platform text
) returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_now timestamptz := clock_timestamp();
  v_job clinical_calendar_sync.account_erasure_jobs%rowtype;
begin
  if v_student_id is null or clinical_calendar_sync.current_session_id() is null then
    return false;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  select * into v_job from clinical_calendar_sync.account_erasure_jobs
  where student_id = v_student_id for update;
  if found and v_job.status = 'pending' then
    if v_now >= v_job.purge_after_utc then return false; end if;
    -- The same JWT session that scheduled deletion is not a new sign-in and
    -- cannot silently undo the request by retrying device registration.
    if clinical_calendar_sync.current_session_id() = v_job.requested_by_session_id then
      return false;
    end if;
    update clinical_calendar_sync.account_erasure_jobs
    set status = 'cancelled', cancelled_at_utc = v_now
    where student_id = v_student_id;
  elsif found and v_job.status = 'complete' then
    return false;
  end if;
  return public.register_current_device_without_erasure_recovery(
    p_device_id, p_device_name, p_platform
  );
end
$$;

alter function public.register_current_device(uuid, text, text)
  owner to clinical_calendar_sync_executor;

-- Trusted scheduler entry point. The supplied time exists for deterministic
-- tests and scheduler replay; clients receive no EXECUTE privilege.
create function clinical_calendar_sync.purge_due_account_erasure(
  p_student_id uuid,
  p_now_utc timestamptz
) returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_job clinical_calendar_sync.account_erasure_jobs%rowtype;
begin
  if p_student_id is null or p_now_utc is null then return 'invalid_request'; end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_student_id::text, 0)
  );
  select * into v_job from clinical_calendar_sync.account_erasure_jobs
  where student_id = p_student_id for update;
  if not found then return 'not_found'; end if;
  if v_job.status = 'complete' then return 'complete'; end if;
  if v_job.status = 'cancelled' then return 'cancelled'; end if;
  if p_now_utc < v_job.purge_after_utc then return 'not_due'; end if;

  -- Child-first, deterministic removal keeps the operation retry-safe and
  -- makes each scope explicit before the final Auth identity deletion.
  delete from clinical_calendar_sync.operation_receipts where student_id = p_student_id;
  delete from clinical_calendar_sync.change_feed where student_id = p_student_id;
  delete from clinical_calendar_sync.feed_heads where student_id = p_student_id;
  delete from clinical_calendar_sync.records where student_id = p_student_id;
  delete from clinical_calendar_sync.purge_markers where student_id = p_student_id;
  delete from clinical_calendar_sync.connected_devices where student_id = p_student_id;
  delete from auth.users where id = p_student_id;

  update clinical_calendar_sync.account_recovery_snapshots
  set expires_at_utc = least(expires_at_utc, p_now_utc + interval '30 days')
  where student_id = p_student_id;
  update clinical_calendar_sync.account_erasure_jobs
  set status = 'complete', completed_at_utc = p_now_utc
  where student_id = p_student_id;
  return 'purged';
end
$$;

alter function clinical_calendar_sync.purge_due_account_erasure(uuid, timestamptz)
  owner to postgres;

create function clinical_calendar_sync.delete_expired_recovery_snapshots(
  p_now_utc timestamptz
) returns bigint
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_count bigint;
begin
  if p_now_utc is null then return 0; end if;
  delete from clinical_calendar_sync.account_recovery_snapshots
  where expires_at_utc <= p_now_utc;
  get diagnostics v_count = row_count;
  return v_count;
end
$$;

alter function clinical_calendar_sync.delete_expired_recovery_snapshots(timestamptz)
  owner to postgres;

revoke all on function public.request_account_erasure(text),
  public.cancel_account_erasure(),
  public.register_current_device(uuid, text, text)
  from public, anon;
grant execute on function public.request_account_erasure(text),
  public.cancel_account_erasure(),
  public.register_current_device(uuid, text, text)
  to authenticated;

revoke all on function clinical_calendar_sync.purge_due_account_erasure(uuid, timestamptz),
  clinical_calendar_sync.delete_expired_recovery_snapshots(timestamptz)
  from public, anon, authenticated, clinical_calendar_sync_executor;

revoke create on schema clinical_calendar_sync from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
revoke clinical_calendar_sync_executor from postgres;
