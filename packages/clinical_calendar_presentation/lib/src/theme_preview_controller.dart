import 'package:flutter/foundation.dart';

import 'theme_contract.dart';

@immutable
final class ThemeApplyRequest {
  const ThemeApplyRequest({
    required this.themeId,
    required this.expectedRevision,
  });

  final String themeId;
  final int expectedRevision;
}

/// Owns signed-in, process-local theme Preview state.
///
/// Persistence stays outside this controller so a candidate can never enter
/// synchronization, backup/restore, or export before Apply succeeds.
final class ThemePreviewController extends ChangeNotifier {
  ThemePreviewController({
    required ClinicalCalendarThemeBundleRegistry registry,
    required String authoritativeThemeId,
    required int initialRevision,
  }) : _registry = registry,
       _authoritativeThemeId = authoritativeThemeId,
       _authoritativeRevision = initialRevision,
       _authoritativeResolution = registry.resolveApplied(authoritativeThemeId);

  final ClinicalCalendarThemeBundleRegistry _registry;
  String _authoritativeThemeId;
  int _authoritativeRevision;
  late AppliedThemeResolution _authoritativeResolution;
  ClinicalCalendarThemeBundle? _previewBundle;
  String? _applyingThemeId;
  String? _applyError;
  bool _previewUnavailable = false;
  bool _preflighting = false;
  bool _authoritativeChangedDuringPreview = false;
  int _preflightGeneration = 0;

  String get authoritativeThemeId => _authoritativeThemeId;
  int get authoritativeRevision => _authoritativeRevision;
  AppliedThemeResolution get authoritativeResolution =>
      _authoritativeResolution;
  ClinicalCalendarThemeBundle get authoritativeBundle =>
      _authoritativeResolution.bundle;
  ClinicalCalendarThemeBundle get effectiveBundle =>
      _previewBundle ?? authoritativeBundle;
  ClinicalCalendarThemeBundle? get previewBundle => _previewBundle;
  bool get isPreviewing => _previewBundle != null;
  bool get isPreflighting => _preflighting;
  bool get isApplying => _applyingThemeId != null;
  bool get previewUnavailable => _previewUnavailable;
  bool get authoritativeChangedDuringPreview =>
      _authoritativeChangedDuringPreview;
  String? get applyError => _applyError;
  bool get canApply => isPreviewing && !isApplying && !_preflighting;

  Future<void> preview(
    String candidateId, {
    required Future<void> Function(ClinicalCalendarThemeBundle candidate)
    preflight,
  }) async {
    final generation = ++_preflightGeneration;
    final baseThemeId = _authoritativeThemeId;
    final baseRevision = _authoritativeRevision;
    _preflighting = true;
    _previewUnavailable = false;
    _applyError = null;
    notifyListeners();

    final result = await _registry.preflightCandidate(
      applied: _authoritativeResolution,
      candidateId: candidateId,
      preflight: preflight,
    );
    if (generation != _preflightGeneration) return;

    _preflighting = false;
    _previewUnavailable = result.previewUnavailable;
    _previewBundle = result.candidate;
    _applyingThemeId = null;
    _authoritativeChangedDuringPreview =
        _authoritativeThemeId != baseThemeId ||
        _authoritativeRevision != baseRevision;
    notifyListeners();
  }

  void revert() {
    if (isApplying) return;
    _preflightGeneration++;
    _previewBundle = null;
    _applyingThemeId = null;
    _applyError = null;
    _previewUnavailable = false;
    _preflighting = false;
    _authoritativeChangedDuringPreview = false;
    notifyListeners();
  }

  ThemeApplyRequest beginApply() {
    final preview = _previewBundle;
    if (preview == null || !canApply) {
      throw StateError('A successfully preflighted Preview is required.');
    }
    _applyingThemeId = preview.id;
    _applyError = null;
    notifyListeners();
    return ThemeApplyRequest(
      themeId: preview.id,
      expectedRevision: _authoritativeRevision,
    );
  }

  void completeApply({required int revision}) {
    final appliedId = _applyingThemeId;
    if (appliedId == null) {
      throw StateError('Apply has not started.');
    }
    _authoritativeThemeId = appliedId;
    _authoritativeRevision = revision;
    _authoritativeResolution = _registry.resolveApplied(appliedId);
    _previewBundle = null;
    _applyingThemeId = null;
    _applyError = null;
    _previewUnavailable = false;
    _authoritativeChangedDuringPreview = false;
    notifyListeners();
  }

  void failApply(String message) {
    if (_applyingThemeId == null && !isPreviewing) return;
    _applyingThemeId = null;
    _applyError = message;
    notifyListeners();
  }

  /// Removes a failed live bundle without changing the authoritative ID.
  ///
  /// A failed Preview returns to the valid applied bundle. A failed applied
  /// bundle resolves to complete Graphite while its stored ID remains intact.
  void handleRuntimeBundleFailure(String failedThemeId) {
    if (_previewBundle?.id == failedThemeId) {
      _preflightGeneration++;
      _previewBundle = null;
      _applyingThemeId = null;
      _applyError = null;
      _previewUnavailable = true;
      _preflighting = false;
      _authoritativeChangedDuringPreview = false;
      notifyListeners();
      return;
    }
    if (_authoritativeResolution.bundle.id != failedThemeId) return;
    _authoritativeResolution = AppliedThemeResolution(
      storedId: _authoritativeThemeId,
      bundle: _registry.resolveSignedOut(),
      isFallback: true,
    );
    _applyError = null;
    notifyListeners();
  }

  void updateAuthoritativeTheme({
    required String themeId,
    required int revision,
  }) {
    if (revision < _authoritativeRevision) return;
    final changed =
        themeId != _authoritativeThemeId || revision != _authoritativeRevision;
    if (!changed) return;

    _authoritativeThemeId = themeId;
    _authoritativeRevision = revision;
    _authoritativeResolution = _registry.resolveApplied(themeId);
    _applyError = null;
    if (isPreviewing) {
      _authoritativeChangedDuringPreview = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _preflightGeneration++;
    super.dispose();
  }
}
