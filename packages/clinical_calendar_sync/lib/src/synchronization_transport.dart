import 'package:clinical_calendar_application/clinical_calendar_application.dart';

final class SynchronizationPushResult {
  const SynchronizationPushResult._({
    required this.accepted,
    this.cursor,
    this.revision,
    this.rejectionCode,
    this.rejectionJson,
  });

  const SynchronizationPushResult.accepted({
    required int cursor,
    required int revision,
  }) : this._(accepted: true, cursor: cursor, revision: revision);

  const SynchronizationPushResult.rejected({
    required String code,
    required String rejectionJson,
  }) : this._(
         accepted: false,
         rejectionCode: code,
         rejectionJson: rejectionJson,
       );

  final bool accepted;
  final int? cursor;
  final int? revision;
  final String? rejectionCode;
  final String? rejectionJson;
}

abstract interface class SynchronizationTransport {
  Future<SynchronizationPushResult> push(OutboxOperation operation);

  Future<List<RemoteSynchronizationChange>> pull({
    required int afterCursor,
    required int limit,
  });
}

final class SynchronizationTransportException implements Exception {
  const SynchronizationTransportException(
    this.code, {
    required this.offline,
    this.cause,
  });

  final String code;
  final bool offline;
  final Object? cause;

  @override
  String toString() => 'SynchronizationTransportException($code)';
}

abstract interface class SynchronizationRetryScheduler {
  void schedule(DateTime atUtc, Future<void> Function() callback);

  void cancel();
}

enum SynchronizationBoundary {
  beforePush,
  afterPushBeforeLocalCommit,
  afterPushLocalCommit,
  beforePull,
  afterPullBeforeLocalCommit,
  afterPullLocalCommit,
}

abstract interface class SynchronizationBoundaryObserver {
  void reached(SynchronizationBoundary boundary);
}

final class NoopSynchronizationBoundaryObserver
    implements SynchronizationBoundaryObserver {
  const NoopSynchronizationBoundaryObserver();

  @override
  void reached(SynchronizationBoundary boundary) {}
}
