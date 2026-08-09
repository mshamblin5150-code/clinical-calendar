import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:clinical_calendar_presentation/src/accessibility_tokens.dart';
import 'package:clinical_calendar_presentation/src/theme_contract.dart';
import 'package:clinical_calendar_presentation/src/variant_f_theme.dart';

abstract final class ThemeAcceptanceGateId {
  static const runtimeTokens = 'runtime-tokens';
  static const registryOwnership = 'registry-ownership';
  static const assetGeometryOriginality = 'asset-geometry-originality';
  static const thumbnailProvenance = 'thumbnail-provenance';
  static const containmentDroneEquality = 'containment-drone-equality';
  static const switchingState = 'switching-state';
  static const persistence = 'persistence';
  static const fallbackPrivacy = 'fallback-privacy';
  static const help = 'help';
  static const accessibility = 'accessibility';
  static const performance = 'performance';
  static const physicalAndroidVisual = 'physical-android-visual';
}

const themeAcceptanceGateIds = <String>[
  ThemeAcceptanceGateId.runtimeTokens,
  ThemeAcceptanceGateId.registryOwnership,
  ThemeAcceptanceGateId.assetGeometryOriginality,
  ThemeAcceptanceGateId.thumbnailProvenance,
  ThemeAcceptanceGateId.containmentDroneEquality,
  ThemeAcceptanceGateId.switchingState,
  ThemeAcceptanceGateId.persistence,
  ThemeAcceptanceGateId.fallbackPrivacy,
  ThemeAcceptanceGateId.help,
  ThemeAcceptanceGateId.accessibility,
  ThemeAcceptanceGateId.performance,
  ThemeAcceptanceGateId.physicalAndroidVisual,
];

enum ThemeAcceptanceState { pending, accepted }

enum ThemeAccessibilityMode { standard, enhanced }

enum ThemeContrastContentKind {
  normalText,
  largeText,
  graphic,
  inactiveControl,
}

enum ThemeTokenState {
  defaultState,
  selected,
  focused,
  pressed,
  disabled,
  warning,
  error,
  inverse,
}

