/// Browser-safe capability adapters used by the web composition root.
library;

export 'src/foundation_platform_adapters.dart';
export 'src/exports/browser_file_downloader.dart';
export 'src/exports/dart_export_encoder.dart';
export 'src/exports/web_export_file_saver.dart';
export 'src/synchronization/dart_synchronization_retry_scheduler.dart';
export 'src/synchronization/supabase_rpc_synchronization_transport.dart';
export 'src/work_schedule_feeds/supabase_work_schedule_feed_relay_gateway.dart';
export 'src/tickets/supabase_ticket_gateway.dart';
