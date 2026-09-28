-- Ticket prose and diagnostics are temporary. The surrounding record remains
-- after private content is removed so status and audit history stay useful.
create type public.ticket_text_removal as enum ('maintainer', 'retention');

alter table public.tickets
  add column text_removal public.ticket_text_removal;
alter table public.ticket_thread_entries
  add column text_removal public.ticket_text_removal;

grant select (text_removal) on public.tickets,
  public.ticket_thread_entries to authenticated;

-- An erased diagnostic keeps its thread position and kind but no snapshot.
alter table public.ticket_thread_entries
  drop constraint ticket_thread_entry_shape,
  add constraint ticket_thread_entry_shape check (
    (kind = 'question' and author = 'maintainer'
      and text is not null and reply_to_id is null
      and diagnostic_snapshot is null)
    or (kind = 'answer' and author = 'sender'
      and text is not null and reply_to_id is not null
      and diagnostic_snapshot is null)
    or (kind = 'diagnostic_request' and author = 'maintainer'
      and text is null and reply_to_id is null
      and diagnostic_snapshot is null and text_removal is null)
    or (kind = 'diagnostic_attached' and author = 'sender'
      and text is null and reply_to_id is not null
      and (diagnostic_snapshot is not null or text_removal is not null))
    or (kind = 'diagnostic_declined' and author = 'sender'
      and text is null and reply_to_id is not null
      and diagnostic_snapshot is null and text_removal is null)
  );

create function public.erase_expired_ticket_text()
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket_ids uuid[];
begin
  select array_agg(ticket.id) into v_ticket_ids
  from public.tickets ticket
  where ticket.state in ('done', 'wont_do')
    and ticket.closed_at <= clock_timestamp() - interval '90 days'
    and (
      ticket.text_removal is distinct from 'retention'
      or exists (
        select 1
        from public.ticket_thread_entries entry
        where entry.ticket_id = ticket.id
          and (
            (entry.text is not null
              and entry.text_removal is distinct from 'retention')
            or entry.diagnostic_snapshot is not null
          )
      )
    );

  if v_ticket_ids is null then
    return 0;
  end if;

  update public.tickets
  set text = 'Text erased 90 days after closing',
    text_removal = 'retention'
  where id = any(v_ticket_ids);

  update public.ticket_thread_entries
  set text = case when text is null then null
      else 'Text erased 90 days after closing' end,
    diagnostic_snapshot = null,
    text_removal = 'retention'
  where ticket_id = any(v_ticket_ids)
    and (text is not null or diagnostic_snapshot is not null);

  return cardinality(v_ticket_ids);
end;
$$;
revoke all on function public.erase_expired_ticket_text()
  from public, anon, authenticated, service_role;

create function public.redact_ticket_text(p_ticket_id uuid)
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
      message = 'Only the Maintainer can redact Ticket text';
  end if;

  update public.tickets
  set text = 'Text removed by the Maintainer',
    text_removal = 'maintainer'
  where id = p_ticket_id
  returning * into v_ticket;
  if not found then
    raise exception using errcode = 'P2854', message = 'Ticket not found';
  end if;
  return v_ticket;
end;
$$;

create function public.redact_ticket_thread_entry(p_entry_id uuid)
returns public.ticket_thread_entries
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_entry public.ticket_thread_entries%rowtype;
begin
  if not public.has_ticket_maintainer_grant() then
    raise exception using errcode = '42501',
      message = 'Only the Maintainer can redact Ticket thread content';
  end if;

  update public.ticket_thread_entries
  set text = case when text is null then null
      else 'Text removed by the Maintainer' end,
    diagnostic_snapshot = null,
    text_removal = 'maintainer'
  where id = p_entry_id
    and (text is not null or diagnostic_snapshot is not null)
  returning * into v_entry;
  if not found then
    raise exception using errcode = 'P2867',
      message = 'Ticket thread entry not found';
  end if;
  return v_entry;
end;
$$;

revoke all on function public.redact_ticket_text(uuid),
  public.redact_ticket_thread_entry(uuid) from public;
grant execute on function public.redact_ticket_text(uuid),
  public.redact_ticket_thread_entry(uuid) to authenticated;

create extension if not exists pg_cron;
select cron.schedule(
  'erase-expired-ticket-text',
  '17 3 * * *',
  'select public.erase_expired_ticket_text()'
);
