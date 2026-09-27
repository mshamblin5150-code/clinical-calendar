abstract interface class Clock {
  DateTime nowUtc();
}

abstract interface class IdentifierGenerator {
  String nextIdentifier();
}

enum SynchronizationDisposition { offline, synchronized, deferred }

abstract final class PublicSynchronizationFailureReference {
  static const pushRetryScheduled = 'push_retry_scheduled';
  static const pullTransportFailure = 'pull_transport_failure';
  static const conflictNeedsAttention = 'conflict_needs_attention';
  static const terminalRejection = 'terminal_rejection';
  static const minimumSyncBuildRequired = 'minimum_sync_build_required';
  static const pendingAfterCycle = 'pending_after_cycle';
  static const cursorOrPayloadFailure = 'cursor_or_payload_failure';
  static const cursorOrPayloadNotFound = 'cursor_or_payload_not_found';
  static const cursorOrPayloadOwnershipMismatch =
      'cursor_or_payload_ownership_mismatch';
  static const cursorOrPayloadConcurrentModification =
      'cursor_or_payload_concurrent_modification';
  static const cursorOrPayloadIdempotencyConflict =
      'cursor_or_payload_idempotency_conflict';
  static const cursorOrPayloadCorruptData = 'cursor_or_payload_corrupt_data';
  static const cursorOrPayloadPersistenceFailure =
      'cursor_or_payload_persistence_failure';
  static const cursorOrPayloadClosed = 'cursor_or_payload_closed';
  static const cursorOrPayloadUninitialized = 'cursor_or_payload_uninitialized';

  static const values = {
    pushRetryScheduled,
    pullTransportFailure,
    conflictNeedsAttention,
    terminalRejection,
    minimumSyncBuildRequired,
    pendingAfterCycle,
    cursorOrPayloadFailure,
    cursorOrPayloadNotFound,
    cursorOrPayloadOwnershipMismatch,
    cursorOrPayloadConcurrentModification,
    cursorOrPayloadIdempotencyConflict,
    cursorOrPayloadCorruptData,
    cursorOrPayloadPersistenceFailure,
    cursorOrPayloadClosed,
    cursorOrPayloadUninitialized,
    'failed',
    'incomplete_aggregate_batch',
    'invalid_pull_response',
    'invalid_push_response',
    'invalid_request',
    'invalid_rpc_response',
    'network_unavailable',
    'rate_limited',
    'retry_deferred',
    'server_unavailable',
    'unauthenticated',
  };
}

final class SynchronizationResult {
  const SynchronizationResult(this.disposition, {this.detail});

  final SynchronizationDisposition disposition;
  final String? detail;
}

abstract interface class SynchronizationService {
  Future<SynchronizationResult> synchronize();
}

abstract interface class NotificationService {
  Future<void> reconcileScheduledNotifications();
}

abstract interface class SecureStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract interface class FileService {
  Future<List<int>> read(Uri location);

  Future<void> write(Uri location, List<int> bytes);
}

/// Authenticated delivery boundary for a Student-owned Work Schedule Feed.
///
/// The gateway stages a credential under the generated feed identity before a
/// first preview, so the relay never accepts an arbitrary URL. A rejected or
/// cancelled preview is discarded; a confirmed feed keeps the staged row.
abstract interface class WorkScheduleFeedRelayGateway {
  Future<String> stageAndFetch({required String feedId, required Uri url});

  Future<String> fetch({required String feedId});

  Future<void> discard({required String feedId});
}

final class WorkScheduleFeedRelayException implements Exception {
  const WorkScheduleFeedRelayException(this.code);

  final String code;

  @override
  String toString() => 'WorkScheduleFeedRelayException: $code';
}
