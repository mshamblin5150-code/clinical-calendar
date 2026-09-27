begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users(id, email) values
  ('00000000-0000-4000-8000-000000000255', 'sender-255@example.test');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000255', true);

select lives_ok($$select public.put_in_ticket(
  'problem', 'The refusal looked wrong.', 'Calendar', '0.1.0+47',
  'Surface Pro', 'windows', '2026-09-27 18:30:00+00',
  array['opened Work Shift editor', 'tapped Save',
    'refused: schedule_conflict'],
  'schedule_conflict')$$,
  'a Ticket accepts bounded content-free actions and a stable refusal code');
select is((select recent_actions from public.tickets),
  array['opened Work Shift editor', 'tapped Save',
    'refused: schedule_conflict'],
  'recent actions are stored in order');
select is((select refusal_code from public.tickets), 'schedule_conflict',
  'the refusal code is attached');
select throws_ok($$select public.put_in_ticket(
  'problem', 'Missing actions.', 'Calendar', '0.1.0+47',
  'Surface Pro', 'windows', clock_timestamp(), array[]::text[], null)$$,
  'P2853', 'Ticket context is incomplete',
  'an empty recent-action trail is refused');
select throws_ok($$select public.put_in_ticket(
  'problem', 'Unstable code.', 'Calendar', '0.1.0+47',
  'Surface Pro', 'windows', clock_timestamp(), array['tapped Save'],
  'Patient Jane Doe')$$,
  'P2853', 'Ticket context is incomplete',
  'a refusal code cannot carry entered prose');
select throws_ok($$select public.put_in_ticket(
  'problem', 'Long action.', 'Calendar', '0.1.0+47',
  'Surface Pro', 'windows', clock_timestamp(),
  array[repeat('x', 1601)], null)$$,
  'P2853', 'Ticket context is incomplete',
  'recent actions cannot exceed the diagnostic bound');

select * from finish();
rollback;
