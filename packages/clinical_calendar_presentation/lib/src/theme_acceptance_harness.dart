import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';
import 'theme_contract.dart';
import 'variant_f_theme.dart';

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
];

enum ThemeAcceptanceState { pending, accepted }

enum ThemeAccessibilityMode { standard, enhanced }

enum ThemeContrastContentKind { normalText, largeText, graphic }

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
    required this.measuredRatio,
    required this.rationale,
    required this.redundantCue,
    required this.maintainerApproved,
  });

  final String pairingId;
  final double measuredRatio;
  final String rationale;
  final String redundantCue;
  final bool maintainerApproved;

  Map<String, Object> toJson() => {
    'pairingId': pairingId,
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
    if (_containsSensitiveIdentity(fixtureId)) {
      failures.add('Evidence fixture contains identifying information.');
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
    if (reportUris.isEmpty || captureUris.isEmpty) {
      failures.add('Reports and original captures must remain retrievable.');
    }
    if ([...reportUris, ...captureUris].any(_isUnsafeEvidenceUri)) {
      failures.add('Evidence links cannot contain credentials or user info.');
    }
    if (contrastExceptions.any(
      (exception) =>
          exception.pairingId.trim().isEmpty ||
          exception.rationale.trim().isEmpty ||
          exception.redundantCue.trim().isEmpty ||
          !exception.maintainerApproved,
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
    required this.attributedReleaseGrowthBytes,
  });

  final ThemePerformanceMeasurement baseline;
  final ThemePerformanceMeasurement candidate;
  final double swapLatencyMs;
  final int retainedMemoryAfterCyclesBytes;
  final bool monotonicRetainedMemoryGrowth;
  final int attributedReleaseGrowthBytes;

  ThemeAcceptanceGateResult evaluate() {
    final failures = <String>[];
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
    if (releaseGrowth > attributedReleaseGrowthBytes) {
      failures.add('Release-size growth is not fully attributed.');
    }
    return ThemeAcceptanceGateResult(
      gateId: ThemeAcceptanceGateId.performance,
      passed: failures.isEmpty,
      failures: List.unmodifiable(failures),
    );
  }

  Map<String, Object> toJson() => {
    'baseline': baseline.toJson(),
    'candidate': candidate.toJson(),
    'swapLatencyMs': swapLatencyMs,
    'retainedMemoryAfterCyclesBytes': retainedMemoryAfterCyclesBytes,
    'monotonicRetainedMemoryGrowth': monotonicRetainedMemoryGrowth,
    'attributedReleaseGrowthBytes': attributedReleaseGrowthBytes,
    'gate': evaluate().toJson(),
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
final class ThemeAssetEvidence {
  const ThemeAssetEvidence({
    required this.assetPath,
    required this.expectedSha256,
    required this.creationRecordUri,
    required this.originalityApproved,
  });

  final String assetPath;
  final String expectedSha256;
  final String creationRecordUri;
  final bool originalityApproved;
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
        _isUnsafeEvidenceUri(evidence.creationRecordUri) ||
        !evidence.originalityApproved) {
      failures.add(
        'Originality requires a retrievable creation record and approval.',
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
    const requiredInsets = {
      ThemeFrameRegion.calendar: EdgeInsets.fromLTRB(38, 46, 38, 46),
      ThemeFrameRegion.placements: EdgeInsets.fromLTRB(30, 44, 30, 44),
      ThemeFrameRegion.planning: EdgeInsets.fromLTRB(34, 46, 34, 42),
      ThemeFrameRegion.status: EdgeInsets.fromLTRB(30, 44, 34, 44),
    };
    if (!mapEquals(descriptor.safeInsets, requiredInsets)) {
      failures.add(
        'Primary frame safe insets do not match the shared geometry.',
      );
    }
    if (transparentCorners.any((transparent) => !transparent)) {
      failures.add('Every exterior primary-frame corner must be transparent.');
    }
    if (pixels == null ||
        _alphaAt(pixels, width, width ~/ 2, height ~/ 2) != 255) {
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
final class ThemeThumbnailEvidence {
  const ThemeThumbnailEvidence({
    required this.themeId,
    required this.rendererId,
    required this.fixtureId,
    required this.viewport,
    required this.sha256,
    required this.captureUri,
    required this.fictionalFixture,
  });

  final String themeId;
  final String rendererId;
  final String fixtureId;
  final Size viewport;
  final String sha256;
  final String captureUri;
  final bool fictionalFixture;
}

abstract final class ThemeThumbnailAcceptanceAuditor {
  static ThemeAcceptanceGateResult audit({
    required ClinicalCalendarThemeBundle bundle,
    required List<int> bytes,
    required ThemeThumbnailEvidence evidence,
  }) {
    final failures = <String>[];
    if (evidence.themeId != bundle.id ||
        evidence.rendererId != bundle.shellRenderer.rendererId ||
        evidence.rendererId != bundle.gallery.rendererId ||
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
    final scheme = theme.colorScheme;
    final filled = theme.filledButtonTheme.style;
    final segmented = theme.segmentedButtonTheme.style;
    final surface = ThemePaintStack(base: scheme.surface);

    Color resolve(
      WidgetStateProperty<Color?>? property,
      Set<WidgetState> states,
      Color fallback,
    ) => property?.resolve(states) ?? fallback;

    final componentPairs = <(Color, Color)>{
      (scheme.onSurface, scheme.surface),
      (scheme.error, scheme.surface),
      (scheme.onError, scheme.error),
      (scheme.onInverseSurface, scheme.inverseSurface),
      (colors.scheduled, scheme.surface),
      (colors.urgent, scheme.surface),
      for (final states in const <Set<WidgetState>>[
        {},
        {WidgetState.selected},
        {WidgetState.focused},
        {WidgetState.pressed},
        {WidgetState.disabled},
      ]) ...[
        (
          resolve(filled?.foregroundColor, states, scheme.onPrimary),
          resolve(filled?.backgroundColor, states, scheme.primary),
        ),
        (
          resolve(segmented?.foregroundColor, states, scheme.onSurface),
          resolve(segmented?.backgroundColor, states, scheme.surface),
        ),
      ],
    };

    return auditPairings(
      themeId: bundle.id,
      mode: mode,
      pairings: [
        ThemeTokenPairing(
          pairingId: 'body-on-surface',
          state: ThemeTokenState.defaultState,
          contentKind: ThemeContrastContentKind.normalText,
          foreground: scheme.onSurface,
          background: surface,
        ),
        ThemeTokenPairing(
          pairingId: 'selected-control',
          state: ThemeTokenState.selected,
          contentKind: ThemeContrastContentKind.normalText,
          foreground: resolve(segmented?.foregroundColor, const {
            WidgetState.selected,
          }, scheme.onPrimary),
          background: ThemePaintStack(
            base: resolve(segmented?.backgroundColor, const {
              WidgetState.selected,
            }, scheme.primary),
          ),
        ),
        ThemeTokenPairing(
          pairingId: 'focus-boundary',
          state: ThemeTokenState.focused,
          contentKind: ThemeContrastContentKind.graphic,
          foreground: accessibility?.focusOuterColor ?? scheme.primary,
          background: surface,
        ),
        ThemeTokenPairing(
          pairingId: 'pressed-control',
          state: ThemeTokenState.pressed,
          contentKind: ThemeContrastContentKind.normalText,
          foreground: resolve(filled?.foregroundColor, const {
            WidgetState.pressed,
          }, scheme.onPrimary),
          background: ThemePaintStack(
            base: resolve(filled?.backgroundColor, const {
              WidgetState.pressed,
            }, scheme.primary),
          ),
        ),
        ThemeTokenPairing(
          pairingId: 'disabled-control',
          state: ThemeTokenState.disabled,
          contentKind: ThemeContrastContentKind.normalText,
          foreground: resolve(filled?.foregroundColor, const {
            WidgetState.disabled,
          }, theme.disabledColor),
          background: ThemePaintStack(
            base: resolve(filled?.backgroundColor, const {
              WidgetState.disabled,
            }, scheme.surface),
          ),
        ),
        ThemeTokenPairing(
          pairingId: 'scheduled-warning',
          state: ThemeTokenState.warning,
          contentKind: ThemeContrastContentKind.graphic,
          foreground: colors.scheduled,
          background: surface,
        ),
        ThemeTokenPairing(
          pairingId: 'error-on-surface',
          state: ThemeTokenState.error,
          contentKind: ThemeContrastContentKind.normalText,
          foreground: scheme.error,
          background: surface,
        ),
        ThemeTokenPairing(
          pairingId: 'inverse-label',
          state: ThemeTokenState.inverse,
          contentKind: ThemeContrastContentKind.normalText,
          foreground: scheme.onInverseSurface,
          background: ThemePaintStack(base: scheme.inverseSurface),
        ),
        ThemeTokenPairing(
          pairingId: 'prohibited-urgent-on-clinical',
          state: ThemeTokenState.error,
          contentKind: ThemeContrastContentKind.graphic,
          foreground: colors.urgent,
          background: ThemePaintStack(base: colors.clinical),
          permitted: false,
          selectedByRuntime: componentPairs.contains((
            colors.urgent,
            colors.clinical,
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
            colors.scheduled,
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

bool _isUnsafeEvidenceUri(String value) {
  final uri = Uri.tryParse(value);
  return value.trim().isEmpty ||
      _containsSensitiveIdentity(value) ||
      (uri != null && uri.userInfo.isNotEmpty);
}

int _alphaAt(ByteData pixels, int width, int x, int y) =>
    pixels.getUint8((y * width + x) * 4 + 3);

bool _equalBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
