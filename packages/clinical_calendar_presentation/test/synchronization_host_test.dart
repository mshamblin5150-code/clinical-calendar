import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('host forwards launch, resume, and connectivity transitions', (
    tester,
  ) async {
    final connectivity = StreamController<bool>.broadcast();
    var launchOrResumeCalls = 0;
    var buildVersionChecks = 0;
    final connectivityValues = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicalCalendarLifecycleHost(
          onLaunchOrResume: () async => launchOrResumeCalls++,
          onBuildVersionCheck: () async => buildVersionChecks++,
          connectivityChanges: connectivity.stream,
          onConnectivityChanged: (connected) async {
            connectivityValues.add(connected);
          },
          child: const SizedBox(key: Key('application-child')),
        ),
      ),
    );
    await tester.pump();
    expect(launchOrResumeCalls, 1);
    expect(buildVersionChecks, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(launchOrResumeCalls, 2);
    expect(buildVersionChecks, 2);

    connectivity.add(false);
    connectivity.add(true);
    await tester.pump();
    expect(connectivityValues, [false, true]);
    expect(find.byKey(const Key('application-child')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    connectivity.add(false);
    await tester.pump();
    expect(connectivityValues, [false, true]);
    await connectivity.close();
  });

  testWidgets('host shows the minimum sync build update banner while held', (
    tester,
  ) async {
    final heldChanges = StreamController<bool>.broadcast();

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicalCalendarLifecycleHost(
          minimumSyncBuildRequiredChanges: heldChanges.stream,
          child: const SizedBox(key: Key('application-child')),
        ),
      ),
    );
    expect(
      find.text(
        'Update this app to keep syncing – '
        'your changes are safe on this device.',
      ),
      findsNothing,
    );

    heldChanges.add(true);
    await tester.pump();

    expect(
      find.text(
        'Update this app to keep syncing – '
        'your changes are safe on this device.',
      ),
      findsOneWidget,
    );

    heldChanges.add(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('minimum-sync-build-banner')), findsNothing);
    await heldChanges.close();
  });

  testWidgets('failed web build check does not suppress synchronization', (
    tester,
  ) async {
    var launchOrResumeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicalCalendarLifecycleHost(
          onBuildVersionCheck: () async => throw StateError('offline'),
          onLaunchOrResume: () async => launchOrResumeCalls++,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();

    expect(launchOrResumeCalls, 1);
  });

  testWidgets('Sync Now reports successful and offline outcomes', (
    tester,
  ) async {
    final synchronization = _SynchronizationService(
      const SynchronizationResult(SynchronizationDisposition.synchronized),
    );
    await _pumpSynchronization(tester, synchronization);

    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();
    expect(synchronization.calls, 1);
    expect(find.text('Synchronization complete.'), findsOneWidget);

    synchronization.result = const SynchronizationResult(
      SynchronizationDisposition.offline,
    );
    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();
    expect(synchronization.calls, 2);
    expect(
      find.text('Synchronization is offline. Local changes remain queued.'),
      findsOneWidget,
    );
  });

  testWidgets('Sync Now sanitizes unexpected failures', (tester) async {
    final synchronization = _SynchronizationService(
      const SynchronizationResult(SynchronizationDisposition.deferred),
    )..failure = StateError('access-token-secret');
    await _pumpSynchronization(tester, synchronization);

    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Synchronization could not complete. Local changes remain queued.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('access-token-secret'), findsNothing);
  });

  testWidgets('Sync Now exposes only a safe deferred failure reference', (
    tester,
  ) async {
    final synchronization = _SynchronizationService(
      const SynchronizationResult(
        SynchronizationDisposition.deferred,
        detail: 'invalid_request',
      ),
    );
    await _pumpSynchronization(tester, synchronization);

    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Reference: invalid_request.'), findsOneWidget);

    synchronization.result = const SynchronizationResult(
      SynchronizationDisposition.deferred,
      detail: 'push_retry_scheduled',
    );
    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Reference: push_retry_scheduled.'),
      findsOneWidget,
    );

    synchronization.result = const SynchronizationResult(
      SynchronizationDisposition.deferred,
      detail: 'cursor_or_payload_persistence_failure',
    );
    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Reference: cursor_or_payload_persistence_failure.'),
      findsOneWidget,
    );

    synchronization.result = const SynchronizationResult(
      SynchronizationDisposition.deferred,
      detail: 'access_token_secret',
    );
    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();

    expect(find.textContaining('access_token_secret'), findsNothing);
  });
}

Future<void> _pumpSynchronization(
  WidgetTester tester,
  SynchronizationService synchronization,
) => tester.pumpWidget(
  MaterialApp(
    theme: buildVariantFTheme(),
    home: Scaffold(
      body: SynchronizationAttentionSurface(synchronization: synchronization),
    ),
  ),
);

final class _SynchronizationService implements SynchronizationService {
  _SynchronizationService(this.result);

  SynchronizationResult result;
  Object? failure;
  int calls = 0;

  @override
  Future<SynchronizationResult> synchronize() async {
    calls++;
    final error = failure;
    if (error != null) throw error;
    return result;
  }
}