List<ThemeTokenPairing> _runtimePermittedPairings({
  required ThemeData theme,
  required ClinicalCalendarColors colors,
  required ClinicalCalendarAccessibilityTokens? accessibility,
}) {
  final scheme = theme.colorScheme;
  final pairings = <ThemeTokenPairing>[];
  const stateSpecs = <(String, ThemeTokenState, Set<WidgetState>)>[
    ('default', ThemeTokenState.defaultState, {}),
    ('selected', ThemeTokenState.selected, {WidgetState.selected}),
    ('focused', ThemeTokenState.focused, {WidgetState.focused}),
    ('pressed', ThemeTokenState.pressed, {WidgetState.pressed}),
    ('disabled', ThemeTokenState.disabled, {WidgetState.disabled}),
    (
      'selected-focused',
      ThemeTokenState.focused,
      {WidgetState.selected, WidgetState.focused},
    ),
    (
      'pressed-focused',
      ThemeTokenState.pressed,
      {WidgetState.pressed, WidgetState.focused},
    ),
    (
      'disabled-selected',
      ThemeTokenState.disabled,
      {WidgetState.disabled, WidgetState.selected},
    ),
  ];
  final componentStyles = <(String, ButtonStyle?, Color, Color)>[
    ('filled', theme.filledButtonTheme.style, scheme.onPrimary, scheme.primary),
    (
      'outlined',
      theme.outlinedButtonTheme.style,
      scheme.onSurface,
      Colors.transparent,
    ),
    ('text', theme.textButtonTheme.style, scheme.primary, Colors.transparent),
    ('icon', theme.iconButtonTheme.style, scheme.onSurface, Colors.transparent),
    (
      'segmented',
      theme.segmentedButtonTheme.style,
      scheme.onSurface,
      Colors.transparent,
    ),
  ];
  for (final component in componentStyles) {
    for (final state in stateSpecs) {
      final foreground =
          component.$2?.foregroundColor?.resolve(state.$3) ??
          (state.$3.contains(WidgetState.disabled)
              ? theme.disabledColor
              : component.$3);
      final layer =
          component.$2?.backgroundColor?.resolve(state.$3) ?? component.$4;
      final overlay = component.$2?.overlayColor?.resolve(state.$3);
      pairings.add(
        ThemeTokenPairing(
          pairingId: '${component.$1}-${state.$1}',
          state: state.$2,
          contentKind: state.$3.contains(WidgetState.disabled)
              ? ThemeContrastContentKind.inactiveControl
              : ThemeContrastContentKind.normalText,
          foreground: foreground,
          background: ThemePaintStack(
            base: scheme.surface,
            layers: [
              if (layer.a != 0) layer,
              if (overlay != null && overlay.a != 0) overlay,
            ],
          ),
        ),
      );
    }
  }

  final schemePairs = <(String, Color, Color, ThemeTokenState)>[
    ('primary', scheme.onPrimary, scheme.primary, ThemeTokenState.defaultState),
    (
      'primary-container',
      scheme.onPrimaryContainer,
      scheme.primaryContainer,
      ThemeTokenState.selected,
    ),
    (
      'secondary',
      scheme.onSecondary,
      scheme.secondary,
      ThemeTokenState.defaultState,
    ),
    (
      'secondary-container',
      scheme.onSecondaryContainer,
      scheme.secondaryContainer,
      ThemeTokenState.selected,
    ),
    (
      'tertiary',
      scheme.onTertiary,
      scheme.tertiary,
      ThemeTokenState.defaultState,
    ),
    (
      'tertiary-container',
      scheme.onTertiaryContainer,
      scheme.tertiaryContainer,
      ThemeTokenState.selected,
    ),
    ('surface', scheme.onSurface, scheme.surface, ThemeTokenState.defaultState),
    ('error', scheme.onError, scheme.error, ThemeTokenState.error),
    (
      'error-container',
      scheme.onErrorContainer,
      scheme.errorContainer,
      ThemeTokenState.error,
    ),
    (
      'inverse',
      scheme.onInverseSurface,
      scheme.inverseSurface,
      ThemeTokenState.inverse,
    ),
  ];
  for (final pairing in schemePairs) {
    pairings.add(
      ThemeTokenPairing(
        pairingId: 'scheme-${pairing.$1}',
        state: pairing.$4,
        contentKind: ThemeContrastContentKind.normalText,
        foreground: pairing.$2,
        background: ThemePaintStack(base: pairing.$3),
      ),
    );
  }

  final textStyles = <(String, TextStyle?, ThemeContrastContentKind)>[
    (
      'display-large',
      theme.textTheme.displayLarge,
      ThemeContrastContentKind.largeText,
    ),
    (
      'display-medium',
      theme.textTheme.displayMedium,
      ThemeContrastContentKind.largeText,
    ),
    (
      'display-small',
      theme.textTheme.displaySmall,
      ThemeContrastContentKind.largeText,
    ),
    (
      'headline-large',
      theme.textTheme.headlineLarge,
      ThemeContrastContentKind.largeText,
    ),
    (
      'headline-medium',
      theme.textTheme.headlineMedium,
      ThemeContrastContentKind.largeText,
    ),
    (
      'headline-small',
      theme.textTheme.headlineSmall,
      ThemeContrastContentKind.largeText,
    ),
    (
      'title-large',
      theme.textTheme.titleLarge,
      ThemeContrastContentKind.largeText,
    ),
    (
      'title-medium',
      theme.textTheme.titleMedium,
      ThemeContrastContentKind.normalText,
    ),
    (
      'title-small',
      theme.textTheme.titleSmall,
      ThemeContrastContentKind.normalText,
    ),
    (
      'body-large',
      theme.textTheme.bodyLarge,
      ThemeContrastContentKind.normalText,
    ),
    (
      'body-medium',
      theme.textTheme.bodyMedium,
      ThemeContrastContentKind.normalText,
    ),
    (
      'body-small',
      theme.textTheme.bodySmall,
      ThemeContrastContentKind.normalText,
    ),
    (
      'label-large',
      theme.textTheme.labelLarge,
      ThemeContrastContentKind.normalText,
    ),
    (
      'label-medium',
      theme.textTheme.labelMedium,
      ThemeContrastContentKind.normalText,
    ),
    (
      'label-small',
      theme.textTheme.labelSmall,
      ThemeContrastContentKind.normalText,
    ),
  ];
  for (final style in textStyles) {
    pairings.add(
      ThemeTokenPairing(
        pairingId: 'text-${style.$1}',
        state: ThemeTokenState.defaultState,
        contentKind: style.$3,
        foreground: style.$2?.color ?? scheme.onSurface,
        background: ThemePaintStack(base: scheme.surface),
      ),
    );
  }

  pairings.addAll([
    ThemeTokenPairing(
      pairingId: 'focus-outer-on-surface',
      state: ThemeTokenState.focused,
      contentKind: ThemeContrastContentKind.graphic,
      foreground: accessibility?.focusOuterColor ?? scheme.primary,
      background: ThemePaintStack(base: scheme.surface),
    ),
    ThemeTokenPairing(
      pairingId: 'clinical-on-tinted-surface',
      state: ThemeTokenState.defaultState,
      contentKind: ThemeContrastContentKind.graphic,
      foreground: colors.clinical,
      background: ThemePaintStack(
        base: scheme.surface,
        layers: [colors.clinical.withValues(alpha: .22)],
      ),
    ),
    ThemeTokenPairing(
      pairingId: 'work-on-tinted-surface',
      state: ThemeTokenState.defaultState,
      contentKind: ThemeContrastContentKind.graphic,
      foreground: colors.workMachinery,
      background: ThemePaintStack(
        base: scheme.surface,
        layers: [colors.work.withValues(alpha: .22)],
      ),
    ),
    ThemeTokenPairing(
      pairingId: 'protected-day-accent',
      state: ThemeTokenState.defaultState,
      contentKind: ThemeContrastContentKind.graphic,
      foreground: colors.protectedDayAccent,
      background: ThemePaintStack(base: colors.protectedDay),
    ),
    ThemeTokenPairing(
      pairingId: 'scheduled-warning',
      state: ThemeTokenState.warning,
      contentKind: ThemeContrastContentKind.graphic,
      foreground: colors.scheduled,
      background: ThemePaintStack(base: scheme.surface),
    ),
    ThemeTokenPairing(
      pairingId: 'urgent-on-surface',
      state: ThemeTokenState.error,
      contentKind: ThemeContrastContentKind.graphic,
      foreground: colors.urgent,
      background: ThemePaintStack(base: scheme.surface),
    ),
  ]);
  return pairings;
}

@immutable
final class ThemePaintStack {
  const ThemePaintStack({required this.base, this.layers = const []});

  final Color base;
  final List<Color> layers;

  Color composite() {
    var result = Color.alphaBlend(base, Colors.black);
    for (final layer in layers) {
      result = Color.alphaBlend(layer, result);
    }
    return result;
  }
}

@immutable
final class ThemeTokenPairing {
  const ThemeTokenPairing({
    required this.pairingId,
    required this.state,
    required this.contentKind,
    required this.foreground,
    required this.background,
    this.permitted = true,
    this.selectedByRuntime = true,
  });

  final String pairingId;
  final ThemeTokenState state;
  final ThemeContrastContentKind contentKind;
  final Color foreground;
  final ThemePaintStack background;
  final bool permitted;
  final bool selectedByRuntime;
}

@immutable
final class ThemeTokenAuditEntry {
  const ThemeTokenAuditEntry({
    required this.pairingId,
    required this.state,
    required this.contentKind,
    required this.permitted,
    required this.selectedByRuntime,
    required this.compositedForeground,
    required this.compositedBackground,
    required this.contrastRatio,
    required this.requiredRatio,
    required this.passed,
  });

