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
    required WebApplicationReloader reload,
  }) => WebBuildVersionCoordinator._(
    currentBuildNumber: currentBuildNumber,
    deployedBuildNumber: deployedBuildNumber,
    hasUnsentChanges: hasUnsentChanges,
    reload: reload,
  );

  WebBuildVersionCoordinator._({
    required this.currentBuildNumber,
    required this._deployedBuildNumber,
    required this._hasUnsentChanges,
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
  final WebApplicationReloader _reload;

  Future<void>? _activeCheck;
  bool _reloadStarted = false;

  Future<void> checkOnOpenOrResume() {
    if (_reloadStarted) return Future.value();
    return _activeCheck ??= _check().whenComplete(() => _activeCheck = null);
  }

  Future<void> _check() async {
    final deployedBuildNumber = await _deployedBuildNumber();
    if (deployedBuildNumber <= currentBuildNumber) return;
    if (await _hasUnsentChanges()) return;
    _reloadStarted = true;
    await _reload();
  }
}
