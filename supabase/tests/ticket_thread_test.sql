begin;
create extension if not exists pgtap with schema extensions;
select plan(21);

insert into auth.users(id, email) values
  ('00000000-0000-4000-8000-000000000253', 'maintainer-253@example.test'),
  ('10000000-0000-4000-8000-000000000253', 'sender-253@example.test'),
  ('20000000-0000-4000-8000-000000000253', 'other-253@example.test');

insert into clinical_calendar_tickets.maintainer_grants(auth_user_id)
values ('00000000-0000-4000-8000-000000000253');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000253', true);
select public.put_in_ticket(
  'problem', 'The save action stayed busy.', 'Calendar', '253',
  'Windows device', 'windows', clock_timestamp());

set local role postgres;
select set_config('test.ticket_id', (select id::text from public.tickets
  where sender_id = '10000000-0000-4000-8000-000000000253'), true);
set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select public.open_ticket_for_maintainer(
  current_setting('test.ticket_id')::uuid);

select lives_ok($$select public.ask_ticket_question(
  current_setting('test.ticket_id')::uuid,
  'Which action was still busy?')$$,
  'the Maintainer can ask the sender one private question');
select is((select state from public.tickets), 'waiting_on_sender',
  'asking moves the Ticket to Waiting on you');
select is((select question_count from public.tickets), 1,
  'asking increments the question count');
select is((select kind::text from public.ticket_thread_entries), 'question',
  'the question is stored in the private thread');

select set_config('request.jwt.claim.sub',
  '20000000-0000-4000-8000-000000000253', true);
select is((select count(*)::integer from public.ticket_thread_entries), 0,
  'another Student cannot read the private thread');

select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000253', true);
select is((select count(*)::integer from public.ticket_thread_entries), 1,
  'the sender can read the Maintainer question');
select lives_ok($$select public.answer_ticket_question(
  current_setting('test.ticket_id')::uuid,
  (select id from public.ticket_thread_entries where kind = 'question'),
  'Saving a Clinical Session.')$$,
  'the sender can answer the latest question');
select is((select state from public.tickets
  where id = current_setting('test.ticket_id')::uuid), 'seen',
  'answering returns the Ticket to Seen');
select is((select count(*)::integer from public.ticket_thread_entries), 2,
  'the answer completes the private round-trip');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select lives_ok($$select public.request_ticket_diagnostic(
  current_setting('test.ticket_id')::uuid)$$,
  'the Maintainer can request a diagnostic');
select is((select state from public.tickets), 'waiting_on_sender',
  'a diagnostic request moves the Ticket to Waiting on you');

select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000253', true);
select throws_ok($$select public.respond_ticket_diagnostic(
  current_setting('test.ticket_id')::uuid,
  (select id from public.ticket_thread_entries
   where kind = 'diagnostic_request'),
  '{"snapshot_version":1,"build":"253","time_zone":"America/New_York",
    "preceptor_name":"SENTINEL PRIVATE NAME"}'::jsonb)$$,
  'P2866', 'The diagnostic snapshot contains an unapproved value',
  'the database rejects diagnostic keys outside the allow-list');
select is((select state from public.tickets), 'waiting_on_sender',
  'a rejected diagnostic leaves the request waiting');
select lives_ok($$select public.respond_ticket_diagnostic(
  current_setting('test.ticket_id')::uuid,
  (select id from public.ticket_thread_entries
   where kind = 'diagnostic_request'),
  '{"snapshot_version":1,"build":"253","time_zone":"America/New_York",
    "count.preceptors":1,"state.clinical_session.scheduled":2,
    "setting.enhanced_accessibility":false}'::jsonb)$$,
  'the sender can attach an approved structural snapshot');
select is((select state from public.tickets), 'seen',
  'attaching the diagnostic returns the Ticket to Seen');
select is(
  (select diagnostic_snapshot ->> 'build'
   from public.ticket_thread_entries where kind = 'diagnostic_attached'),
  '253', 'the approved snapshot is attached to the private thread');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select throws_ok($$select public.ask_ticket_question(
  current_setting('test.ticket_id')::uuid, 'A third request?')$$,
  'P2865', 'This Ticket has reached its question limit',
  'a diagnostic request counts toward the two-question limit');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000253', true);
select public.put_in_ticket(
  'question', 'Can I decline a diagnostic?', 'Tickets', '253',
  'Windows device', 'windows', clock_timestamp());
set local role postgres;
select set_config('test.declined_ticket_id', (select id::text
  from public.tickets where text = 'Can I decline a diagnostic?'), true);
set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select public.open_ticket_for_maintainer(
  current_setting('test.declined_ticket_id')::uuid);
select public.request_ticket_diagnostic(
  current_setting('test.declined_ticket_id')::uuid);
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000253', true);
select lives_ok($$select public.respond_ticket_diagnostic(
  current_setting('test.declined_ticket_id')::uuid,
  (select id from public.ticket_thread_entries
   where ticket_id = current_setting('test.declined_ticket_id')::uuid
     and kind = 'diagnostic_request'
   order by created_at desc, id desc limit 1), null)$$,
  'the sender can decline a diagnostic');
select is(
  (select count(*)::integer from public.ticket_thread_entries
   where kind = 'diagnostic_declined' and diagnostic_snapshot is null),
  1, 'declining attaches nothing');
select is((select state from public.tickets
  where id = current_setting('test.declined_ticket_id')::uuid), 'seen',
  'declining returns the Ticket to Seen');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select is((select count(*)::integer from public.ticket_thread_entries), 6,
  'the Maintainer can read the complete private thread');

select * from finish();
rollback;