  final String pairingId;
  final ThemeTokenState state;
  final ThemeContrastContentKind contentKind;
  final bool permitted;
  final bool selectedByRuntime;
  final Color compositedForeground;
  final Color compositedBackground;
  final double contrastRatio;
  final double requiredRatio;
  final bool passed;

  Map<String, Object> toJson() => {
    'pairingId': pairingId,
    'state': state.name,
    'contentKind': contentKind.name,
    'permitted': permitted,
    'selectedByRuntime': selectedByRuntime,
    'compositedForeground': _hex(compositedForeground),
    'compositedBackground': _hex(compositedBackground),
    'contrastRatio': double.parse(contrastRatio.toStringAsFixed(3)),
    'requiredRatio': requiredRatio,
    'passed': passed,
  };
}

@immutable
final class ThemeTokenAuditReport {
  const ThemeTokenAuditReport({
    required this.themeId,
    required this.mode,
    required this.entries,
  });

  final String themeId;
  final ThemeAccessibilityMode mode;
  final List<ThemeTokenAuditEntry> entries;

  bool get passed => entries.every((entry) => entry.passed);

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'themeId': themeId,
    'mode': mode.name,
    'passed': passed,
    'entries': [for (final entry in entries) entry.toJson()],
  };
}

enum ThemeMaintainerDecision { pending, approved, rejected }

@immutable
final class ThemeAcceptanceEnvironment {
  const ThemeAcceptanceEnvironment({
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.displayMode,
    required this.orientation,
    required this.refreshRateHz,
  });

  final String platform;
  final String deviceModel;
  final String osVersion;
  final String displayMode;
  final String orientation;
  final double refreshRateHz;

  Map<String, Object> toJson() => {
    'platform': platform,
    'deviceModel': deviceModel,
    'osVersion': osVersion,
    'displayMode': displayMode,
    'orientation': orientation,
    'refreshRateHz': refreshRateHz,
  };
}

@immutable
final class ThemeContrastException {
  const ThemeContrastException({
    required this.pairingId,
    required this.state,
    required this.contentKind,
    required this.mode,
    required this.standardMeasuredRatio,
    required this.measuredRatio,
    required this.rationale,
    required this.redundantCue,
    required this.maintainerApproved,
  });

  final String pairingId;
  final ThemeTokenState state;
  final ThemeContrastContentKind contentKind;
  final ThemeAccessibilityMode mode;
  final double standardMeasuredRatio;
  final double measuredRatio;
  final String rationale;
  final String redundantCue;
  final bool maintainerApproved;

  bool get isValidEnhancedException =>
      pairingId.trim().isNotEmpty &&
      mode == ThemeAccessibilityMode.enhanced &&
      standardMeasuredRatio >=
          _requiredRatio(contentKind, ThemeAccessibilityMode.standard) &&
      measuredRatio < _requiredRatio(contentKind, mode) &&
      rationale.trim().isNotEmpty &&
      redundantCue.trim().isNotEmpty &&
      maintainerApproved;

  Map<String, Object> toJson() => {
    'pairingId': pairingId,
    'state': state.name,
    'contentKind': contentKind.name,
    'mode': mode.name,
    'standardMeasuredRatio': standardMeasuredRatio,
    'measuredRatio': measuredRatio,
    'rationale': rationale,
    'redundantCue': redundantCue,
    'maintainerApproved': maintainerApproved,
  };
}

@immutable
final class ThemeEvidenceManifest {
  const ThemeEvidenceManifest({
    required this.candidateCommit,
    required this.buildNumber,
    required this.themeId,
    required this.displayName,
    required this.fixtureId,
    required this.capturedAtUtc,
    required this.environment,
    required this.assetHashes,
    required this.reportUris,
    required this.captureUris,
    required this.ciRunUri,
    required this.manualChecklistUris,
    required this.accessibilityScannerReportUri,
    required this.approvedSignerSha256,
    required this.retrievedEvidenceSha256,
    required this.contrastExceptions,
    required this.gates,
    required this.maintainerDecision,
  });

  final String candidateCommit;
  final int buildNumber;
  final String themeId;
  final String displayName;
  final String fixtureId;
  final DateTime capturedAtUtc;
  final ThemeAcceptanceEnvironment environment;
  final Map<String, String> assetHashes;
  final List<String> reportUris;
  final List<String> captureUris;
  final String ciRunUri;
  final List<String> manualChecklistUris;
  final String accessibilityScannerReportUri;
  final String approvedSignerSha256;
  final Map<String, String> retrievedEvidenceSha256;
  final List<ThemeContrastException> contrastExceptions;
  final List<ThemeAcceptanceGateResult> gates;
  final ThemeMaintainerDecision maintainerDecision;

  ThemeAcceptanceState get acceptanceState {
    if (validationFailures.isNotEmpty) return ThemeAcceptanceState.pending;
    return ThemeAcceptanceEvaluation.evaluate(
      themeId: themeId,
      gates: gates,
      maintainerApproved:
          maintainerDecision == ThemeMaintainerDecision.approved,
    ).state;
  }

