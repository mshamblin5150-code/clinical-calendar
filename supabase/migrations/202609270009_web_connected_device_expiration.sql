-- Each browser is a Connected Device. Web sessions expire after 90 days
-- without a successful synchronization; native Connected Devices do not.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

alter table clinical_calendar_sync.connected_devices
  drop constraint connected_devices_platform_check;
alter table clinical_calendar_sync.connected_devices
  add constraint connected_devices_platform_check
  check (platform in ('windows', 'ios', 'android', 'web'));

create or replace function clinical_calendar_sync.set_auth_session_not_after(
  p_student_id uuid,
  p_session_id uuid,
  p_not_after_utc timestamptz
) returns void
language sql
volatile
security definer
set search_path = ''
as $$
  update auth.sessions
  set not_after = p_not_after_utc
  where id = p_session_id and user_id = p_student_id
$$;

alter function clinical_calendar_sync.set_auth_session_not_after(
  uuid, uuid, timestamptz
) owner to postgres;
revoke all on function clinical_calendar_sync.set_auth_session_not_after(
  uuid, uuid, timestamptz
) from public, anon, authenticated;
grant execute on function clinical_calendar_sync.set_auth_session_not_after(
  uuid, uuid, timestamptz
) to clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.delete_auth_session(
  p_student_id uuid,
  p_session_id uuid
) returns void
language sql
volatile
security definer
set search_path = ''
as $$
  delete from auth.sessions
  where id = p_session_id and user_id = p_student_id
$$;

alter function clinical_calendar_sync.delete_auth_session(uuid, uuid)
  owner to postgres;
revoke all on function clinical_calendar_sync.delete_auth_session(uuid, uuid)
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.delete_auth_session(uuid, uuid)
  to clinical_calendar_sync_executor;

set role clinical_calendar_sync_executor;

create or replace function clinical_calendar_sync.device_is_within_web_idle_window(
  p_platform text,
  p_registered_at_utc timestamptz,
  p_last_synchronized_at_utc timestamptz,
  p_now_utc timestamptz
) returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select p_platform <> 'web'
    or coalesce(p_last_synchronized_at_utc, p_registered_at_utc)
      > p_now_utc - interval '90 days'
$$;

revoke all on function clinical_calendar_sync.device_is_within_web_idle_window(
  text, timestamptz, timestamptz, timestamptz
) from public, anon, authenticated;
grant execute on function clinical_calendar_sync.device_is_within_web_idle_window(
  text, timestamptz, timestamptz, timestamptz
) to clinical_calendar_sync_executor, postgres;

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
      and clinical_calendar_sync.device_is_within_web_idle_window(
        d.platform, d.registered_at_utc, d.last_synchronized_at_utc,
        clock_timestamp()
      )
  )
$$;

alter function clinical_calendar_sync.current_device_is_active()
  owner to clinical_calendar_sync_executor;
revoke all on function clinical_calendar_sync.current_device_is_active()
  from public, anon, authenticated;
grant execute on function clinical_calendar_sync.current_device_is_active()
  to clinical_calendar_sync_executor;

create or replace function public.register_current_device_without_erasure_recovery(
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
  v_now timestamptz := clock_timestamp();
  v_web_deadline_utc timestamptz;
begin
  if v_student_id is null or v_session_id is null then
    return false;
  end if;
  if p_device_id is null or p_device_name is null or p_platform is null
    or length(trim(p_device_name)) not between 1 and 120
    or p_platform not in ('windows', 'ios', 'android', 'web') then
    return false;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );

  update clinical_calendar_sync.connected_devices
  set session_id = v_session_id,
      device_name = trim(p_device_name),
      platform = p_platform,
      registered_at_utc = v_now,
      revoked_at_utc = null
  where student_id = v_student_id and device_id = p_device_id
    and (session_id <> v_session_id or revoked_at_utc is null)
  returning coalesce(last_synchronized_at_utc, registered_at_utc)
    + interval '90 days'
  into v_web_deadline_utc;
  if not found then
    insert into clinical_calendar_sync.connected_devices (
      device_id, student_id, session_id, device_name, platform, registered_at_utc
    ) values (
      p_device_id, v_student_id, v_session_id, trim(p_device_name), p_platform,
      v_now
    );
    v_web_deadline_utc := v_now + interval '90 days';
  end if;

  perform clinical_calendar_sync.set_auth_session_not_after(
    v_student_id,
    v_session_id,
    case when p_platform = 'web' then v_web_deadline_utc else null end
  );
  return clinical_calendar_sync.current_device_is_active();
exception when unique_violation then
  return false;
end
$$;

