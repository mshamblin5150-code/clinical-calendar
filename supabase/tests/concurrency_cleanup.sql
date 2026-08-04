-- Removes the disposable concurrency fixture through the auth ownership root.
delete from clinical_calendar_sync.change_feed
where student_id = '10000000-0000-4000-8000-000000000001';
delete from clinical_calendar_sync.operation_receipts
where student_id = '10000000-0000-4000-8000-000000000001';
delete from clinical_calendar_sync.records
where student_id = '10000000-0000-4000-8000-000000000001';
delete from clinical_calendar_sync.feed_heads
where student_id = '10000000-0000-4000-8000-000000000001';
delete from auth.users
where id = '10000000-0000-4000-8000-000000000001';
