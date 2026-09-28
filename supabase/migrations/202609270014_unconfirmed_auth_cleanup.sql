-- Remove abandoned passwordless sign-in identities after a seven-day grace
-- period. The function is private and owned by the scheduler's privileged
-- role because deleting from auth.users must never be a client capability.

create extension if not exists pg_cron;

create function clinical_calendar_sync.delete_never_confirmed_auth_users()
returns bigint
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_deleted_count bigint;
begin
  delete from auth.users as auth_user
  where auth_user.email_confirmed_at is null
    and auth_user.last_sign_in_at is null
    and auth_user.created_at < clock_timestamp() - interval '7 days'
    and not exists (
      select 1
      from clinical_calendar_sync.connected_devices as device
      where device.student_id = auth_user.id
    );

  get diagnostics v_deleted_count = row_count;
  return v_deleted_count;
end
$$;

alter function clinical_calendar_sync.delete_never_confirmed_auth_users()
  owner to postgres;

revoke all on function
  clinical_calendar_sync.delete_never_confirmed_auth_users()
  from public, anon, authenticated;

select cron.schedule(
  'clinical-calendar-delete-never-confirmed-auth-users',
  '0 3 * * *',
  'select clinical_calendar_sync.delete_never_confirmed_auth_users()'
);
