-- Prevent an older client from overwriting synchronized records whose shape
-- was changed by a newer release. Pull remains available so an old client can
-- stay current while its durable local pushes wait for an application update.

create table clinical_calendar_sync.sync_configuration (
  singleton boolean primary key default true check (singleton),
  minimum_sync_build integer not null check (minimum_sync_build > 0),
  updated_at_utc timestamptz not null default clock_timestamp()
);

insert into clinical_calendar_sync.sync_configuration (
  singleton, minimum_sync_build
) values (true, 46);

revoke all on clinical_calendar_sync.sync_configuration
  from public, anon, authenticated;
grant select on clinical_calendar_sync.sync_configuration
  to clinical_calendar_sync_executor;

-- Keep the latest audited write implementation private. The old public
-- signature becomes an explicit compatibility rejection for installed builds
-- that predate build-number envelopes.
alter function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  rename to apply_sync_operation_for_compatible_build;
revoke all on function public.apply_sync_operation_for_compatible_build(
  uuid, text, uuid, text, bigint, jsonb
) from public, anon, authenticated;
grant execute on function public.apply_sync_operation_for_compatible_build(
  uuid, text, uuid, text, bigint, jsonb
) to clinical_calendar_sync_executor;

create function public.apply_sync_operation(
  p_idempotency_key uuid,
  p_entity_type text,
  p_entity_id uuid,
  p_operation_type text,
  p_base_revision bigint,
  p_payload jsonb
) returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_minimum_sync_build integer;
begin
  select minimum_sync_build into strict v_minimum_sync_build
  from clinical_calendar_sync.sync_configuration
  where singleton;
  return jsonb_build_object(
    'accepted', false,
    'rejection', jsonb_build_object(
      'code', 'minimum_sync_build_required',
      'minimum_build', v_minimum_sync_build
    )
  );
end
$$;

alter function public.apply_sync_operation(uuid, text, uuid, text, bigint, jsonb)
  owner to clinical_calendar_sync_executor;

create function public.apply_sync_operation(
  p_build_number integer,
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
  v_minimum_sync_build integer;
begin
  select minimum_sync_build into strict v_minimum_sync_build
  from clinical_calendar_sync.sync_configuration
  where singleton;
  if p_build_number is null or p_build_number < v_minimum_sync_build then
    return jsonb_build_object(
      'accepted', false,
      'rejection', jsonb_build_object(
        'code', 'minimum_sync_build_required',
        'minimum_build', v_minimum_sync_build
      )
    );
  end if;
  return public.apply_sync_operation_for_compatible_build(
    p_idempotency_key, p_entity_type, p_entity_id, p_operation_type,
    p_base_revision, p_payload
  );
end
$$;

alter function public.apply_sync_operation(
  integer, uuid, text, uuid, text, bigint, jsonb
) owner to clinical_calendar_sync_executor;

-- The legacy two-argument pull remains callable by older builds. Updated
-- clients send their build number through this overload; pull is deliberately
-- not gated by the minimum.
create function public.pull_changes_after(
  p_build_number integer,
  p_after_cursor bigint,
  p_limit integer
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
volatile
security definer
set search_path = ''
as $$
  select * from public.pull_changes_after(p_after_cursor, p_limit)
$$;

alter function public.pull_changes_after(integer, bigint, integer)
  owner to clinical_calendar_sync_executor;

revoke all on function public.apply_sync_operation(
  uuid, text, uuid, text, bigint, jsonb
), public.apply_sync_operation(
  integer, uuid, text, uuid, text, bigint, jsonb
), public.pull_changes_after(integer, bigint, integer)
  from public, anon;
grant execute on function public.apply_sync_operation(
  uuid, text, uuid, text, bigint, jsonb
), public.apply_sync_operation(
  integer, uuid, text, uuid, text, bigint, jsonb
), public.pull_changes_after(integer, bigint, integer)
  to authenticated;

revoke create on schema clinical_calendar_sync
  from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
