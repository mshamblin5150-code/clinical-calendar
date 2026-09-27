-- Stage a Student-owned credential for the authenticated relay without
-- accepting an arbitrary URL at the Edge Function boundary.

create function public.stage_work_schedule_feed_preview(
  p_feed_id uuid,
  p_url text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_student_id uuid := clinical_calendar_sync.current_student_id();
begin
  if p_url is null
     or length(p_url) not between 1 and 4096
     or p_url !~* '^(https|webcal)://' then
    raise exception using errcode = 'P2840', message = 'invalid_feed_url';
  end if;

  if exists (
    select 1
    from clinical_calendar_sync.work_schedule_feeds feed
    where feed.feed_id = p_feed_id
      and feed.student_id <> v_student_id
  ) then
    raise exception using errcode = 'P2841', message = 'feed_not_owned';
  end if;

  insert into clinical_calendar_sync.work_schedule_feeds (
    feed_id, student_id, url
  ) values (
    p_feed_id, v_student_id, p_url
  )
  on conflict (feed_id) do update
  set url = excluded.url,
      updated_at_utc = clock_timestamp()
  where clinical_calendar_sync.work_schedule_feeds.student_id = v_student_id;
end
$$;

create function public.discard_work_schedule_feed(p_feed_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from clinical_calendar_sync.work_schedule_feeds
  where feed_id = p_feed_id
    and student_id = clinical_calendar_sync.current_student_id();
$$;

revoke all on function public.stage_work_schedule_feed_preview(uuid, text)
  from public, anon;
grant execute on function public.stage_work_schedule_feed_preview(uuid, text)
  to authenticated;
revoke all on function public.discard_work_schedule_feed(uuid)
  from public, anon;
grant execute on function public.discard_work_schedule_feed(uuid)
  to authenticated;
