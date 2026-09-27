import 'package:clinical_calendar/main_web.dart' as web;
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('web startup fails closed until web storage is available', (
    tester,
  ) async {
    await tester.pumpWidget(web.buildWebRoot());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const Key('web-not-available')), findsOneWidget);
    expect(find.text('Clinical Calendar'), findsOneWidget);
    expect(find.text('Web support is not available yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web startup checks the deployed build on open', (tester) async {
    var deployedBuildChecks = 0;
    final coordinator = WebBuildVersionCoordinator(
      currentBuildNumber: web.currentSyncBuildNumber,
      deployedBuildNumber: () async {
        deployedBuildChecks++;
        return web.currentSyncBuildNumber;
      },
      hasUnsentChanges: () async => false,
      unsentChangesDrained: const Stream<void>.empty(),
      reload: () async {},
    );

    await tester.pumpWidget(
      web.buildWebRoot(buildVersionCoordinator: coordinator),
    );
    await tester.pump();

    expect(deployedBuildChecks, 1);
    await coordinator.dispose();
  });
}
