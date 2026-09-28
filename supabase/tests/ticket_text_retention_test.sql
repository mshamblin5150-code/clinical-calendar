begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

insert into auth.users(id, email) values
  ('00000000-0000-4000-8000-000000000256', 'maintainer-256@example.test'),
  ('10000000-0000-4000-8000-000000000256', 'sender-256@example.test'),
  ('20000000-0000-4000-8000-000000000256', 'other-256@example.test');

insert into clinical_calendar_tickets.maintainer_grants(auth_user_id)
values ('00000000-0000-4000-8000-000000000256');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000256', true);
select public.put_in_ticket(
  'problem', 'Patient detail that must disappear.', 'Calendar', '256',
  'Windows device', 'windows', clock_timestamp());
select public.put_in_ticket(
  'idea', 'Keep this open Ticket.', 'Tickets', '256',
  'Windows device', 'windows', clock_timestamp());
select public.put_in_ticket(
  'question', 'Keep this reopened Ticket.', 'Tickets', '256',
  'Windows device', 'windows', clock_timestamp());
select public.put_in_ticket(
  'idea', 'Redact this Ticket now.', 'Tickets', '256',
  'Windows device', 'windows', clock_timestamp());
select public.put_in_ticket(
  'question', 'Keep this until the full 90 days pass.', 'Tickets', '256',
  'Windows device', 'windows', clock_timestamp());

set local role postgres;
create temporary table tickets_256 as
select kind, text, id from public.tickets;
grant select on tickets_256 to authenticated;

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000256', true);
select public.open_ticket_for_maintainer(
  (select id from tickets_256
   where text = 'Patient detail that must disappear.'));
select public.ask_ticket_question(
  (select id from tickets_256
   where text = 'Patient detail that must disappear.'),
  'Which screen contained the detail?');
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000256', true);
select public.answer_ticket_question(
  (select id from tickets_256
   where text = 'Patient detail that must disappear.'),
  (select id from public.ticket_thread_entries where kind = 'question'),
  'It named a patient on the Calendar.');
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000256', true);
select public.request_ticket_diagnostic(
  (select id from tickets_256
   where text = 'Patient detail that must disappear.'));
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000256', true);
select public.respond_ticket_diagnostic(
  (select id from tickets_256
   where text = 'Patient detail that must disappear.'),
  (select id from public.ticket_thread_entries
   where kind = 'diagnostic_request'),
  '{"snapshot_version":1,"build":"256","time_zone":"America/New_York",'
    '"count.preceptors":1}'::jsonb);
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000256', true);
select public.close_ticket(
  (select id from tickets_256
   where text = 'Patient detail that must disappear.'),
  'done', 'The privacy change is live.');

select public.open_ticket_for_maintainer(
  (select id from tickets_256 where text = 'Keep this reopened Ticket.'));
select public.close_ticket(
  (select id from tickets_256 where text = 'Keep this reopened Ticket.'),
  'wont_do', 'This Ticket was closed once.');
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000256', true);
select public.reopen_ticket(
  (select id from tickets_256 where text = 'Keep this reopened Ticket.'),
  'The question came back.');
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000256', true);
select public.open_ticket_for_maintainer(
  (select id from tickets_256
   where text = 'Keep this until the full 90 days pass.'));
select public.close_ticket(
  (select id from tickets_256
   where text = 'Keep this until the full 90 days pass.'),
  'done', 'This Ticket has not reached retention yet.');

set local role postgres;
update public.tickets
set closed_at = clock_timestamp() - interval '90 days 1 minute'
where text = 'Patient detail that must disappear.';
update public.tickets
set closed_at = clock_timestamp() - interval '91 days',
  reopened_at = clock_timestamp() - interval '1 day'
where text = 'Keep this reopened Ticket.';
update public.tickets
set closed_at = clock_timestamp() - interval '89 days 23 hours 59 minutes'
where text = 'Keep this until the full 90 days pass.';
create temporary table expired_metadata_256 as
select kind, sender_id, state, screen_context, build_context,
  device_context, platform_context, context_captured_at, created_at,
  seen_at, close_reason, closed_at, question_count
from public.tickets
where id = (select id from tickets_256
  where text = 'Patient detail that must disappear.');

select is(public.erase_expired_ticket_text(), 1,
  'the scheduled operation erases one expired closed Ticket');
