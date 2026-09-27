begin;

create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
) values
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
   'relay-student-a@example.invalid', '', now(), now(), now(), '{}', '{}'),
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
   'relay-student-b@example.invalid', '', now(), now(), now(), '{}', '{}');

insert into clinical_calendar_sync.work_schedule_feeds (
  feed_id, student_id, url
) values (
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'webcal://calendar.example/private-token.ics'
);

set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000002';

select is(
  public.claim_work_schedule_feed_relay(
    '20000000-0000-4000-8000-000000000001'
  ) ->> 'kind',
  'not_found',
  'another Student cannot claim the feed'
);

set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
create temporary table first_relay_claim as
select public.claim_work_schedule_feed_relay(
  '20000000-0000-4000-8000-000000000001'
) as result;

select is(
  (select result ->> 'kind' from first_relay_claim),
  'fetch',
  'the owning Student receives the first fetch lease'
);

select is(
  public.claim_work_schedule_feed_relay(
    '20000000-0000-4000-8000-000000000001'
  ) #>> '{result,errorClass}',
  'fetch_in_progress',
  'a concurrent request cannot start another download'
);

select is(
  public.finish_work_schedule_feed_relay(
    '20000000-0000-4000-8000-000000000001',
    (select (result ->> 'leaseToken')::uuid from first_relay_claim),
    '2026-09-27T12:00:00Z', 200,
    E'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n',
    '"feed-v1"', 'Sat, 26 Sep 2026 12:00:00 GMT', null
  ) ->> 'ics',
  E'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n',
  'a successful fetch stores and returns raw ICS text'
);

select is(
  public.claim_work_schedule_feed_relay(
    '20000000-0000-4000-8000-000000000001'
  ) ->> 'kind',
  'cached',
  'a request inside 15 minutes receives the cache'
);

reset role;
update clinical_calendar_sync.work_schedule_feed_cache
set attempted_at_utc = clock_timestamp() - interval '16 minutes'
where feed_id = '20000000-0000-4000-8000-000000000001';
set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-4000-8000-000000000001';
create temporary table revalidation_claim as
select public.claim_work_schedule_feed_relay(
  '20000000-0000-4000-8000-000000000001'
) as result;

select is(
  (select result ->> 'etag' from revalidation_claim),
  '"feed-v1"',
  'a request after 15 minutes receives validators for revalidation'
);

select is(
  public.finish_work_schedule_feed_relay(
    '20000000-0000-4000-8000-000000000001',
    (select (result ->> 'leaseToken')::uuid from revalidation_claim),
    '2026-09-27T12:16:00Z', 304,
    E'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n', null, null, null
  ) ->> 'fromCache',
  'true',
  'a 304 passes through with the cached raw ICS result'
);

select * from finish();
rollback;
