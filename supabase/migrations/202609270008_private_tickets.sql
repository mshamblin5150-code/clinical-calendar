-- Tickets live beside, never inside, the Student synchronization record store.
-- The Maintainer grant is deliberately narrower than every calendar surface.
create schema if not exists clinical_calendar_tickets;
revoke all on schema clinical_calendar_tickets from public, anon, authenticated;

create table clinical_calendar_tickets.maintainer_grants (
  auth_user_id uuid primary key references auth.users(id) on delete cascade,
  granted_at timestamptz not null default clock_timestamp()
);
revoke all on clinical_calendar_tickets.maintainer_grants
  from public, anon, authenticated;

create function clinical_calendar_tickets.current_student_id()
returns uuid
language sql
stable
set search_path = ''
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), '')::uuid,
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid
  )
$$;
revoke all on function clinical_calendar_tickets.current_student_id()
  from public, anon, authenticated;
grant execute on function clinical_calendar_tickets.current_student_id()
  to authenticated;

create function public.has_ticket_maintainer_grant()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from clinical_calendar_tickets.maintainer_grants grant_row
    where grant_row.auth_user_id =
      clinical_calendar_tickets.current_student_id()
  )
$$;
revoke all on function public.has_ticket_maintainer_grant() from public;
grant execute on function public.has_ticket_maintainer_grant() to authenticated;

create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('problem', 'idea', 'question')),
  text text not null check (char_length(trim(text)) between 1 and 2000),
  state text not null default 'sent'
    check (state in ('sent', 'seen', 'waiting_on_sender', 'done', 'wont_do')),
  screen_context text not null
    check (char_length(trim(screen_context)) between 1 and 100),
  build_context text not null
    check (char_length(trim(build_context)) between 1 and 120),
  device_context text not null
    check (char_length(trim(device_context)) between 1 and 200),
  platform_context text not null
    check (char_length(trim(platform_context)) between 1 and 80),
  context_captured_at timestamptz not null,
  created_at timestamptz not null default clock_timestamp(),
  seen_at timestamptz,
  seen_by_auth_user_id uuid references auth.users(id),
  constraint ticket_seen_record check (
    (state = 'sent' and seen_at is null and seen_by_auth_user_id is null)
    or (state <> 'sent' and seen_at is not null
      and seen_by_auth_user_id is not null)
  )
);

create index tickets_by_sender
  on public.tickets(sender_id, created_at desc, id);
create index tickets_newest_first
  on public.tickets(created_at desc, id);

alter table public.tickets enable row level security;
revoke all on public.tickets from public, anon, authenticated;
grant select (
  id, sender_id, kind, text, state, screen_context, build_context,
  device_context, platform_context, context_captured_at, created_at, seen_at
) on public.tickets to authenticated;

create policy "Sender reads own Tickets"
on public.tickets for select to authenticated
using (
  sender_id = clinical_calendar_tickets.current_student_id()
);

create policy "Maintainer reads every Ticket"
on public.tickets for select to authenticated
using (public.has_ticket_maintainer_grant());

create function public.put_in_ticket(
  p_kind text,
  p_text text,
  p_screen_context text,
  p_build_context text,
  p_device_context text,
  p_platform_context text,
  p_context_captured_at timestamptz
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_sender_id uuid := clinical_calendar_tickets.current_student_id();
  v_ticket_id uuid;
  v_now timestamptz := clock_timestamp();
begin
  if v_sender_id is null then
    raise exception using errcode = '42501',
      message = 'A signed-in Student is required';
  end if;
  if p_text is null or char_length(trim(p_text)) not between 1 and 2000 then
    raise exception using errcode = 'P2852',
      message = 'Ticket text must be between 1 and 2000 characters';
  end if;
  if p_kind is null or p_kind not in ('problem', 'idea', 'question')
      or p_screen_context is null
      or char_length(trim(p_screen_context)) not between 1 and 100
      or p_build_context is null
      or char_length(trim(p_build_context)) not between 1 and 120
      or p_device_context is null
      or char_length(trim(p_device_context)) not between 1 and 200
      or p_platform_context is null
      or char_length(trim(p_platform_context)) not between 1 and 80
      or p_context_captured_at is null then
    raise exception using errcode = 'P2853',
      message = 'Ticket context is incomplete';
  end if;

  -- One lock per Student keeps duplicate merging and both bounds correct when
  -- a retry and a second tap arrive together.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_sender_id::text, 251)
  );

  select ticket.id into v_ticket_id
  from public.tickets ticket
  where ticket.sender_id = v_sender_id
    and ticket.kind = p_kind
    and ticket.text = trim(p_text)
    and ticket.created_at >= v_now - interval '5 minutes'
  order by ticket.created_at desc, ticket.id desc
  limit 1;
  if found then
    return v_ticket_id;
  end if;

  if (select count(*) from public.tickets ticket
      where ticket.sender_id = v_sender_id
        and ticket.created_at >= v_now - interval '1 hour') >= 5
    or (select count(*) from public.tickets ticket
      where ticket.sender_id = v_sender_id
        and ticket.created_at >= v_now - interval '24 hours') >= 20 then
    raise exception using errcode = 'P2851',
      message = 'You have put in a lot of Tickets; the Maintainer will see them all';
  end if;

  insert into public.tickets(
    sender_id, kind, text, screen_context, build_context,
    device_context, platform_context, context_captured_at
  ) values (
    v_sender_id, p_kind, trim(p_text), trim(p_screen_context),
    trim(p_build_context), trim(p_device_context), trim(p_platform_context),
    p_context_captured_at
  ) returning id into v_ticket_id;
  return v_ticket_id;
end;
$$;
revoke all on function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz
) from public;
grant execute on function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz
) to authenticated;

create function public.open_ticket_for_maintainer(p_ticket_id uuid)
returns public.tickets
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
begin
  if not public.has_ticket_maintainer_grant() then
    raise exception using errcode = '42501',
      message = 'Only the Maintainer can open Tickets';
  end if;

  update public.tickets
  set state = case when state = 'sent' then 'seen' else state end,
    seen_at = case when state = 'sent' then clock_timestamp() else seen_at end,
    seen_by_auth_user_id = case when state = 'sent'
      then clinical_calendar_tickets.current_student_id()
      else seen_by_auth_user_id end
  where id = p_ticket_id
  returning * into v_ticket;

  if not found then
    raise exception using errcode = 'P2854', message = 'Ticket not found';
  end if;
  return v_ticket;
end;
$$;
revoke all on function public.open_ticket_for_maintainer(uuid) from public;
grant execute on function public.open_ticket_for_maintainer(uuid)
  to authenticated;
