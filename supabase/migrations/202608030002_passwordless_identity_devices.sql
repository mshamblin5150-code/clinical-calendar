-- Passwordless identity and Connected Devices enforcement.
-- A device is bound to the Supabase Auth session_id claim. Revocation is an
-- application-data access decision; it never claims to erase an offline copy.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.current_student_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    nullif(
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'),
      ''
    )
  )::uuid
$$;

create or replace function clinical_calendar_sync.current_session_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.session_id', true), ''),
    nullif(
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'session_id'),
      ''
    )
  )::uuid
$$;

alter function clinical_calendar_sync.current_student_id()
  owner to clinical_calendar_sync_executor;
alter function clinical_calendar_sync.current_session_id()
  owner to clinical_calendar_sync_executor;
revoke all on function clinical_calendar_sync.current_student_id(),
  clinical_calendar_sync.current_session_id()
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.current_student_id(),
  clinical_calendar_sync.current_session_id()
  to clinical_calendar_sync_executor, postgres;

create table clinical_calendar_sync.connected_devices (
  device_id uuid primary key,
  student_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null,
  device_name text not null check (length(trim(device_name)) between 1 and 120),
  platform text not null check (platform in ('windows', 'ios', 'android')),
  registered_at_utc timestamptz not null default clock_timestamp(),
  last_synchronized_at_utc timestamptz,
  revoked_at_utc timestamptz,
  unique (student_id, session_id),
  unique (student_id, device_id)
);

create index connected_devices_student_active_idx
  on clinical_calendar_sync.connected_devices (student_id, last_synchronized_at_utc desc)
  where revoked_at_utc is null;

alter table clinical_calendar_sync.connected_devices enable row level security;
alter table clinical_calendar_sync.connected_devices force row level security;

create policy connected_devices_executor_owner
  on clinical_calendar_sync.connected_devices
  for all to clinical_calendar_sync_executor
  using (
    student_id = (select clinical_calendar_sync.current_student_id())
  )
  with check (
    student_id = (select clinical_calendar_sync.current_student_id())
  );

revoke all on clinical_calendar_sync.connected_devices from public, anon, authenticated;
grant select, insert, update on clinical_calendar_sync.connected_devices
  to clinical_calendar_sync_executor;

-- The public RPCs are the only authenticated read boundary. These revokes are
-- deliberately repeated here so a future PostgREST schema configuration
-- cannot accidentally turn the original RLS table grants into a bypass of
-- Connected Device revocation.
revoke select on clinical_calendar_sync.records,
  clinical_calendar_sync.change_feed,
  clinical_calendar_sync.operation_receipts from authenticated;

create or replace function clinical_calendar_sync.current_device_is_active()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from clinical_calendar_sync.connected_devices d
    where d.student_id = clinical_calendar_sync.current_student_id()
      and d.session_id = clinical_calendar_sync.current_session_id()
      and d.revoked_at_utc is null
  )
$$;

alter function clinical_calendar_sync.current_device_is_active()
  owner to clinical_calendar_sync_executor;
revoke all on function clinical_calendar_sync.current_device_is_active()
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.current_device_is_active()
  to clinical_calendar_sync_executor;

create or replace function public.register_current_device(
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
  v_session_id uuid := clinical_calendar_sync.current_session_id();
begin
  if v_student_id is null or v_session_id is null then
    return false;
  end if;
  if p_device_id is null or p_device_name is null or p_platform is null
    or length(trim(p_device_name)) not between 1 and 120
    or p_platform not in ('windows', 'ios', 'android') then
    return false;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );

  -- Rebind this installation to a newly authenticated session for the same
  -- Student. A globally colliding identifier owned by another Student, or a
  -- session already bound to another installation, fails closed through the
  -- unique constraints and exception handler.
  update clinical_calendar_sync.connected_devices
  set session_id = v_session_id,
      device_name = trim(p_device_name),
      platform = p_platform,
      registered_at_utc = clock_timestamp(),
      revoked_at_utc = null
  where student_id = v_student_id and device_id = p_device_id
    and (session_id <> v_session_id or revoked_at_utc is null);
  if found then
    return clinical_calendar_sync.current_device_is_active();
  end if;

  insert into clinical_calendar_sync.connected_devices (
    device_id, student_id, session_id, device_name, platform
  ) values (
    p_device_id, v_student_id, v_session_id, trim(p_device_name), p_platform
  );

  return clinical_calendar_sync.current_device_is_active();
exception when unique_violation then
  return false;
end
$$;

alter function public.register_current_device(uuid, text, text)
  owner to clinical_calendar_sync_executor;

