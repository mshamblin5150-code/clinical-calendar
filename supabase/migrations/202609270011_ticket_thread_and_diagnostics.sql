-- A Ticket thread and its diagnostics remain private between the sender and
-- the Maintainer. Diagnostics accept only a fixed set of structural scalars.
alter table public.tickets
  add column question_count integer not null default 0
    check (question_count between 0 and 2);

grant select (question_count) on public.tickets to authenticated;

create type public.ticket_thread_author as enum ('maintainer', 'sender');
create type public.ticket_thread_entry_kind as enum (
  'question',
  'answer',
  'diagnostic_request',
  'diagnostic_attached',
  'diagnostic_declined'
);

create table public.ticket_thread_entries (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete cascade,
  author public.ticket_thread_author not null,
  kind public.ticket_thread_entry_kind not null,
  text text check (
    text is null or char_length(trim(text)) between 1 and 1000
  ),
  reply_to_id uuid references public.ticket_thread_entries(id),
  diagnostic_snapshot jsonb,
  created_at timestamptz not null default clock_timestamp(),
  constraint ticket_thread_entry_shape check (
    (kind = 'question' and author = 'maintainer'
      and text is not null and reply_to_id is null
      and diagnostic_snapshot is null)
    or (kind = 'answer' and author = 'sender'
      and text is not null and reply_to_id is not null
      and diagnostic_snapshot is null)
    or (kind = 'diagnostic_request' and author = 'maintainer'
      and text is null and reply_to_id is null
      and diagnostic_snapshot is null)
    or (kind = 'diagnostic_attached' and author = 'sender'
      and text is null and reply_to_id is not null
      and diagnostic_snapshot is not null)
    or (kind = 'diagnostic_declined' and author = 'sender'
      and text is null and reply_to_id is not null
      and diagnostic_snapshot is null)
  )
);

create index ticket_thread_in_order
  on public.ticket_thread_entries(ticket_id, created_at, id);

alter table public.ticket_thread_entries enable row level security;
revoke all on public.ticket_thread_entries from public, anon, authenticated;
grant select (
  id, ticket_id, author, kind, text, reply_to_id, diagnostic_snapshot,
  created_at
) on public.ticket_thread_entries to authenticated;

create policy "Sender reads own Ticket thread"
on public.ticket_thread_entries for select to authenticated
using (exists (
  select 1 from public.tickets ticket
  where ticket.id = ticket_id
    and ticket.sender_id = clinical_calendar_tickets.current_student_id()
));

create policy "Maintainer reads every Ticket thread"
on public.ticket_thread_entries for select to authenticated
using (public.has_ticket_maintainer_grant());