select is((select text from public.tickets
    where id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')),
  'Text erased 90 days after closing',
  'a Ticket closed more than 90 days ago no longer contains its text');
select is((select text_removal::text from public.tickets
    where id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')),
  'retention', 'the Ticket records retention as the removal reason');
select is((select count(*)::integer from public.ticket_thread_entries
    where ticket_id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')
      and text = 'Text erased 90 days after closing'), 2,
  'all free text in the Ticket thread is erased');
select is((select count(*)::integer from public.ticket_thread_entries
    where ticket_id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')
      and text is not null and text_removal = 'retention'), 2,
  'each erased thread message records the retention removal');
select is((select count(*)::integer from public.ticket_thread_entries
    where ticket_id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')
      and kind = 'diagnostic_attached'
      and diagnostic_snapshot is null), 1,
  'the attached diagnostic is erased with the Ticket text');
select is((select count(*)::integer from public.ticket_thread_entries
    where ticket_id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')
      and kind = 'diagnostic_attached'
      and text_removal = 'retention'), 1,
  'the erased diagnostic records the retention removal');
select is((select row(kind, sender_id, state, screen_context, build_context,
      device_context, platform_context, context_captured_at, created_at,
      seen_at, close_reason, closed_at, question_count)
    from public.tickets
    where id = (select id from tickets_256
      where text = 'Patient detail that must disappear.')),
  (select row(kind, sender_id, state, screen_context, build_context,
      device_context, platform_context, context_captured_at, created_at,
      seen_at, close_reason, closed_at, question_count)
    from expired_metadata_256),
  'erasure preserves the rest of the Ticket record');
select is((select text from public.tickets
    where id = (select id from tickets_256
      where text = 'Keep this open Ticket.')),
  'Keep this open Ticket.', 'an open Ticket is not erased');
select is((select text from public.tickets
    where id = (select id from tickets_256
      where text = 'Keep this reopened Ticket.')),
  'Keep this reopened Ticket.', 'a reopened Ticket is not erased');
select is((select text from public.tickets
    where id = (select id from tickets_256
      where text = 'Keep this until the full 90 days pass.')),
  'Keep this until the full 90 days pass.',
  'a closed Ticket remains intact immediately before 90 days');
select is(public.erase_expired_ticket_text(), 0,
  'the retention operation is safe to retry');
select ok(exists(select 1 from cron.job
    where jobname = 'erase-expired-ticket-text'),
  'pg_cron schedules Ticket text erasure');
select ok(not has_function_privilege(
    'authenticated', 'public.erase_expired_ticket_text()', 'EXECUTE'),
  'authenticated callers cannot run the retention job');
select ok(not has_function_privilege(
    'service_role', 'public.erase_expired_ticket_text()', 'EXECUTE'),
  'service-role callers cannot run the retention job');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000256', true);
select throws_ok(format('select public.redact_ticket_text(%L)',
  (select id from tickets_256 where text = 'Redact this Ticket now.')),
  '42501', 'Only the Maintainer can redact Ticket text',
  'the sender cannot redact Ticket text');
select set_config('request.jwt.claim.sub',
  '20000000-0000-4000-8000-000000000256', true);
select throws_ok(format('select public.redact_ticket_thread_entry(%L)',
  (select id from public.ticket_thread_entries where kind = 'question')),
  '42501', 'Only the Maintainer can redact Ticket thread content',
  'another Student cannot redact Ticket thread content');
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000256', true);
select lives_ok(format('select public.redact_ticket_text(%L)',
  (select id from tickets_256 where text = 'Redact this Ticket now.')),
  'the Maintainer can redact Ticket text at once');
select lives_ok(format('select public.redact_ticket_thread_entry(%L)',
  (select id from public.ticket_thread_entries where kind = 'question')),
  'the Maintainer can redact one thread entry at once');
select throws_ok($$select public.redact_ticket_text(
    'ffffffff-ffff-ffff-ffff-ffffffffffff')$$,
  'P2854', 'Ticket not found',
  'redacting requires an existing Ticket');
select throws_ok($$select public.redact_ticket_thread_entry(
    'ffffffff-ffff-ffff-ffff-ffffffffffff')$$,
  'P2867', 'Ticket thread entry not found',
  'redacting requires an existing thread entry');
select is((select text from public.tickets
    where id = (select id from tickets_256
      where text = 'Redact this Ticket now.')),
  'Text removed by the Maintainer',
  'redacted Ticket text uses the required replacement wording');
select is((select text_removal::text from public.tickets
    where id = (select id from tickets_256
      where text = 'Redact this Ticket now.')),
  'maintainer', 'redacted Ticket text records the Maintainer removal');
select is((select text from public.ticket_thread_entries
    where kind = 'question'),
  'Text removed by the Maintainer',
  'redacted thread text uses the required replacement wording');
select is((select text_removal::text from public.ticket_thread_entries
    where kind = 'question'),
  'maintainer', 'redacted thread text records the Maintainer removal');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '10000000-0000-4000-8000-000000000256', true);
select is((select text from public.tickets
    where id = (select id from tickets_256
      where text = 'Redact this Ticket now.')),
  'Text removed by the Maintainer',
  'the sender sees the Ticket replacement wording');
select is((select text from public.ticket_thread_entries
    where kind = 'question'),
  'Text removed by the Maintainer',
  'the sender sees the thread replacement wording');

select * from finish();
rollback;