create or replace function public.list_connected_devices()
returns table (
  device_id uuid,
  device_name text,
  platform text,
  last_synchronized_at_utc timestamptz,
  is_current boolean,
  is_revoked boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select d.device_id, d.device_name, d.platform,
    d.last_synchronized_at_utc,
    d.session_id = clinical_calendar_sync.current_session_id(),
    d.revoked_at_utc is not null
  from clinical_calendar_sync.connected_devices d
  where d.student_id = clinical_calendar_sync.current_student_id()
    and clinical_calendar_sync.current_device_is_active()
  order by (d.revoked_at_utc is null) desc,
    d.last_synchronized_at_utc desc nulls last,
    d.registered_at_utc desc
$$;

alter function public.list_connected_devices()
  owner to clinical_calendar_sync_executor;

create or replace function public.revoke_connected_device(p_device_id uuid)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_session_id uuid := clinical_calendar_sync.current_session_id();
  v_target_session_id uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  if not clinical_calendar_sync.current_device_is_active() then
    return 'revoked_device';
  end if;
  select d.session_id into v_target_session_id
  from clinical_calendar_sync.connected_devices d
  where d.student_id = v_student_id and d.device_id = p_device_id;

  if v_target_session_id is null then return 'not_found'; end if;
  if v_target_session_id = v_session_id then return 'current_device'; end if;

  update clinical_calendar_sync.connected_devices
  set revoked_at_utc = coalesce(revoked_at_utc, clock_timestamp())
  where student_id = v_student_id and device_id = p_device_id;
  return 'revoked';
end
$$;

alter function public.revoke_connected_device(uuid)
  owner to clinical_calendar_sync_executor;

create or replace function public.mark_current_device_synchronized()
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      clinical_calendar_sync.current_student_id()::text, 0
    )
  );
  update clinical_calendar_sync.connected_devices
  set last_synchronized_at_utc = clock_timestamp()
  where student_id = clinical_calendar_sync.current_student_id()
    and session_id = clinical_calendar_sync.current_session_id()
    and revoked_at_utc is null;
  return found;
end
$$;

alter function public.mark_current_device_synchronized()
  owner to clinical_calendar_sync_executor;

create or replace function public.deactivate_current_device()
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  update clinical_calendar_sync.connected_devices
  set revoked_at_utc = coalesce(revoked_at_utc, clock_timestamp())
  where student_id = v_student_id
    and session_id = clinical_calendar_sync.current_session_id()
    and revoked_at_utc is null;
  if found then return true; end if;
  return exists (
    select 1 from clinical_calendar_sync.connected_devices
    where student_id = v_student_id
      and session_id = clinical_calendar_sync.current_session_id()
      and revoked_at_utc is not null
  );
end
$$;

alter function public.deactivate_current_device()
  owner to clinical_calendar_sync_executor;

-- Preserve the audited synchronization implementation behind a narrow,
-- session-bound authorization wrapper.
alter function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  rename to apply_sync_operation_for_active_device;
revoke all on function public.apply_sync_operation_for_active_device(uuid, text, uuid, text, bigint, jsonb)
  from public, anon, authenticated;
grant execute on function public.apply_sync_operation_for_active_device(uuid, text, uuid, text, bigint, jsonb)
  to clinical_calendar_sync_executor;

create function public.apply_sync_operation(
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
begin
  perform set_config(
    'request.jwt.claim.sub',
    clinical_calendar_sync.current_student_id()::text,
    true
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      clinical_calendar_sync.current_student_id()::text, 0
    )
  );
  if not clinical_calendar_sync.current_device_is_active() then
    return jsonb_build_object(
      'accepted', false,
      'rejection', jsonb_build_object('code', 'revoked_device')
    );
  end if;
  return public.apply_sync_operation_for_active_device(
    p_idempotency_key, p_entity_type, p_entity_id, p_operation_type,
    p_base_revision, p_payload
  );
end
$$;

alter function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  owner to clinical_calendar_sync_executor;

alter function public.pull_changes_after(bigint, integer)
  rename to pull_changes_after_for_active_device;
revoke all on function public.pull_changes_after_for_active_device(bigint, integer)
  from public, anon, authenticated;
grant execute on function public.pull_changes_after_for_active_device(bigint, integer)
  to clinical_calendar_sync_executor;

create function public.pull_changes_after(
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
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform set_config(
    'request.jwt.claim.sub',
    clinical_calendar_sync.current_student_id()::text,
    true
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      clinical_calendar_sync.current_student_id()::text, 0
    )
  );
  if not clinical_calendar_sync.current_device_is_active() then
    raise sqlstate 'PT403' using message = 'revoked_device';
  end if;
  return query select * from public.pull_changes_after_for_active_device(
    p_after_cursor, p_limit
  );
end
$$;

alter function public.pull_changes_after(bigint, integer)
  owner to clinical_calendar_sync_executor;

revoke all on function public.register_current_device(uuid, text, text),
  public.list_connected_devices(),
  public.revoke_connected_device(uuid),
  public.mark_current_device_synchronized(),
  public.deactivate_current_device(),
  public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb),
  public.pull_changes_after(bigint, integer)
  from public, anon;
grant execute on function public.register_current_device(uuid, text, text),
  public.list_connected_devices(),
  public.revoke_connected_device(uuid),
  public.mark_current_device_synchronized(),
  public.deactivate_current_device(),
  public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb),
  public.pull_changes_after(bigint, integer)
  to authenticated;

revoke create on schema clinical_calendar_sync from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
revoke clinical_calendar_sync_executor from postgres;