  List<String> get validationFailures {
    final failures = <String>[];
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(candidateCommit)) {
      failures.add('Candidate commit must be a complete lowercase Git SHA.');
    }
    if (buildNumber <= 0) failures.add('Candidate build must be positive.');
    if (themeId.trim().isEmpty || displayName.trim().isEmpty) {
      failures.add('Theme identity is incomplete.');
    }
    if (!fixtureId.toLowerCase().contains('fictional')) {
      failures.add('Evidence fixture must be explicitly fictional.');
    }
    if (_containsSensitiveIdentity(fixtureId) ||
        _containsCredentialAssignment(fixtureId)) {
      failures.add(
        'Evidence fixture contains identifying or credential information.',
      );
    }
    if (!capturedAtUtc.isUtc) {
      failures.add('Evidence timestamp must be UTC.');
    }
    if (environment.platform.trim().isEmpty ||
        environment.deviceModel.trim().isEmpty ||
        environment.osVersion.trim().isEmpty ||
        environment.displayMode.trim().isEmpty ||
        environment.orientation.trim().isEmpty ||
        environment.refreshRateHz <= 0) {
      failures.add('Evidence environment is incomplete.');
    }
    if (assetHashes.isEmpty ||
        assetHashes.values.any(
          (hash) => !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash),
        )) {
      failures.add(
        'Asset evidence requires complete lowercase SHA-256 values.',
      );
    }
    if (reportUris.isEmpty ||
        captureUris.isEmpty ||
        manualChecklistUris.isEmpty ||
        ciRunUri.trim().isEmpty ||
        accessibilityScannerReportUri.trim().isEmpty) {
      failures.add(
        'Reports, CI, captures, scanner results, and manual checklists must remain retrievable.',
      );
    }
    final evidenceUris = <String>{
      ...reportUris,
      ...captureUris,
      ...manualChecklistUris,
      ciRunUri,
      accessibilityScannerReportUri,
    };
    if (evidenceUris.any(_isUnsafeEvidenceUri)) {
      failures.add(
        'Evidence links cannot contain credentials or identifying information.',
      );
    }
    if (!setEquals(retrievedEvidenceSha256.keys.toSet(), evidenceUris) ||
        retrievedEvidenceSha256.values.any(
          (hash) => !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash),
        )) {
      failures.add(
        'Every evidence link requires an exact successful retrieval SHA-256 attestation.',
      );
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(approvedSignerSha256)) {
      failures.add(
        'The approved signer certificate requires a SHA-256 identity.',
      );
    }
    if (contrastExceptions.any(
      (exception) => !exception.isValidEnhancedException,
    )) {
      failures.add('Every Enhanced contrast exception requires full approval.');
    }
    return List.unmodifiable(failures);
  }

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'candidateCommit': candidateCommit,
    'candidateBuild': buildNumber,
    'themeId': themeId,
    'displayName': displayName,
    'fixture': fixtureId,
    'capturedAtUtc': capturedAtUtc.toIso8601String(),
    'environment': environment.toJson(),
    'assetHashes': assetHashes,
    'reports': reportUris,
    'captures': captureUris,
    'ciRun': ciRunUri,
    'manualChecklists': manualChecklistUris,
    'accessibilityScannerReport': accessibilityScannerReportUri,
    'approvedSignerSha256': approvedSignerSha256,
    'retrievedEvidenceSha256': retrievedEvidenceSha256,
    'contrastExceptions': [
      for (final exception in contrastExceptions) exception.toJson(),
    ],
    'gates': [for (final gate in gates) gate.toJson()],
    'approvalState': maintainerDecision.name,
    'acceptanceState': acceptanceState.name,
  };
}

@immutable
final class ThemePerformanceMeasurement {
  const ThemePerformanceMeasurement({
    required this.frameIntervalMs,
    required this.uiThreadFrameTimeMsP95,
    required this.rasterThreadFrameTimeMsP95,
    required this.retainedMemoryBytes,
    required this.releaseSizeBytes,
  });

  final double frameIntervalMs;
  final double uiThreadFrameTimeMsP95;
  final double rasterThreadFrameTimeMsP95;
  final int retainedMemoryBytes;
  final int releaseSizeBytes;

  Map<String, Object> toJson() => {
    'frameIntervalMs': frameIntervalMs,
    'uiThreadFrameTimeMsP95': uiThreadFrameTimeMsP95,
    'rasterThreadFrameTimeMsP95': rasterThreadFrameTimeMsP95,
    'retainedMemoryBytes': retainedMemoryBytes,
    'releaseSizeBytes': releaseSizeBytes,
  };
}

@immutable
final class ThemePerformanceEvidence {
  const ThemePerformanceEvidence({
    required this.baseline,
    required this.candidate,
    required this.swapLatencyMs,
    required this.retainedMemoryAfterCyclesBytes,
    required this.monotonicRetainedMemoryGrowth,
    required this.releaseSizeAttributionByAssetSha256,
  });

  final ThemePerformanceMeasurement baseline;
  final ThemePerformanceMeasurement candidate;
  final double swapLatencyMs;
  final int retainedMemoryAfterCyclesBytes;
  final bool monotonicRetainedMemoryGrowth;
  final Map<String, int> releaseSizeAttributionByAssetSha256;

  ThemeAcceptanceGateResult evaluate({
    required ThemeEvidenceManifest manifest,
  }) {
    final failures = <String>[];
    if (baseline.frameIntervalMs <= 0 ||
        baseline.uiThreadFrameTimeMsP95 <= 0 ||
        baseline.rasterThreadFrameTimeMsP95 <= 0 ||
        baseline.retainedMemoryBytes <= 0 ||
        baseline.releaseSizeBytes <= 0 ||
        candidate.frameIntervalMs <= 0 ||
        candidate.uiThreadFrameTimeMsP95 <= 0 ||
        candidate.rasterThreadFrameTimeMsP95 <= 0 ||
        candidate.retainedMemoryBytes <= 0 ||
        candidate.releaseSizeBytes <= 0 ||
        swapLatencyMs <= 0 ||
        retainedMemoryAfterCyclesBytes <= 0) {
      failures.add('Performance evidence requires measured positive values.');
    }
    final uiLimit = math.min(
      candidate.frameIntervalMs,
      baseline.uiThreadFrameTimeMsP95 * 1.1,
    );
    final rasterLimit = math.min(
      candidate.frameIntervalMs,
      baseline.rasterThreadFrameTimeMsP95 * 1.1,
    );
    if ((candidate.frameIntervalMs - baseline.frameIntervalMs).abs() > .01) {
      failures.add(
        'Candidate refresh-rate frame interval differs from baseline.',
      );
    }
    if (candidate.uiThreadFrameTimeMsP95 > uiLimit) {
      failures.add('UI-thread p95 exceeds the frame or 10% baseline limit.');
    }
    if (candidate.rasterThreadFrameTimeMsP95 > rasterLimit) {
      failures.add(
        'Raster-thread p95 exceeds the frame or 10% baseline limit.',
      );
    }
    if (swapLatencyMs > 250) {
      failures.add('Atomic theme swap exceeds 250 ms.');
    }
    final memoryLimit = (baseline.retainedMemoryBytes * 1.1).round();
    if (monotonicRetainedMemoryGrowth ||
        retainedMemoryAfterCyclesBytes > memoryLimit) {
      failures.add(
        '25 cycles show monotonic growth or retain more than 10% over baseline.',
      );
    }
    final releaseGrowth =
        candidate.releaseSizeBytes - baseline.releaseSizeBytes;
    final attributedGrowth = releaseSizeAttributionByAssetSha256.values.fold(
      0,
      (total, bytes) => total + bytes,
    );
    if (releaseSizeAttributionByAssetSha256.entries.any(
          (entry) =>
              !RegExp(r'^[0-9a-f]{64}$').hasMatch(entry.key) ||
              entry.value <= 0 ||
              !manifest.assetHashes.values.contains(entry.key),
        ) ||
        attributedGrowth != math.max(0, releaseGrowth)) {
      failures.add(
        'Release-size growth requires exact attribution to approved manifest asset hashes.',
      );
    }
    return ThemeAcceptanceGateResult(
      gateId: ThemeAcceptanceGateId.performance,
      passed: failures.isEmpty,
      failures: List.unmodifiable(failures),
    );
  }

