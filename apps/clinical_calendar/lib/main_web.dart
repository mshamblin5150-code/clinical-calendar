import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:flutter/material.dart';

import 'sync_build_number.dart';
import 'web_build_version_runtime.dart';

export 'sync_build_number.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(buildWebRoot());
}

Widget buildWebRoot({
  WebBuildVersionCoordinator? buildVersionCoordinator,
  UnsentChangesProbe hasUnsentChanges = _noUnsentChanges,
  Stream<void> unsentChangesDrained = const Stream<void>.empty(),
}) {
  final coordinator =
      buildVersionCoordinator ??
      createProductionWebBuildVersionCoordinator(
        currentBuildNumber: currentSyncBuildNumber,
        hasUnsentChanges: hasUnsentChanges,
        unsentChangesDrained: unsentChangesDrained,
      );
  return ClinicalCalendarLifecycleHost(
    onBuildVersionCheck: coordinator?.checkOnOpenOrResume,
    child: const _WebUnavailableApplication(),
  );
}

Future<bool> _noUnsentChanges() async => false;

final class _WebUnavailableApplication extends StatelessWidget {
  const _WebUnavailableApplication();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173A5E)),
    ),
    home: const Scaffold(
      key: Key('web-not-available'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Clinical Calendar', style: TextStyle(fontSize: 28)),
              SizedBox(height: 12),
              Text(
                'Web support is not available yet.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
