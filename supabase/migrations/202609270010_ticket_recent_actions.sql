alter table public.tickets
  add column recent_actions text[] not null
    default array['recent actions unavailable'],
  add column refusal_code text,
  add constraint ticket_recent_actions_content_free_shape check (
    cardinality(recent_actions) between 1 and 8
    and array_position(recent_actions, null) is null
    and char_length(recent_actions::text) <= 1600
  ),
  add constraint ticket_refusal_code_stable check (
    refusal_code is null or refusal_code ~ '^[a-z][a-z0-9_]{0,79}$'
  );

alter table public.tickets alter column recent_actions drop default;

grant select (recent_actions, refusal_code)
on public.tickets to authenticated;

drop function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz
);

create function public.put_in_ticket(
  p_kind text,
  p_text text,
  p_screen_context text,
  p_build_context text,
  p_device_context text,
  p_platform_context text,
  p_context_captured_at timestamptz,
  p_recent_actions text[],
  p_refusal_code text
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
      or p_context_captured_at is null
      or p_recent_actions is null
      or cardinality(p_recent_actions) not between 1 and 8
      or array_position(p_recent_actions, null) is not null
      or char_length(p_recent_actions::text) > 1600
      or (p_refusal_code is not null
        and p_refusal_code !~ '^[a-z][a-z0-9_]{0,79}$') then
    raise exception using errcode = 'P2853',
      message = 'Ticket context is incomplete';
  end if;

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
    device_context, platform_context, context_captured_at,
    recent_actions, refusal_code
  ) values (
    v_sender_id, p_kind, trim(p_text), trim(p_screen_context),
    trim(p_build_context), trim(p_device_context), trim(p_platform_context),
    p_context_captured_at, p_recent_actions, p_refusal_code
  ) returning id into v_ticket_id;
  return v_ticket_id;
end;
$$;

revoke all on function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz, text[], text
) from public;
grant execute on function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz, text[], text
) to authenticated;

-- Preserve the original RPC while deployed clients adopt richer context.
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
language sql
volatile
security definer
set search_path = ''
as $$
  select public.put_in_ticket(
    p_kind, p_text, p_screen_context, p_build_context,
    p_device_context, p_platform_context, p_context_captured_at,
    array['recent actions unavailable'], null
  )
$$;

revoke all on function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz
) from public;
grant execute on function public.put_in_ticket(
  text, text, text, text, text, text, timestamptz
) to authenticated;
