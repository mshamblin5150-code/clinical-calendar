import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_platform/clinical_calendar_web_identity_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_identity_presentation.dart';
import 'package:clinical_calendar_sync/web_build_version.dart';
import 'package:flutter/material.dart';

import 'config/app_environment.dart';
import 'sync_build_number.dart';
import 'web_build_version_runtime.dart';
import 'web_device_descriptor.dart';
import 'web_identity_runtime.dart';

export 'sync_build_number.dart';

DeviceDescriptor currentWebDeviceDescriptor() =>
    webDeviceDescriptor(currentBrowserUserAgent());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(buildWebRoot());
}

Widget buildWebRoot({
  WebBuildVersionCoordinator? buildVersionCoordinator,
  UnsentChangesProbe hasUnsentChanges = _noUnsentChanges,
  Stream<void> unsentChangesDrained = const Stream<void>.empty(),
  AppEnvironment? environment,
  SecureStorage? secureStorage,
  IdentifierGenerator? identifiers,
  Clock? clock,
  PasswordlessIdentityGateway? identityGateway,
  DeviceDescriptor? currentDevice,
  LocalDeviceCopyController? localCopy,
}) {
  final coordinator =
      buildVersionCoordinator ??
      createProductionWebBuildVersionCoordinator(
        currentBuildNumber: currentSyncBuildNumber,
        hasUnsentChanges: hasUnsentChanges,
        unsentChangesDrained: unsentChangesDrained,
      );
  final configuredEnvironment = environment ?? AppEnvironment.fromCompileTime();
  final Widget content;
  if (!configuredEnvironment.hasSynchronizationConfiguration) {
    content = const _WebUnavailableApplication();
  } else {
    final identity = PasswordlessIdentityService(
      gateway:
          identityGateway ??
          SupabasePasswordlessIdentityGateway(
            projectUri: configuredEnvironment.synchronizationProjectUri!,
            publishableKey: configuredEnvironment.supabasePublishableKey,
          ),
      secureStorage: secureStorage ?? createWebIdentityStorage(),
      identifiers: identifiers ?? ProcessIdentifierGenerator(),
      clock: clock ?? const SystemClock(),
      currentDevice: currentDevice ?? currentWebDeviceDescriptor(),
      localCopy: localCopy ?? const _WebLocalDeviceCopyController(),
    );
    content = _WebIdentityApplication(identity: identity);
  }
  return _BuildVersionLifecycle(
    onOpenOrResume: coordinator?.checkOnOpenOrResume,
    child: content,
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

final class _WebIdentityApplication extends StatefulWidget {
  const _WebIdentityApplication({required this.identity});

  final PasswordlessIdentityService identity;

  @override
  State<_WebIdentityApplication> createState() =>
      _WebIdentityApplicationState();
}

final class _WebIdentityApplicationState
    extends State<_WebIdentityApplication> {
  IdentitySession? _session;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final session = await widget.identity.restoreForOfflineLaunch();
    if (!mounted) return;
    setState(() {
      _session = session;
      _restoring = false;
    });
  }

  Widget _home() {
    if (_restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = _session;
    if (session == null) {
      return PasswordlessSignInSurface(
        identity: widget.identity,
        onSignedIn: (session) async {
          if (mounted) setState(() => _session = session);
        },
      );
    }
    return Scaffold(
      body: IdentityDevicesSurface(
        identity: widget.identity,
        email: session.email,
        onLocalCopyRemoved: () async {
          if (mounted) setState(() => _session = null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173A5E)),
    ),
    home: _home(),
  );
}

final class _WebLocalDeviceCopyController implements LocalDeviceCopyController {
  const _WebLocalDeviceCopyController();

  @override
  Future<LocalRemovalPreview> previewRemoval() async =>
      const LocalRemovalPreview(pendingChangeCount: 0);

  @override
  Future<void> removeLocalCopy() async {}
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
