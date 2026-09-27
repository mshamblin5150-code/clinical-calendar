import 'dart:async';

typedef DeployedBuildNumberLoader = Future<int> Function();
typedef UnsentChangesProbe = Future<bool> Function();
typedef WebApplicationReloader = Future<void> Function();

/// Coordinates the web lifecycle check without importing browser libraries.
///
/// The web composition supplies the deployed-build loader and hard reload
/// adapter. A newer deployment is never loaded over unsent in-memory changes.
final class WebBuildVersionCoordinator {
  factory WebBuildVersionCoordinator({
    required int currentBuildNumber,
    required DeployedBuildNumberLoader deployedBuildNumber,
    required UnsentChangesProbe hasUnsentChanges,
    required Stream<void> unsentChangesDrained,
    required WebApplicationReloader reload,
  }) => WebBuildVersionCoordinator._(
    currentBuildNumber: currentBuildNumber,
    deployedBuildNumber: deployedBuildNumber,
    hasUnsentChanges: hasUnsentChanges,
    unsentChangesDrained: unsentChangesDrained,
    reload: reload,
  );

  WebBuildVersionCoordinator._({
    required this.currentBuildNumber,
    required this._deployedBuildNumber,
    required this._hasUnsentChanges,
    required this._unsentChangesDrained,
    required this._reload,
  }) {
    if (currentBuildNumber <= 0) {
      throw ArgumentError.value(
        currentBuildNumber,
        'currentBuildNumber',
        'must be positive',
      );
    }
  }

  final int currentBuildNumber;
  final DeployedBuildNumberLoader _deployedBuildNumber;
  final UnsentChangesProbe _hasUnsentChanges;
  final Stream<void> _unsentChangesDrained;
  final WebApplicationReloader _reload;

  Future<void>? _activeCheck;
  StreamSubscription<void>? _drainSubscription;
  bool _newerBuildDetected = false;
  bool _reloadStarted = false;
  bool _disposed = false;

  Future<void> checkOnOpenOrResume() {
    if (_disposed || _reloadStarted) return Future.value();
    return _activeCheck ??= _check().whenComplete(() => _activeCheck = null);
  }

  Future<void> _check() async {
    if (!_newerBuildDetected) {
      final deployedBuildNumber = await _deployedBuildNumber();
      if (deployedBuildNumber <= currentBuildNumber) return;
      _newerBuildDetected = true;
    }
    if (await _hasUnsentChanges()) {
      _drainSubscription ??= _unsentChangesDrained.listen((_) {
        unawaited(checkOnOpenOrResume().catchError((Object _) {}));
      });
      return;
    }
    await _drainSubscription?.cancel();
    _drainSubscription = null;
    _reloadStarted = true;
    await _reload();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _drainSubscription?.cancel();
    _drainSubscription = null;
  }
}