  Map<String, Object> toJson({required ThemeEvidenceManifest manifest}) => {
    'baseline': baseline.toJson(),
    'candidate': candidate.toJson(),
    'swapLatencyMs': swapLatencyMs,
    'retainedMemoryAfterCyclesBytes': retainedMemoryAfterCyclesBytes,
    'monotonicRetainedMemoryGrowth': monotonicRetainedMemoryGrowth,
    'releaseSizeAttributionByAssetSha256': releaseSizeAttributionByAssetSha256,
    'manifestAssetSha256': manifest.assetHashes.values.toList()..sort(),
    'gate': evaluate(manifest: manifest).toJson(),
  };
}

const _acceptedCatalogThemeIds = <String>{
  'variant-f',
  'federation-classic',
  'federation-2399',
  'botanical-study',
  'coastal-calm',
  'graphite',
  'heritage-field-notes',
};

abstract final class ThemeRegistryAcceptanceAuditor {
  static ThemeAcceptanceGateResult audit(
    ClinicalCalendarThemeBundleRegistry registry,
  ) {
    final failures = <String>[];
    final bundles = registry.galleryBundles;
    try {
      ClinicalCalendarThemeBundleValidator.validate(bundles);
    } on InvalidThemeBundle catch (error) {
      failures.add(error.message);
    }
    final ids = {for (final bundle in bundles) bundle.id};
    if (!registry.isSelectableCatalogComplete ||
        registry.selectableBundles.length != 7 ||
        !setEquals(ids, _acceptedCatalogThemeIds)) {
      failures.add(
        'The closed selectable registry does not contain all seven themes.',
      );
    }
    return ThemeAcceptanceGateResult(
      gateId: ThemeAcceptanceGateId.registryOwnership,
      passed: failures.isEmpty,
      failures: List.unmodifiable(failures),
    );
  }
}

@immutable
final class ThemeRasterAcceptanceFixture {
  const ThemeRasterAcceptanceFixture({
    required this.expectedSha256,
    required this.creationRecordUri,
  });

  final String expectedSha256;
  final String creationRecordUri;
}

ThemeRasterAcceptanceFixture themeRasterAcceptanceFixture(String themeId) =>
    switch (themeId) {
      variantFThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            '9ff3968a94d497dc6f76f2b14f370c5a24c3bb4969397ee220da005093c15ad7',
        creationRecordUri:
            'docs/performance/containment-drone-pre-catalog-baseline.md',
      ),
      graphiteThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            '4865763bc6e0ab118ceda4f437d29595ed0d599078f9454724bb498b3fbc9a15',
        creationRecordUri: 'docs/concepts/themes/graphite/README.md',
      ),
      federationClassicThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            'd88711508354961c147c5d31064c48b205f3c71c511d2ee6500b0810da107689',
        creationRecordUri: 'docs/concepts/themes/federation-classic/README.md',
      ),
      federation2399ThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            '1a11f86edb76286e6bf35c58188b23fee0a4414c0d173c8bd28f602732ec49aa',
        creationRecordUri: 'docs/concepts/themes/federation-2399/README.md',
      ),
      coastalCalmThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            '449bee6b6097389d0fc860069160f20def2425043c20bb1e3daf29fe3f55e22f',
        creationRecordUri: 'docs/concepts/themes/coastal-light/README.md',
      ),
      botanicalStudyThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            'd8dd1c290cd87789ebc01a46d15f2a1fbb32b50c4c0c9afd9da89367b16542df',
        creationRecordUri: 'docs/concepts/themes/botanical-study/README.md',
      ),
      heritageFieldNotesThemeId => const ThemeRasterAcceptanceFixture(
        expectedSha256:
            '5bdc8587d9e35595868e5ee6e983c2cfb35d06bc110bd5cbf5885345c1f2645b',
        creationRecordUri:
            'docs/themes/acceptance/proofs/heritage-field-notes/README.md',
      ),
      _ => throw StateError('No primary-frame fixture for $themeId.'),
    };

@immutable
final class ThemeAssetEvidence {
  const ThemeAssetEvidence({
    required this.assetPath,
    required this.expectedSha256,
    required this.creationRecordUri,
    required this.comparisonCaptureUri,
    required this.originalityReviewer,
    required this.originalityApprovedAtUtc,
    required this.originalityApproved,
    required this.operationalContentAbsent,
  });

  final String assetPath;
  final String expectedSha256;
  final String creationRecordUri;
  final String comparisonCaptureUri;
  final String originalityReviewer;
  final DateTime originalityApprovedAtUtc;
  final bool originalityApproved;
  final bool operationalContentAbsent;
}