alter function public.register_current_device_without_erasure_recovery(uuid, text, text)
  owner to clinical_calendar_sync_executor;
revoke all on function public.register_current_device_without_erasure_recovery(uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.register_current_device_without_erasure_recovery(uuid, text, text)
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
  v_now timestamptz := clock_timestamp();
  v_job clinical_calendar_sync.account_erasure_jobs%rowtype;
begin
  if v_student_id is null or clinical_calendar_sync.current_session_id() is null then
    return false;
  end if;
  if p_device_id is null or p_device_name is null or p_platform is null
    or length(trim(p_device_name)) not between 1 and 120
    or p_platform not in ('windows', 'ios', 'android', 'web') then
    return false;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  select * into v_job from clinical_calendar_sync.account_erasure_jobs
  where student_id = v_student_id for update;
  if found and v_job.status = 'pending' then
    if v_now >= v_job.purge_after_utc then return false; end if;
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
  v_target_platform text;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  if not clinical_calendar_sync.current_device_is_active() then
    return 'revoked_device';
  end if;
  select d.session_id, d.platform
  into v_target_session_id, v_target_platform
  from clinical_calendar_sync.connected_devices d
  where d.student_id = v_student_id and d.device_id = p_device_id;

  if v_target_session_id is null then return 'not_found'; end if;
  if v_target_session_id = v_session_id then return 'current_device'; end if;

  update clinical_calendar_sync.connected_devices
  set revoked_at_utc = coalesce(revoked_at_utc, clock_timestamp())
  where student_id = v_student_id and device_id = p_device_id;
  if v_target_platform = 'web' then
    perform clinical_calendar_sync.delete_auth_session(
      v_student_id, v_target_session_id
    );
  end if;
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
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_session_id uuid := clinical_calendar_sync.current_session_id();
  v_now timestamptz := clock_timestamp();
  v_platform text;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_student_id::text, 0)
  );
  update clinical_calendar_sync.connected_devices
  set last_synchronized_at_utc = v_now
  where student_id = v_student_id
    and session_id = v_session_id
    and revoked_at_utc is null
    and clinical_calendar_sync.device_is_within_web_idle_window(
      platform, registered_at_utc, last_synchronized_at_utc, v_now
    )
  returning platform into v_platform;
  if not found then return false; end if;
  if v_platform = 'web' then
    perform clinical_calendar_sync.set_auth_session_not_after(
      v_student_id, v_session_id, v_now + interval '90 days'
    );
  end if;
  return true;
end
$$;

alter function public.mark_current_device_synchronized()
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
    and not (
      d.platform = 'web'
      and (
        d.revoked_at_utc is not null
        or not clinical_calendar_sync.device_is_within_web_idle_window(
          d.platform, d.registered_at_utc, d.last_synchronized_at_utc,
          clock_timestamp()
        )
      )
    )
  order by (d.revoked_at_utc is null) desc,
    d.last_synchronized_at_utc desc nulls last,
    d.registered_at_utc desc
$$;

alter function public.list_connected_devices()
  owner to clinical_calendar_sync_executor;

reset role;

-- Run from trusted server infrastructure. Deleting the matching Auth session
-- invalidates its refresh tokens; the active-device predicate above closes the
-- sync boundary even if this retention job is delayed.
create or replace function clinical_calendar_sync.revoke_inactive_web_devices(
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

  with expired as (
    update clinical_calendar_sync.connected_devices
    set revoked_at_utc = p_now_utc
    where platform = 'web'
      and revoked_at_utc is null
      and not clinical_calendar_sync.device_is_within_web_idle_window(
        platform, registered_at_utc, last_synchronized_at_utc, p_now_utc
      )
    returning session_id
  ), deleted_sessions as (
    delete from auth.sessions s
    using expired e
    where s.id = e.session_id
    returning s.id
  )
  select count(*) into v_count from expired;

  return v_count;
end
$$;

alter function clinical_calendar_sync.revoke_inactive_web_devices(timestamptz)
  owner to postgres;
revoke all on function clinical_calendar_sync.revoke_inactive_web_devices(timestamptz)
  from public, anon, authenticated, clinical_calendar_sync_executor;

revoke all on function public.register_current_device(uuid, text, text),
  public.list_connected_devices(),
  public.revoke_connected_device(uuid),
  public.mark_current_device_synchronized()
  from public, anon;
grant execute on function public.register_current_device(uuid, text, text),
  public.list_connected_devices(),
  public.revoke_connected_device(uuid),
  public.mark_current_device_synchronized()
  to authenticated;

revoke create on schema clinical_calendar_sync
  from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
revoke clinical_calendar_sync_executor from postgres;
