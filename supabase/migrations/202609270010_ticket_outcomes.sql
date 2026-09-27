-- A Maintainer closes a Ticket with a reason; its sender may reopen for 14 days.
alter table public.tickets
  add column close_reason text,
  add column closed_at timestamptz,
  add column closed_by_auth_user_id uuid references auth.users(id),
  add column reopened_at timestamptz,
  add column reopen_note text,
  add constraint ticket_close_record check (
    (close_reason is null and closed_at is null
      and closed_by_auth_user_id is null)
    or (char_length(trim(close_reason)) between 1 and 1000
      and closed_at is not null and closed_by_auth_user_id is not null)
  ),
  add constraint ticket_closed_state_has_record check (
    state not in ('done', 'wont_do') or closed_at is not null
  ),
  add constraint ticket_prior_close_is_reopened check (
    closed_at is null or state in ('done', 'wont_do')
      or (state = 'seen' and reopened_at is not null)
  ),
  add constraint ticket_reopen_record check (
    (reopened_at is null and reopen_note is null)
    or (reopened_at is not null
      and char_length(trim(reopen_note)) between 1 and 500)
  );

grant select (close_reason, closed_at, reopened_at, reopen_note)
  on public.tickets to authenticated;

create function clinical_calendar_tickets.sender_ticket(
  p_ticket public.tickets
)
returns jsonb
language sql
volatile
set search_path = ''
as $$
  select to_jsonb(p_ticket)
    - 'seen_by_auth_user_id'
    - 'closed_by_auth_user_id'
    || jsonb_build_object(
      'can_reopen', p_ticket.state in ('done', 'wont_do')
        and p_ticket.closed_at is not null
        and clock_timestamp() <= p_ticket.closed_at + interval '14 days',
      'reopen_until', case when p_ticket.closed_at is null then null
        else p_ticket.closed_at + interval '14 days' end
    )
$$;
revoke all on function clinical_calendar_tickets.sender_ticket(public.tickets)
  from public, anon, authenticated;

create function public.open_ticket_for_sender(p_ticket_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
begin
  select * into v_ticket
  from public.tickets
  where id = p_ticket_id
    and sender_id = clinical_calendar_tickets.current_student_id();
  if not found then
    raise exception using errcode = 'P2860', message = 'Ticket not found';
  end if;
  return clinical_calendar_tickets.sender_ticket(v_ticket);
end;
$$;

create function public.close_ticket(
  p_ticket_id uuid,
  p_outcome text,
  p_reason text
)
returns public.tickets
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
  v_maintainer_id uuid := clinical_calendar_tickets.current_student_id();
begin
  if not public.has_ticket_maintainer_grant() then
    raise exception using errcode = '42501',
      message = 'Only the Maintainer can close Tickets';
  end if;
  if p_reason is null or char_length(trim(p_reason)) not between 1 and 1000 then
    raise exception using errcode = 'P2855',
      message = 'A closing reason is required';
  end if;
  if p_outcome is null or p_outcome not in ('done', 'wont_do') then
    raise exception using errcode = 'P2856',
      message = 'Close a Ticket as Done or Won''t do';
  end if;

  update public.tickets
  set state = p_outcome,
    seen_at = coalesce(seen_at, clock_timestamp()),
    seen_by_auth_user_id = coalesce(seen_by_auth_user_id, v_maintainer_id),
    close_reason = trim(p_reason),
    closed_at = clock_timestamp(),
    closed_by_auth_user_id = v_maintainer_id
  where id = p_ticket_id
    and state not in ('done', 'wont_do')
  returning * into v_ticket;

  if not found then
    raise exception using errcode = 'P2856',
      message = 'This Ticket cannot be closed';
  end if;
  return v_ticket;
end;
$$;

create function public.reopen_ticket(p_ticket_id uuid, p_note text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
begin
  if p_note is null or char_length(trim(p_note)) not between 1 and 500 then
    raise exception using errcode = 'P2857',
      message = 'A reopening note is required';
  end if;

  select * into v_ticket
  from public.tickets
  where id = p_ticket_id
    and sender_id = clinical_calendar_tickets.current_student_id();
  if not found or v_ticket.state not in ('done', 'wont_do')
      or v_ticket.closed_at is null then
    raise exception using errcode = 'P2858',
      message = 'This Ticket cannot be reopened';
  end if;
  if clock_timestamp() > v_ticket.closed_at + interval '14 days' then
    raise exception using errcode = 'P2859',
      message = 'This Ticket can no longer be reopened';
  end if;

  update public.tickets
  set state = 'seen',
    reopened_at = clock_timestamp(),
    reopen_note = trim(p_note)
  where id = p_ticket_id
  returning * into v_ticket;
  return clinical_calendar_tickets.sender_ticket(v_ticket);
end;
$$;

revoke all on function public.close_ticket(uuid, text, text),
  public.reopen_ticket(uuid, text),
  public.open_ticket_for_sender(uuid) from public;
grant execute on function public.close_ticket(uuid, text, text),
  public.reopen_ticket(uuid, text),
  public.open_ticket_for_sender(uuid) to authenticated;