@immutable
final class ThemeAssetAuditReport {
  const ThemeAssetAuditReport({
    required this.gate,
    required this.sha256,
    required this.width,
    required this.height,
    required this.transparentCorners,
  });

  final ThemeAcceptanceGateResult gate;
  final String sha256;
  final int width;
  final int height;
  final List<bool> transparentCorners;

  Map<String, Object> toJson() => {
    'sha256': sha256,
    'width': width,
    'height': height,
    'transparentCorners': transparentCorners,
    'gate': gate.toJson(),
  };
}

abstract final class ThemeAssetAcceptanceAuditor {
  static Future<ThemeAssetAuditReport> auditPrimaryFrame({
    required ClinicalCalendarThemeBundle bundle,
    required List<int> bytes,
    required ThemeAssetEvidence evidence,
  }) async {
    final failures = <String>[];
    final descriptor = bundle.frame;
    final actualHash = sha256.convert(bytes).toString();
    if (evidence.assetPath != descriptor.primaryAsset) {
      failures.add('Asset evidence does not name the bundle primary frame.');
    }
    if (actualHash != evidence.expectedSha256) {
      failures.add('Primary frame SHA-256 does not match its evidence.');
    }
    if (evidence.creationRecordUri.trim().isEmpty ||
        evidence.comparisonCaptureUri.trim().isEmpty ||
        _isUnsafeEvidenceUri(evidence.creationRecordUri) ||
        _isUnsafeEvidenceUri(evidence.comparisonCaptureUri) ||
        evidence.originalityReviewer.trim().isEmpty ||
        !evidence.originalityApprovedAtUtc.isUtc ||
        !evidence.originalityApproved ||
        !evidence.operationalContentAbsent) {
      failures.add(
        'Originality requires creation and comparison records, an approved UTC attestation, and no operational content.',
      );
    }

    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    final transparentCorners = pixels == null
        ? const [false, false, false, false]
        : [
            _alphaAt(pixels, width, 0, 0) == 0,
            _alphaAt(pixels, width, width - 1, 0) == 0,
            _alphaAt(pixels, width, 0, height - 1) == 0,
            _alphaAt(pixels, width, width - 1, height - 1) == 0,
          ];
    if (width != 1536 ||
        height != 1024 ||
        descriptor.sourceSize != const Size(1536, 1024)) {
      failures.add('Primary frame must be 1536 by 1024 pixels.');
    }
    if (descriptor.sourceCuts !=
        const EdgeInsets.fromLTRB(120, 145, 120, 170)) {
      failures.add('Nine-slice cuts must remain 120/145/120/170.');
    }
    const minimumInsets = {
      ThemeFrameRegion.calendar: EdgeInsets.fromLTRB(38, 46, 38, 46),
      ThemeFrameRegion.placements: EdgeInsets.fromLTRB(30, 44, 30, 44),
      ThemeFrameRegion.planning: EdgeInsets.fromLTRB(34, 46, 34, 42),
      ThemeFrameRegion.status: EdgeInsets.fromLTRB(30, 44, 34, 44),
    };
    if (!_containsMinimumInsets(descriptor.safeInsets, minimumInsets)) {
      failures.add('Primary frame safe insets reduce the shared minima.');
    }
    if (transparentCorners.any((transparent) => !transparent)) {
      failures.add('Every exterior primary-frame corner must be transparent.');
    }
    if (pixels == null ||
        !_hasOpaqueContentBay(
          pixels,
          width: width,
          height: height,
          cuts: descriptor.sourceCuts,
        )) {
      failures.add('Primary frame must provide one opaque center content bay.');
    }

    image.dispose();
    codec.dispose();
    return ThemeAssetAuditReport(
      gate: ThemeAcceptanceGateResult(
        gateId: ThemeAcceptanceGateId.assetGeometryOriginality,
        passed: failures.isEmpty,
        failures: List.unmodifiable(failures),
      ),
      sha256: actualHash,
      width: width,
      height: height,
      transparentCorners: List.unmodifiable(transparentCorners),
    );
  }
}

@immutable
final class ThemeThumbnailSwatchEvidence {
  const ThemeThumbnailSwatchEvidence({
    required this.role,
    required this.label,
    required this.color,
  });

  final ThemeGallerySwatchRole role;
  final String label;
  final Color color;
}

@immutable
final class ThemeThumbnailEvidence {
  const ThemeThumbnailEvidence({
    required this.themeId,
    required this.rendererVersion,
    required this.fixtureId,
    required this.viewport,
    required this.sha256,
    required this.captureUri,
    required this.fictionalFixture,
    required this.swatches,
  });

  final String themeId;
  final String rendererVersion;
  final String fixtureId;
  final Size viewport;
  final String sha256;
  final String captureUri;
  final bool fictionalFixture;
  final List<ThemeThumbnailSwatchEvidence> swatches;
}

