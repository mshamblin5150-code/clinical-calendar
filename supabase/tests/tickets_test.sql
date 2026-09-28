begin;
create extension if not exists pgtap with schema extensions;
select plan(34);

insert into auth.users(id, email) values
  ('00000000-0000-4000-8000-000000000251', 'maintainer-251@example.test'),
  ('00000000-0000-4000-8000-000000000252', 'sender-251@example.test'),
  ('00000000-0000-4000-8000-000000000253', 'other-251@example.test'),
  ('00000000-0000-4000-8000-000000000254', 'daily-251@example.test');

insert into clinical_calendar_tickets.maintainer_grants(auth_user_id)
values ('00000000-0000-4000-8000-000000000251');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000252', true);

select lives_ok($$select public.put_in_ticket(
  'problem', 'The Save button did not work.', 'Calendar', '0.1.0+46',
  'Surface Pro', 'windows', '2026-09-27 14:30:00+00')$$,
  'a signed-in Student can put in a Ticket');
select is((select state from public.tickets), 'sent',
  'a new Ticket is Sent');
select is((select build_context from public.tickets), '0.1.0+46',
  'the build is attached');
select is((select device_context from public.tickets), 'Surface Pro',
  'the device is attached');
select is((select platform_context from public.tickets), 'windows',
  'the platform is attached');
select is(
  public.put_in_ticket(
    'problem', '  The Save button did not work.  ', 'Calendar', '0.1.0+46',
    'Surface Pro', 'windows', '2026-09-27 14:31:00+00'),
  (select id from public.tickets),
  'an exact duplicate within five minutes returns the existing Ticket');
select is((select count(*)::integer from public.tickets), 1,
  'a duplicate is merged instead of stored twice');
select is((select count(public.put_in_ticket(
  'idea', 'Distinct Ticket ' || n::text, 'Calendar', '0.1.0+46',
  'Surface Pro', 'windows', clock_timestamp()))::integer
  from generate_series(1, 4) n), 4,
  'five distinct Tickets in an hour are accepted');
select throws_ok($$select public.put_in_ticket(
  'question', 'Sixth Ticket', 'Calendar', '0.1.0+46',
  'Surface Pro', 'windows', clock_timestamp())$$,
  'P2851', 'You have put in a lot of Tickets; the Maintainer will see them all',
  'the sixth Ticket in an hour is refused with a stable code');
select throws_ok($$insert into public.tickets(
  sender_id, kind, text, state, screen_context, build_context,
  device_context, platform_context, context_captured_at
) values (
  '00000000-0000-4000-8000-000000000252', 'problem', 'Bypass', 'sent',
  'Calendar', '0.1.0+46', 'Surface Pro', 'windows', clock_timestamp()
)$$, '42501', null, 'direct Ticket inserts are denied');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select is((select count(*)::integer from public.tickets), 0,
  'another Student cannot read the sender''s Tickets');
select ok(not has_table_privilege('anon', 'public.tickets', 'select'),
  'anonymous callers cannot read any Tickets');
select ok(not public.has_ticket_maintainer_grant(),
  'an ordinary Student has no Maintainer grant');

set local role postgres;
insert into public.tickets(
  sender_id, kind, text, state, screen_context, build_context,
  device_context, platform_context, context_captured_at, created_at,
  recent_actions
)
select '00000000-0000-4000-8000-000000000254', 'question',
  'Daily Ticket ' || n::text, 'sent', 'Calendar', '0.1.0+46',
  'Android tablet', 'android', clock_timestamp(),
  clock_timestamp() - n * interval '65 minutes',
  array['ticket test seed']
from generate_series(1, 20) n;
set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000254', true);
select throws_ok($$select public.put_in_ticket(
  'idea', 'Daily Ticket 21', 'Calendar', '0.1.0+46',
  'Android tablet', 'android', clock_timestamp())$$,
  'P2851', 'You have put in a lot of Tickets; the Maintainer will see them all',
  'the twenty-first Ticket in twenty-four hours is refused');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000251', true);
select ok(public.has_ticket_maintainer_grant(),
  'the Maintainer grant is visible through its narrow capability check');
select is((select count(*)::integer from public.tickets), 25,
  'the Maintainer reads every Ticket');
select ok(not has_table_privilege(
  'authenticated', 'clinical_calendar_sync.records', 'select'),
  'the Maintainer grant gives no direct sync-record access');
select lives_ok($$select public.open_ticket_for_maintainer(
  (select id from public.tickets
   where sender_id = '00000000-0000-4000-8000-000000000252'
   order by created_at limit 1))$$,
  'the Maintainer can open a Ticket');
select is((select state from public.tickets
  where sender_id = '00000000-0000-4000-8000-000000000252'
  order by created_at limit 1), 'seen',
  'opening a Sent Ticket marks it Seen');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000252', true);
select is((select state from public.tickets
  where text = 'The Save button did not work.'), 'seen',
  'the sender reads the Ticket as Seen');
select throws_ok($$select public.put_in_ticket(
  'problem', '   ', 'Calendar', '0.1.0+46',
  'Surface Pro', 'windows', clock_timestamp())$$,
  'P2852', 'Ticket text must be between 1 and 2000 characters',
  'blank Ticket text has a stable refusal code');
select throws_ok($$select public.close_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'done', 'This caller is not the Maintainer.')$$,
  '42501', 'Only the Maintainer can close Tickets',
  'an ordinary Student cannot close a Ticket');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000251', true);
select throws_ok($$select public.close_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'done', '   ')$$,
  'P2855', 'A closing reason is required',
  'the Maintainer must give the sender a closing reason');
select lives_ok($$select public.close_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'done', 'The fix is live on the web app.')$$,
  'the Maintainer closes a Ticket as Done');
select is((select state from public.tickets
  where text = 'The Save button did not work.'), 'done',
  'closing records the Done outcome');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000253', true);
select throws_ok($$select public.reopen_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'This Ticket does not belong to me.')$$,
  'P2858', 'This Ticket cannot be reopened',
  'another Student cannot reopen the sender''s Ticket');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000252', true);
select is((select close_reason from public.tickets
  where text = 'The Save button did not work.'),
  'The fix is live on the web app.',
  'the sender sees the closing reason');
select is((public.open_ticket_for_sender(
  (select id from public.tickets
   where text = 'The Save button did not work.')
  )->>'can_reopen')::boolean, true,
  'the sender receives the server reopening verdict');
select lives_ok($$select public.reopen_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'The same failure happened again.')$$,
  'the sender reopens a closed Ticket within 14 days');
select is((select state from public.tickets
  where text = 'The Save button did not work.'), 'seen',
  'reopening returns the Ticket to Seen');
select is((select reopen_note from public.tickets
  where text = 'The Save button did not work.'),
  'The same failure happened again.',
  'reopening records what happened again');

select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000251', true);
select lives_ok($$select public.close_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'wont_do', 'This change would make the calendar harder to read.')$$,
  'the Maintainer can close a reopened Ticket as Won''t do');
select is((select state from public.tickets
  where text = 'The Save button did not work.'), 'wont_do',
  'closing records the Won''t do outcome');

set local role postgres;
update public.tickets
set closed_at = clock_timestamp() - interval '14 days 1 second'
where text = 'The Save button did not work.';
set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000252', true);
select throws_ok($$select public.reopen_ticket(
  (select id from public.tickets
   where text = 'The Save button did not work.'),
  'It happened after the deadline.')$$,
  'P2859', 'This Ticket can no longer be reopened',
  'reopening is refused after 14 days');

select * from finish();
rollback;
