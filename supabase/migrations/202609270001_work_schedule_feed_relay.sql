-- Authenticated, bounded relay support for Student-owned Work Schedule Feeds.

grant clinical_calendar_sync_executor to postgres;
grant create on schema clinical_calendar_sync to clinical_calendar_sync_executor;
grant create on schema public to clinical_calendar_sync_executor;

-- This is the server-side account row the relay reads. Issue #247 extends the
-- Work Schedule Feed model and synchronization; callers of this function never
-- provide the credential URL themselves.
create table clinical_calendar_sync.work_schedule_feeds (
  feed_id uuid primary key,
  student_id uuid not null references auth.users(id) on delete cascade,
  url text not null check (
    length(url) between 1 and 4096
    and url ~* '^(https|webcal)://'
  ),
  created_at_utc timestamptz not null default clock_timestamp(),
  updated_at_utc timestamptz not null default clock_timestamp(),
  unique (feed_id, student_id),
  check (updated_at_utc >= created_at_utc)
);
revoke all on clinical_calendar_sync.work_schedule_feeds
  from public, anon, authenticated;
grant select on clinical_calendar_sync.work_schedule_feeds
  to clinical_calendar_sync_executor;

create table clinical_calendar_sync.work_schedule_feed_cache (
  feed_id uuid primary key,
  student_id uuid not null,
  attempted_at_utc timestamptz,
  fetched_at_utc timestamptz,
  upstream_status integer,
  ics_text text,
  etag text,
  last_modified text,
  error_class text,
  lease_token uuid,
  lease_until_utc timestamptz,
  check (octet_length(ics_text) <= 3145728),
  check ((lease_token is null) = (lease_until_utc is null)),
  foreign key (feed_id, student_id)
    references clinical_calendar_sync.work_schedule_feeds(feed_id, student_id)
    on delete cascade
);
revoke all on clinical_calendar_sync.work_schedule_feed_cache
  from public, anon, authenticated;
grant select, insert, update on clinical_calendar_sync.work_schedule_feed_cache
  to clinical_calendar_sync_executor;

create function public.claim_work_schedule_feed_relay(p_feed_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_now timestamptz := clock_timestamp();
  v_url text;
  v_cache clinical_calendar_sync.work_schedule_feed_cache%rowtype;
  v_lease_token uuid;
begin
  select f.url
  into v_url
  from clinical_calendar_sync.work_schedule_feeds f
  where f.feed_id = p_feed_id
    and f.student_id = v_student_id;

  if v_url is null then
    return jsonb_build_object('kind', 'not_found');
  end if;

  insert into clinical_calendar_sync.work_schedule_feed_cache(feed_id, student_id)
  values (p_feed_id, v_student_id)
  on conflict (feed_id) do nothing;

  select * into v_cache
  from clinical_calendar_sync.work_schedule_feed_cache c
  where c.feed_id = p_feed_id and c.student_id = v_student_id
  for update;

  if v_cache.lease_until_utc > v_now then
    return jsonb_build_object(
      'kind', 'cached',
      'result', jsonb_build_object(
        'ics', case when v_cache.ics_text is not null then v_cache.ics_text else null end,
        'fetchedAt', v_cache.fetched_at_utc,
        'upstreamStatus', v_cache.upstream_status,
        'fromCache', true,
        'errorClass', case
          when v_cache.ics_text is null then 'fetch_in_progress'
          else v_cache.error_class
        end
      )
    );
  end if;

  if v_cache.attempted_at_utc >= v_now - interval '15 minutes' then
    return jsonb_build_object(
      'kind', 'cached',
      'result', jsonb_build_object(
        'ics', case when v_cache.error_class is null then v_cache.ics_text else null end,
        'fetchedAt', v_cache.fetched_at_utc,
        'upstreamStatus', v_cache.upstream_status,
        'fromCache', true,
        'errorClass', v_cache.error_class
      )
    );
  end if;

  v_lease_token := pg_catalog.gen_random_uuid();
  update clinical_calendar_sync.work_schedule_feed_cache
  set attempted_at_utc = v_now,
      lease_token = v_lease_token,
      lease_until_utc = v_now + interval '30 seconds'
  where feed_id = p_feed_id and student_id = v_student_id;

  return jsonb_build_object(
    'kind', 'fetch',
    'feedId', p_feed_id,
    'leaseToken', v_lease_token,
    'url', v_url,
    'etag', v_cache.etag,
    'lastModified', v_cache.last_modified,
    'cachedIcs', v_cache.ics_text
  );
end
$$;

alter function public.claim_work_schedule_feed_relay(uuid)
  owner to clinical_calendar_sync_executor;
revoke all on function public.claim_work_schedule_feed_relay(uuid)
  from public, anon;
grant execute on function public.claim_work_schedule_feed_relay(uuid)
  to authenticated;

create function public.finish_work_schedule_feed_relay(
  p_feed_id uuid,
  p_lease_token uuid,
  p_fetched_at_utc timestamptz,
  p_upstream_status integer,
  p_ics_text text,
  p_etag text,
  p_last_modified text,
  p_error_class text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
  v_cache clinical_calendar_sync.work_schedule_feed_cache%rowtype;
begin
  update clinical_calendar_sync.work_schedule_feed_cache
  set fetched_at_utc = p_fetched_at_utc,
      upstream_status = p_upstream_status,
      ics_text = case
        when p_error_class is not null or p_upstream_status = 304 then ics_text
        else p_ics_text
      end,
      etag = case when p_error_class is null then coalesce(p_etag, etag) else etag end,
      last_modified = case
        when p_error_class is null then coalesce(p_last_modified, last_modified)
        else last_modified
      end,
      error_class = p_error_class,
      lease_token = null,
      lease_until_utc = null
  where feed_id = p_feed_id
    and student_id = v_student_id
    and lease_token = p_lease_token
  returning * into v_cache;

  if not found then
    raise sqlstate 'PT409' using message = 'invalid_relay_lease';
  end if;

  return jsonb_build_object(
    'ics', case when v_cache.error_class is null then v_cache.ics_text else null end,
    'fetchedAt', v_cache.fetched_at_utc,
    'upstreamStatus', v_cache.upstream_status,
    'fromCache', v_cache.upstream_status = 304,
    'errorClass', v_cache.error_class
  );
end
$$;

alter function public.finish_work_schedule_feed_relay(
  uuid, uuid, timestamptz, integer, text, text, text, text
) owner to clinical_calendar_sync_executor;
revoke all on function public.finish_work_schedule_feed_relay(
  uuid, uuid, timestamptz, integer, text, text, text, text
) from public, anon;
grant execute on function public.finish_work_schedule_feed_relay(
  uuid, uuid, timestamptz, integer, text, text, text, text
) to authenticated;

revoke create on schema clinical_calendar_sync from clinical_calendar_sync_executor;
revoke create on schema public from clinical_calendar_sync_executor;
revoke clinical_calendar_sync_executor from postgres;
