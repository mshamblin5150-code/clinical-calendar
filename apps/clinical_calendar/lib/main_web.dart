import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_sync/web_build_version.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'sync_build_number.dart';
import 'web_build_version_runtime.dart';
import 'web_device_descriptor.dart';

export 'sync_build_number.dart';

DeviceDescriptor currentWebDeviceDescriptor() =>
    webDeviceDescriptor(web.window.navigator.userAgent);

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
  return _BuildVersionLifecycle(
    onOpenOrResume: coordinator?.checkOnOpenOrResume,
    child: const _WebUnavailableApplication(),
  );
}

Future<bool> _noUnsentChanges() async => false;

final class _BuildVersionLifecycle extends StatefulWidget {
  const _BuildVersionLifecycle({required this.child, this.onOpenOrResume});

  final Widget child;
  final Future<void> Function()? onOpenOrResume;

  @override
  State<_BuildVersionLifecycle> createState() => _BuildVersionLifecycleState();
}

final class _BuildVersionLifecycleState extends State<_BuildVersionLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _check() {
    final callback = widget.onOpenOrResume;
    if (callback != null) {
      unawaited(callback().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
