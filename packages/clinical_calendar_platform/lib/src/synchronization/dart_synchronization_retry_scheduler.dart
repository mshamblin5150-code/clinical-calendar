import 'dart:async';

import 'package:clinical_calendar_sync/synchronization.dart';

final class DartSynchronizationRetryScheduler
    implements SynchronizationRetryScheduler {
  Timer? _timer;

  @override
  void schedule(DateTime atUtc, Future<void> Function() callback) {
    if (!atUtc.isUtc) {
      throw ArgumentError.value(atUtc, 'atUtc', 'must be UTC');
    }
    cancel();
    final delay = atUtc.difference(DateTime.now().toUtc());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      unawaited(callback());
    });
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