abstract final class ThemeThumbnailAcceptanceAuditor {
  static Future<ThemeAcceptanceGateResult> audit({
    required ClinicalCalendarThemeBundle bundle,
    required List<int> bytes,
    required ThemeThumbnailEvidence evidence,
  }) async {
    final failures = <String>[];
    if (evidence.themeId != bundle.id ||
        evidence.rendererVersion != bundle.shellRenderer.rendererId ||
        evidence.rendererVersion != bundle.gallery.rendererId ||
        evidence.fixtureId != bundle.gallery.thumbnailFixtureId ||
        evidence.viewport != bundle.gallery.thumbnailViewport) {
      failures.add('Thumbnail provenance does not match the runtime bundle.');
    }
    if (!evidence.fictionalFixture) {
      failures.add('Thumbnail evidence must use the pinned fictional fixture.');
    }
    if (sha256.convert(bytes).toString() != evidence.sha256) {
      failures.add('Thumbnail bytes do not match the recorded SHA-256.');
    }
    if (_isUnsafeEvidenceUri(evidence.captureUri)) {
      failures.add(
        'Thumbnail capture must remain retrievable and credential-free.',
      );
    }
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      if (frame.image.width != evidence.viewport.width.round() ||
          frame.image.height != evidence.viewport.height.round()) {
        failures.add('Thumbnail dimensions do not match the pinned viewport.');
      }
      frame.image.dispose();
      codec.dispose();
    } on Object {
      failures.add('Thumbnail evidence is not a decodable runtime image.');
    }
    final runtimeColors = bundle.standardPresentation.semanticColors;
    final bundleSwatches = bundle.gallery.swatches;
    if (evidence.swatches.length != ThemeGallerySwatchRole.values.length ||
        evidence.swatches.length != bundleSwatches.length) {
      failures.add('Thumbnail evidence does not contain all five swatches.');
    } else {
      for (var index = 0; index < bundleSwatches.length; index++) {
        final recorded = evidence.swatches[index];
        final runtime = bundleSwatches[index];
        final permittedRuntimeColors = _runtimeColorsForSwatch(
          runtime.role,
          runtimeColors,
        );
        if (recorded.role != runtime.role ||
            recorded.label != runtime.label ||
            recorded.color != runtime.color ||
            !permittedRuntimeColors.contains(recorded.color)) {
          failures.add(
            'Swatch ${runtime.role.name} is not the ordered runtime semantic token.',
          );
        }
      }
    }
    return ThemeAcceptanceGateResult(
      gateId: ThemeAcceptanceGateId.thumbnailProvenance,
      passed: failures.isEmpty,
      failures: List.unmodifiable(failures),
    );
  }
}

abstract final class ThemeContainmentDroneEqualityAuditor {
  static ThemeAcceptanceGateResult audit({
    required List<int> expectedRgba,
    required List<int> actualRgba,
    required bool protectedAssetsUnchanged,
    required bool protectedRendererUnchanged,
    required bool regressionSuitePassed,
  }) {
    final failures = <String>[];
    if (!_equalBytes(expectedRgba, actualRgba)) {
      failures.add(
        'Catalog-resolved Variant F is not exact reference-image equality.',
      );
    }
    if (!protectedAssetsUnchanged) {
      failures.add('A protected Containment Drone asset changed.');
    }
    if (!protectedRendererUnchanged) {
      failures.add('A protected Containment Drone renderer changed.');
    }
    if (!regressionSuitePassed) {
      failures.add('Containment Drone regression suites did not pass.');
    }
    return ThemeAcceptanceGateResult(
      gateId: ThemeAcceptanceGateId.containmentDroneEquality,
      passed: failures.isEmpty,
      failures: List.unmodifiable(failures),
    );
  }
}

abstract final class ThemeRuntimeTokenAuditor {
  static ThemeTokenAuditReport audit({
    required ClinicalCalendarThemeBundle bundle,
    required ThemeAccessibilityMode mode,
  }) {
    final enhanced = mode == ThemeAccessibilityMode.enhanced;
    final theme = bundle.standardPresentation.createThemeData(
      enhancedAccessibility: enhanced,
    );
    final colors = theme.extension<ClinicalCalendarColors>()!;
    final accessibility = theme
        .extension<ClinicalCalendarAccessibilityTokens>();
    return auditThemeData(
      themeId: bundle.id,
      theme: theme,
      colors: colors,
      accessibility: accessibility,
      mode: mode,
    );
  }

  static ThemeTokenAuditReport auditThemeData({
    required String themeId,
    required ThemeData theme,
    required ClinicalCalendarColors colors,
    required ClinicalCalendarAccessibilityTokens? accessibility,
    required ThemeAccessibilityMode mode,
  }) {
    final permitted = _runtimePermittedPairings(
      theme: theme,
      colors: colors,
      accessibility: accessibility,
    );
    final componentPairs = {
      for (final pairing in permitted)
        (pairing.foreground, pairing.background.composite()),
    };

    return auditPairings(
      themeId: themeId,
      mode: mode,
      pairings: [
        ...permitted,
        ThemeTokenPairing(
          pairingId: 'prohibited-urgent-on-clinical',
          state: ThemeTokenState.error,
          contentKind: ThemeContrastContentKind.graphic,
          foreground: colors.urgent,
          background: ThemePaintStack(base: colors.clinical),
          permitted: false,
          selectedByRuntime: componentPairs.contains((
            colors.urgent,
            ThemePaintStack(base: colors.clinical).composite(),
          )),
        ),
        ThemeTokenPairing(
          pairingId: 'prohibited-work-on-scheduled',
          state: ThemeTokenState.warning,
          contentKind: ThemeContrastContentKind.graphic,
          foreground: colors.workMachinery,
          background: ThemePaintStack(base: colors.scheduled),
          permitted: false,
          selectedByRuntime: componentPairs.contains((
            colors.workMachinery,
            ThemePaintStack(base: colors.scheduled).composite(),
          )),
        ),
      ],
    );
  }

  static ThemeTokenAuditReport auditPairings({
    required String themeId,
    required ThemeAccessibilityMode mode,
    required Iterable<ThemeTokenPairing> pairings,
  }) => ThemeTokenAuditReport(
    themeId: themeId,
    mode: mode,
    entries: List.unmodifiable(
      pairings.map((pairing) {
        final background = pairing.background.composite();
        final foreground = Color.alphaBlend(pairing.foreground, background);
        final ratio = _contrastRatio(foreground, background);
        final required = _requiredRatio(pairing.contentKind, mode);
        return ThemeTokenAuditEntry(
          pairingId: pairing.pairingId,
          state: pairing.state,
          contentKind: pairing.contentKind,
          permitted: pairing.permitted,
          selectedByRuntime: pairing.selectedByRuntime,
          compositedForeground: foreground,
          compositedBackground: background,
          contrastRatio: ratio,
          requiredRatio: required,
          passed: pairing.permitted
              ? pairing.selectedByRuntime && ratio >= required
              : !pairing.selectedByRuntime,
        );
      }),
    ),
  );
}

