import 'dart:async';

import 'package:clinical_calendar_sync/synchronization.dart';
import 'package:test/test.dart';

void main() {
  test('newer web build reloads only after unsent changes drain', () async {
    var hasUnsentChanges = true;
    var reloads = 0;
    var versionChecks = 0;
    final drained = StreamController<void>.broadcast();
    final coordinator = WebBuildVersionCoordinator(
      currentBuildNumber: 46,
      deployedBuildNumber: () async {
        versionChecks++;
        return 47;
      },
      hasUnsentChanges: () async => hasUnsentChanges,
      unsentChangesDrained: drained.stream,
      reload: () async => reloads++,
    );

    await coordinator.checkOnOpenOrResume();
    expect(reloads, 0);

    hasUnsentChanges = false;
    drained.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(reloads, 1);

    await coordinator.checkOnOpenOrResume();
    expect(reloads, 1);
    expect(versionChecks, 1);
    await coordinator.dispose();
    await drained.close();
  });

  test('current web build stays open when nothing is unsent', () async {
    var reloads = 0;
    final coordinator = WebBuildVersionCoordinator(
      currentBuildNumber: 46,
      deployedBuildNumber: () async => 46,
      hasUnsentChanges: () async => false,
      unsentChangesDrained: const Stream.empty(),
      reload: () async => reloads++,
    );

    await coordinator.checkOnOpenOrResume();

    expect(reloads, 0);
    await coordinator.dispose();
  });
}