create function clinical_calendar_tickets.valid_diagnostic_snapshot(
  p_snapshot jsonb
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_snapshot is not null
    and pg_catalog.jsonb_typeof(p_snapshot) = 'object'
    and p_snapshot -> 'snapshot_version' = '1'::jsonb
    and pg_catalog.jsonb_typeof(p_snapshot -> 'build') = 'string'
    and char_length(trim(p_snapshot ->> 'build')) between 1 and 120
    and pg_catalog.jsonb_typeof(p_snapshot -> 'time_zone') = 'string'
    and char_length(trim(p_snapshot ->> 'time_zone')) between 1 and 120
    and not exists (
      select 1
      from pg_catalog.jsonb_each(p_snapshot) entry
      where entry.key <> all (array[
        'snapshot_version', 'build', 'time_zone',
        'count.work_shifts', 'count.clinical_sessions',
        'count.protected_days', 'count.schedule_templates',
        'count.preceptors', 'count.clinical_placements',
        'count.historical_hours_entries', 'count.evaluation_plans',
        'count.work_schedule_feeds', 'count.academic_assignments',
        'count.class_catalog_entries',
        'state.clinical_session.scheduled',
        'state.clinical_session.awaiting_confirmation',
        'state.clinical_session.completed',
        'state.clinical_session.cancelled',
        'state.clinical_session.missed',
        'state.clinical_placement.active',
        'state.clinical_placement.ready_to_complete',
        'state.clinical_placement.completed',
        'state.academic_assignment.pending',
        'state.academic_assignment.completed',
        'state.class_catalog_entry.active',
        'state.class_catalog_entry.archived',
        'state.work_schedule_feed.active',
        'state.work_schedule_feed.held',
        'number.work_shift_planned_minutes',
        'number.clinical_session_planned_minutes',
        'number.clinical_session_completed_minutes',
        'number.historical_completed_minutes',
        'number.clinical_placement_target_minutes',
        'setting.week_start', 'setting.time_display', 'setting.theme',
        'setting.enhanced_accessibility', 'setting.synchronization',
        'setting.notification.upcoming_work_shifts',
        'setting.notification.upcoming_clinical_sessions',
        'setting.notification.weekly_summary',
        'setting.notification.backup_reminders',
        'setting.notification.work_shift_first_lead_minutes',
        'setting.notification.work_shift_second_lead_minutes',
        'setting.notification.clinical_session_first_lead_minutes',
        'setting.notification.clinical_session_second_lead_minutes',
        'setting.notification.confirmation_first_delay_minutes',
        'setting.notification.confirmation_repeat_days',
        'setting.notification.evaluation_approaching_hours',
        'setting.notification.evaluation_repeat_days',
        'setting.notification.protected_day_first_lead_days',
        'setting.notification.protected_day_second_lead_days',
        'setting.notification.weekly_summary_weekday',
        'setting.notification.weekly_summary_hour',
        'setting.notification.weekly_summary_minute',
        'setting.notification.no_backup_reminder_days',
        'setting.notification.stale_backup_reminder_days'
      ]::text[])
      or case
        when entry.key = 'build' then
          pg_catalog.jsonb_typeof(entry.value) <> 'string'
          or (entry.value #>> '{}') !~ '^[A-Za-z0-9._+-]{1,120}$'
        when entry.key = 'time_zone' then
          pg_catalog.jsonb_typeof(entry.value) <> 'string'
          or (entry.value #>> '{}') !~
            '^(UTC[+-][0-9]{2}:[0-9]{2}|[A-Za-z0-9._+-]+(/[A-Za-z0-9._+-]+)*)$'
        when entry.key = 'setting.time_display' then
          entry.value #>> '{}' not in ('military', 'twelveHour')
        when entry.key = 'setting.theme' then
          pg_catalog.jsonb_typeof(entry.value) <> 'string'
          or (entry.value #>> '{}') !~ '^[a-z0-9][a-z0-9-]{0,79}$'
        when entry.key = 'setting.synchronization' then
          entry.value #>> '{}' not in ('enabled', 'paused')
        when entry.key in (
          'setting.enhanced_accessibility',
          'setting.notification.upcoming_work_shifts',
          'setting.notification.upcoming_clinical_sessions',
          'setting.notification.weekly_summary',
          'setting.notification.backup_reminders'
        ) then pg_catalog.jsonb_typeof(entry.value) <> 'boolean'
        else pg_catalog.jsonb_typeof(entry.value) <> 'number'
          or (entry.value #>> '{}') !~ '^[0-9]+$'
      end
    )
$$;
revoke all on function clinical_calendar_tickets.valid_diagnostic_snapshot(
  jsonb
) from public, anon, authenticated;

create function public.ask_ticket_question(
  p_ticket_id uuid,
  p_question text
)
returns public.tickets
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare v_ticket public.tickets%rowtype;
begin
  if not public.has_ticket_maintainer_grant() then
    raise exception using errcode = '42501',
      message = 'Only the Maintainer can ask Ticket questions';
  end if;
  if p_question is null
      or char_length(trim(p_question)) not between 1 and 1000 then
    raise exception using errcode = 'P2861',
      message = 'Ticket question text is invalid';
  end if;

  select * into v_ticket from public.tickets
  where id = p_ticket_id for update;
  if not found then
    raise exception using errcode = 'P2854', message = 'Ticket not found';
  end if;
  if v_ticket.state <> 'seen' then
    raise exception using errcode = 'P2862',
      message = 'This Ticket is not ready for another request';
  end if;
  if v_ticket.question_count >= 2 then
    raise exception using errcode = 'P2865',
      message = 'This Ticket has reached its question limit';
  end if;

  insert into public.ticket_thread_entries(
    ticket_id, author, kind, text
  ) values (p_ticket_id, 'maintainer', 'question', trim(p_question));
  update public.tickets
  set state = 'waiting_on_sender', question_count = question_count + 1
  where id = p_ticket_id returning * into v_ticket;
  return v_ticket;
end;
$$;
revoke all on function public.ask_ticket_question(uuid, text) from public;
grant execute on function public.ask_ticket_question(uuid, text)
  to authenticated;

create function public.answer_ticket_question(
  p_ticket_id uuid,
  p_question_id uuid,
  p_answer text
)
returns public.tickets
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
  v_latest public.ticket_thread_entries%rowtype;
begin
  select * into v_ticket from public.tickets
  where id = p_ticket_id for update;
  if not found or v_ticket.sender_id is distinct from
      clinical_calendar_tickets.current_student_id() then
    raise exception using errcode = '42501',
      message = 'Only the sender can answer this Ticket';
  end if;
  if v_ticket.state <> 'waiting_on_sender' then
    raise exception using errcode = 'P2864',
      message = 'This Ticket is not waiting for a response';
  end if;
  if p_answer is null
      or char_length(trim(p_answer)) not between 1 and 1000 then
    raise exception using errcode = 'P2863',
      message = 'Ticket answer text is invalid';
  end if;

  select * into v_latest from public.ticket_thread_entries
  where ticket_id = p_ticket_id
  order by created_at desc, id desc limit 1;
  if not found or v_latest.id is distinct from p_question_id
      or v_latest.kind <> 'question' then
    raise exception using errcode = 'P2864',
      message = 'This Ticket question is no longer waiting for an answer';
  end if;

  insert into public.ticket_thread_entries(
    ticket_id, author, kind, text, reply_to_id
  ) values (
    p_ticket_id, 'sender', 'answer', trim(p_answer), p_question_id
  );
  update public.tickets set state = 'seen'
  where id = p_ticket_id returning * into v_ticket;
  return v_ticket;
end;
$$;
revoke all on function public.answer_ticket_question(uuid, uuid, text)
  from public;
grant execute on function public.answer_ticket_question(uuid, uuid, text)
  to authenticated;

create function public.request_ticket_diagnostic(p_ticket_id uuid)
returns public.tickets
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare v_ticket public.tickets%rowtype;
begin
  if not public.has_ticket_maintainer_grant() then
    raise exception using errcode = '42501',
      message = 'Only the Maintainer can request a Ticket diagnostic';
  end if;
  select * into v_ticket from public.tickets
  where id = p_ticket_id for update;
  if not found then
    raise exception using errcode = 'P2854', message = 'Ticket not found';
  end if;
  if v_ticket.state <> 'seen' then
    raise exception using errcode = 'P2862',
      message = 'This Ticket is not ready for another request';
  end if;
  if v_ticket.question_count >= 2 then
    raise exception using errcode = 'P2865',
      message = 'This Ticket has reached its question limit';
  end if;

  insert into public.ticket_thread_entries(ticket_id, author, kind)
  values (p_ticket_id, 'maintainer', 'diagnostic_request');
  update public.tickets
  set state = 'waiting_on_sender', question_count = question_count + 1
  where id = p_ticket_id returning * into v_ticket;
  return v_ticket;
end;
$$;
revoke all on function public.request_ticket_diagnostic(uuid) from public;
grant execute on function public.request_ticket_diagnostic(uuid)
  to authenticated;

create function public.respond_ticket_diagnostic(
  p_ticket_id uuid,
  p_request_id uuid,
  p_snapshot jsonb
)
returns public.tickets
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
  v_latest public.ticket_thread_entries%rowtype;
begin
  select * into v_ticket from public.tickets
  where id = p_ticket_id for update;
  if not found or v_ticket.sender_id is distinct from
      clinical_calendar_tickets.current_student_id() then
    raise exception using errcode = '42501',
      message = 'Only the sender can respond to this diagnostic request';
  end if;
  if v_ticket.state <> 'waiting_on_sender' then
    raise exception using errcode = 'P2864',
      message = 'This Ticket is not waiting for a response';
  end if;
  select * into v_latest from public.ticket_thread_entries
  where ticket_id = p_ticket_id
  order by created_at desc, id desc limit 1;
  if not found or v_latest.id is distinct from p_request_id
      or v_latest.kind <> 'diagnostic_request' then
    raise exception using errcode = 'P2864',
      message = 'This diagnostic request is no longer waiting for a response';
  end if;
  if p_snapshot is not null and not
      clinical_calendar_tickets.valid_diagnostic_snapshot(p_snapshot) then
    raise exception using errcode = 'P2866',
      message = 'The diagnostic snapshot contains an unapproved value';
  end if;

  insert into public.ticket_thread_entries(
    ticket_id, author, kind, reply_to_id, diagnostic_snapshot
  ) values (
    p_ticket_id,
    'sender',
    case when p_snapshot is null
      then 'diagnostic_declined'::public.ticket_thread_entry_kind
      else 'diagnostic_attached'::public.ticket_thread_entry_kind end,
    p_request_id,
    p_snapshot
  );
  update public.tickets set state = 'seen'
  where id = p_ticket_id returning * into v_ticket;
  return v_ticket;
end;
$$;
revoke all on function public.respond_ticket_diagnostic(uuid, uuid, jsonb)
  from public;
grant execute on function public.respond_ticket_diagnostic(uuid, uuid, jsonb)
  to authenticated;