@immutable
final class ThemeAcceptanceGateResult {
  const ThemeAcceptanceGateResult({
    required this.gateId,
    required this.passed,
    this.reportUri,
    this.failures = const [],
  });

  final String gateId;
  final bool passed;
  final String? reportUri;
  final List<String> failures;

  Map<String, Object?> toJson() => {
    'gateId': gateId,
    'passed': passed,
    if (reportUri != null) 'reportUri': reportUri,
    'failures': failures,
  };
}

@immutable
final class ThemeAcceptanceEvaluation {
  const ThemeAcceptanceEvaluation._({
    required this.themeId,
    required this.state,
    required this.failedGateIds,
    required this.missingGateIds,
    required this.maintainerApproved,
  });

  factory ThemeAcceptanceEvaluation.evaluate({
    required String themeId,
    required Iterable<ThemeAcceptanceGateResult> gates,
    required bool maintainerApproved,
  }) {
    final byId = <String, List<ThemeAcceptanceGateResult>>{};
    for (final gate in gates) {
      byId.putIfAbsent(gate.gateId, () => []).add(gate);
    }
    final missing = [
      for (final gateId in themeAcceptanceGateIds)
        if (!byId.containsKey(gateId)) gateId,
    ];
    final failed = [
      for (final gateId in themeAcceptanceGateIds)
        if (byId[gateId]?.any((gate) => !gate.passed) ?? false) gateId,
    ];
    return ThemeAcceptanceEvaluation._(
      themeId: themeId,
      state: missing.isEmpty && failed.isEmpty && maintainerApproved
          ? ThemeAcceptanceState.accepted
          : ThemeAcceptanceState.pending,
      failedGateIds: List.unmodifiable(failed),
      missingGateIds: List.unmodifiable(missing),
      maintainerApproved: maintainerApproved,
    );
  }

  final String themeId;
  final ThemeAcceptanceState state;
  final List<String> failedGateIds;
  final List<String> missingGateIds;
  final bool maintainerApproved;
}

double _requiredRatio(
  ThemeContrastContentKind kind,
  ThemeAccessibilityMode mode,
) => switch ((kind, mode)) {
  (ThemeContrastContentKind.normalText, ThemeAccessibilityMode.standard) => 4.5,
  (ThemeContrastContentKind.normalText, ThemeAccessibilityMode.enhanced) => 7,
  (ThemeContrastContentKind.largeText, ThemeAccessibilityMode.standard) => 3,
  (ThemeContrastContentKind.largeText, ThemeAccessibilityMode.enhanced) => 4.5,
  (ThemeContrastContentKind.graphic, ThemeAccessibilityMode.standard) => 3,
  (ThemeContrastContentKind.graphic, ThemeAccessibilityMode.enhanced) => 4.5,
  (ThemeContrastContentKind.inactiveControl, _) => 1,
};

double _contrastRatio(Color foreground, Color background) {
  final lighter = math.max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final darker = math.min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  return (lighter + .05) / (darker + .05);
}

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

bool _containsSensitiveIdentity(String value) => RegExp(
  r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
  caseSensitive: false,
).hasMatch(value);

bool _containsCredentialAssignment(String value) => RegExp(
  r'(?:(?:api|db|database|private|signing)[_-]?key|key|access[_-]?token|token|password|passphrase|otp|signature|sig|client[_-]?secret|secret|auth(?:orization)?|credentials?)\s*[:=]\s*[^&\s]+',
  caseSensitive: false,
).hasMatch(value);

abstract final class ThemeEvidenceSafety {
  static bool isSafeReference(String value) => !_isUnsafeEvidenceUri(value);
}

bool _isUnsafeEvidenceUri(String value) {
  final uri = Uri.tryParse(value);
  final unsafeKey = RegExp(
    r'^(?:(?:api|db|database|private|signing)[_-]?key|key|access[_-]?token|token|password|passphrase|otp|signature|sig|client[_-]?secret|secret|auth(?:orization)?|credentials?)$',
    caseSensitive: false,
  );
  final fragmentParameters = uri == null
      ? const <String, String>{}
      : Uri.tryParse('?${uri.fragment}')?.queryParameters ??
            const <String, String>{};
  return value.trim().isEmpty ||
      _containsSensitiveIdentity(value) ||
      _containsCredentialAssignment(value) ||
      (uri != null &&
          (uri.userInfo.isNotEmpty ||
              uri.queryParameters.keys.any(unsafeKey.hasMatch) ||
              fragmentParameters.keys.any(unsafeKey.hasMatch)));
}

int _alphaAt(ByteData pixels, int width, int x, int y) =>
    pixels.getUint8((y * width + x) * 4 + 3);

bool _containsMinimumInsets(
  Map<ThemeFrameRegion, EdgeInsets> actual,
  Map<ThemeFrameRegion, EdgeInsets> minimum,
) => minimum.entries.every((entry) {
  final value = actual[entry.key];
  final required = entry.value;
  return value != null &&
      value.left >= required.left &&
      value.top >= required.top &&
      value.right >= required.right &&
      value.bottom >= required.bottom;
});

bool _hasOpaqueContentBay(
  ByteData pixels, {
  required int width,
  required int height,
  required EdgeInsets cuts,
}) {
  for (var y = cuts.top.ceil(); y < height - cuts.bottom.ceil(); y++) {
    for (var x = cuts.left.ceil(); x < width - cuts.right.ceil(); x++) {
      if (_alphaAt(pixels, width, x, y) != 255) return false;
    }
  }
  return true;
}

bool _equalBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Set<Color> _runtimeColorsForSwatch(
  ThemeGallerySwatchRole role,
  ClinicalCalendarColors colors,
) => switch (role) {
  ThemeGallerySwatchRole.canvas => {colors.canvas},
  ThemeGallerySwatchRole.structure => {
    colors.structure,
    colors.structureRaised,
  },
  ThemeGallerySwatchRole.clinicalSession => {colors.clinical},
  ThemeGallerySwatchRole.workShift => {colors.workMachinery},
  ThemeGallerySwatchRole.urgent => {colors.urgent},
};
