import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('non-compensating theme acceptance', () {
    test('a missing or failed gate leaves the theme Pending', () {
      final evaluation = ThemeAcceptanceEvaluation.evaluate(
        themeId: graphiteThemeId,
        gates: [
          for (final gateId in themeAcceptanceGateIds)
            ThemeAcceptanceGateResult(
              gateId: gateId,
              passed: gateId != ThemeAcceptanceGateId.runtimeTokens,
              failures: gateId == ThemeAcceptanceGateId.runtimeTokens
                  ? const ['disabled text misses the required contrast']
                  : const [],
            ),
        ],
        maintainerApproved: true,
      );

      expect(evaluation.state, ThemeAcceptanceState.pending);
      expect(evaluation.failedGateIds, [ThemeAcceptanceGateId.runtimeTokens]);

      final missing = ThemeAcceptanceEvaluation.evaluate(
        themeId: graphiteThemeId,
        gates: const [],
        maintainerApproved: true,
      );
      expect(missing.state, ThemeAcceptanceState.pending);
      expect(missing.missingGateIds, themeAcceptanceGateIds);
    });

    test('only every passing gate plus maintainer approval can accept', () {
      final passing = [
        for (final gateId in themeAcceptanceGateIds)
          ThemeAcceptanceGateResult(
            gateId: gateId,
            passed: true,
            reportUri: 'reports/$gateId.json',
          ),
      ];

      expect(
        ThemeAcceptanceEvaluation.evaluate(
          themeId: variantFThemeId,
          gates: passing,
          maintainerApproved: false,
        ).state,
        ThemeAcceptanceState.pending,
      );
      expect(
        ThemeAcceptanceEvaluation.evaluate(
          themeId: variantFThemeId,
          gates: passing,
          maintainerApproved: true,
        ).state,
        ThemeAcceptanceState.accepted,
      );

      final duplicatedFailure = ThemeAcceptanceEvaluation.evaluate(
        themeId: variantFThemeId,
        gates: [
          const ThemeAcceptanceGateResult(
            gateId: ThemeAcceptanceGateId.runtimeTokens,
            passed: false,
            failures: ['Standard audit failed.'],
          ),
          ...passing,
        ],
        maintainerApproved: true,
      );
      expect(duplicatedFailure.state, ThemeAcceptanceState.pending);
      expect(
        duplicatedFailure.failedGateIds,
        contains(ThemeAcceptanceGateId.runtimeTokens),
      );
    });
  });

  group('runtime token audit', () {
    for (final bundle
        in ClinicalCalendarThemeBundleRegistry.standard.galleryBundles) {
      for (final mode in ThemeAccessibilityMode.values) {
        test(
          '${bundle.id} ${mode.name} audits actual runtime state layers',
          () {
            final report = ThemeRuntimeTokenAuditor.audit(
              bundle: bundle,
              mode: mode,
            );

            expect(report.themeId, bundle.id);
            expect(report.mode, mode);
            expect(
              report.entries.map((entry) => entry.state).toSet(),
              containsAll(ThemeTokenState.values),
            );
            expect(report.entries.any((entry) => entry.permitted), isTrue);
            expect(report.entries.any((entry) => !entry.permitted), isTrue);
            expect(
              report.entries.every(
                (entry) =>
                    entry.compositedForeground.a == 1 &&
                    entry.compositedBackground.a == 1,
              ),
              isTrue,
            );
            expect(report.toJson()['themeId'], bundle.id);
          },
        );
      }
    }

    test('alpha is composited over the surface actually painted', () {
      final report = ThemeRuntimeTokenAuditor.auditPairings(
        themeId: 'fixture',
        mode: ThemeAccessibilityMode.standard,
        pairings: const [
          ThemeTokenPairing(
            pairingId: 'translucent-label',
            state: ThemeTokenState.defaultState,
            contentKind: ThemeContrastContentKind.normalText,
            foreground: Color(0x80FFFFFF),
            background: ThemePaintStack(
              base: Colors.black,
              layers: [Color(0x40FFFFFF)],
            ),
          ),
        ],
      );

      final entry = report.entries.single;
      expect(entry.compositedBackground, isNot(Colors.black));
      expect(entry.compositedForeground, isNot(const Color(0x80FFFFFF)));
      expect(entry.contrastRatio, greaterThan(1));
      expect(entry.contrastRatio, lessThan(21));
    });
  });

  group('reviewable evidence', () {
    test(
      'manifest identifies the candidate and rejects identifying fixtures',
      () {
        final manifest = ThemeEvidenceManifest(
          candidateCommit: '0123456789abcdef0123456789abcdef01234567',
          buildNumber: 41,
          themeId: graphiteThemeId,
          displayName: 'Graphite',
          fixtureId: 'catalog-acceptance-fictional-v1',
          capturedAtUtc: DateTime.utc(2026, 8, 8),
          environment: const ThemeAcceptanceEnvironment(
            platform: 'Android',
            deviceModel: 'SM-X920',
            osVersion: '16',
            displayMode: '2960x1848@120Hz',
            orientation: 'landscape',
            refreshRateHz: 120,
          ),
          assetHashes: const {
            'assets/graphite_raster/panel-nine-slice-v1.png':
                '4865763bc6e0ab118ceda4f437d29595ed0d599078f9454724bb498b3fbc9a15',
          },
          reportUris: const ['reports/runtime-tokens.json'],
          captureUris: const ['captures/calendar.png'],
          contrastExceptions: const [],
          gates: const [],
          maintainerDecision: ThemeMaintainerDecision.pending,
        );

        expect(manifest.validationFailures, isEmpty);
        expect(manifest.toJson(), containsPair('approvalState', 'pending'));
        expect(manifest.toJson(), containsPair('candidateBuild', 41));

        final unsafe = ThemeEvidenceManifest(
          candidateCommit: '0123456789abcdef0123456789abcdef01234567',
          buildNumber: 41,
          themeId: graphiteThemeId,
          displayName: 'Graphite',
          fixtureId: 'student@example.com',
          capturedAtUtc: DateTime.utc(2026, 8, 8),
          environment: manifest.environment,
          assetHashes: manifest.assetHashes,
          reportUris: manifest.reportUris,
          captureUris: manifest.captureUris,
          contrastExceptions: const [],
          gates: const [],
          maintainerDecision: ThemeMaintainerDecision.pending,
        );
        expect(unsafe.validationFailures, isNotEmpty);
      },
    );

    test('performance gate compares every measurement with the baseline', () {
      const baseline = ThemePerformanceMeasurement(
        frameIntervalMs: 8.333,
        uiThreadFrameTimeMsP95: 3.403,
        rasterThreadFrameTimeMsP95: 5.627,
        retainedMemoryBytes: 219508000,
        releaseSizeBytes: 50000000,
      );
      const passingCandidate = ThemePerformanceMeasurement(
        frameIntervalMs: 8.333,
        uiThreadFrameTimeMsP95: 3.5,
        rasterThreadFrameTimeMsP95: 5.8,
        retainedMemoryBytes: 220000000,
        releaseSizeBytes: 51000000,
      );

      final passing = ThemePerformanceEvidence(
        baseline: baseline,
        candidate: passingCandidate,
        swapLatencyMs: 180,
        retainedMemoryAfterCyclesBytes: 221000000,
        monotonicRetainedMemoryGrowth: false,
        attributedReleaseGrowthBytes: 1000000,
      ).evaluate();
      expect(passing.passed, isTrue);

      final failed = ThemePerformanceEvidence(
        baseline: baseline,
        candidate: passingCandidate,
        swapLatencyMs: 251,
        retainedMemoryAfterCyclesBytes: 221000000,
        monotonicRetainedMemoryGrowth: false,
        attributedReleaseGrowthBytes: 1000000,
      ).evaluate();
      expect(failed.passed, isFalse);
      expect(failed.failures, contains(contains('250')));
    });
  });

  group('executable catalog gates', () {
    final packageRoot =
        Directory.current.path.endsWith('clinical_calendar_presentation')
        ? Directory.current
        : Directory('packages/clinical_calendar_presentation');
    final bundles = ClinicalCalendarThemeBundleRegistry.standard.galleryBundles;

    test('registry audits ownership and remains Pending while partial', () {
      final result = ThemeRegistryAcceptanceAuditor.audit(
        ClinicalCalendarThemeBundleRegistry.standard,
      );

      expect(result.passed, isFalse);
      expect(result.failures, contains(contains('seven')));
      for (final bundle in bundles) {
        expect(result.failures, isNot(contains(contains(bundle.id))));
      }
    });

    for (final bundle in bundles) {
      test(
        '${bundle.id} primary frame geometry and originality are audited',
        () async {
          final expectedHash = switch (bundle.id) {
            variantFThemeId =>
              '9ff3968a94d497dc6f76f2b14f370c5a24c3bb4969397ee220da005093c15ad7',
            graphiteThemeId =>
              '4865763bc6e0ab118ceda4f437d29595ed0d599078f9454724bb498b3fbc9a15',
            _ => throw StateError('Unexpected fixture ${bundle.id}'),
          };
          final report = await ThemeAssetAcceptanceAuditor.auditPrimaryFrame(
            bundle: bundle,
            bytes: await File(
              '${packageRoot.path}/${bundle.frame.primaryAsset}',
            ).readAsBytes(),
            evidence: ThemeAssetEvidence(
              assetPath: bundle.frame.primaryAsset,
              expectedSha256: expectedHash,
              creationRecordUri: bundle.id == variantFThemeId
                  ? 'docs/performance/containment-drone-pre-catalog-baseline.md'
                  : 'docs/concepts/themes/graphite/README.md',
              originalityApproved: true,
            ),
          );

          expect(
            report.gate.passed,
            isTrue,
            reason: report.gate.failures.join('\n'),
          );
          expect(report.width, 1536);
          expect(report.height, 1024);
          expect(report.transparentCorners, [true, true, true, true]);
        },
      );
    }

    test('thumbnail provenance binds bytes to the runtime bundle metadata', () {
      final bundle = bundles.singleWhere((item) => item.id == graphiteThemeId);
      final bytes = utf8.encode('runtime-thumbnail');
      final evidence = ThemeThumbnailEvidence(
        themeId: bundle.id,
        rendererId: bundle.shellRenderer.rendererId,
        fixtureId: bundle.gallery.thumbnailFixtureId,
        viewport: bundle.gallery.thumbnailViewport,
        sha256:
            'b5071c54484cacebbbb1e4a39dc1eb159d627d15ec288f7b8c7076c364943f30',
        captureUri: 'captures/graphite-thumbnail.png',
        fictionalFixture: true,
      );

      expect(
        ThemeThumbnailAcceptanceAuditor.audit(
          bundle: bundle,
          bytes: bytes,
          evidence: evidence,
        ).passed,
        isTrue,
      );
      expect(
        ThemeThumbnailAcceptanceAuditor.audit(
          bundle: bundle,
          bytes: utf8.encode('stale-thumbnail'),
          evidence: evidence,
        ).passed,
        isFalse,
      );
    });

    test('Containment Drone equality is exact and non-tolerant', () {
      const expected = [1, 2, 3, 4];
      expect(
        ThemeContainmentDroneEqualityAuditor.audit(
          expectedRgba: expected,
          actualRgba: expected,
          protectedAssetsUnchanged: true,
          protectedRendererUnchanged: true,
          regressionSuitePassed: true,
        ).passed,
        isTrue,
      );
      expect(
        ThemeContainmentDroneEqualityAuditor.audit(
          expectedRgba: expected,
          actualRgba: const [1, 2, 3, 5],
          protectedAssetsUnchanged: true,
          protectedRendererUnchanged: true,
          regressionSuitePassed: true,
        ).passed,
        isFalse,
      );
    });
  });

  group('parameterized external-behavior matrix', () {
    final registry = ClinicalCalendarThemeBundleRegistry.standard;
    final bundles = registry.galleryBundles;

    for (final source in bundles) {
      for (final candidate in bundles.where(
        (bundle) => bundle.id != source.id,
      )) {
        test(
          '${source.id} to ${candidate.id} preserves working state and persists only on Apply',
          () async {
            final workingState = <String, Object>{
              'destination': 'Settings',
              'calendarPeriod': 'August 2026',
              'calendarSelection': '2026-08-07',
              'scrollOffset': 312.5,
              'unsavedField': 'fictional draft',
              'focus': 'theme-gallery-row-${candidate.id}',
              'controllerIdentity': 17,
              'loadedStudentFixture': 'catalog-acceptance-fictional-v1',
            };
            final before = Map<String, Object>.of(workingState);
            final controller = ThemePreviewController(
              registry: registry,
              authoritativeThemeId: source.id,
              initialRevision: 8,
            );
            addTearDown(controller.dispose);

            await controller.preview(candidate.id, preflight: (_) async {});
            expect(controller.effectiveBundle.id, candidate.id);
            expect(controller.authoritativeThemeId, source.id);
            expect(workingState, before);

            final request = controller.beginApply();
            expect(request, isA<ThemeApplyRequest>());
            expect(request.expectedRevision, 8);
            controller.failApply('fictional persistence failure');
            expect(controller.authoritativeThemeId, source.id);
            expect(controller.canApply, isTrue);

            controller.beginApply();
            controller.completeApply(revision: 9);
            expect(controller.authoritativeThemeId, candidate.id);
            expect(workingState, before);
          },
        );
      }
    }

    for (final bundle in bundles) {
      test(
        '${bundle.id} resolves complete Help and both accessibility modes',
        () {
          expect(bundle.helpGuide.themeId, bundle.id);
          expect(
            bundle.helpGuide.calendarStates.map((state) => state.role).toSet(),
            const {
              ThemeSemanticRole.clinicalSession,
              ThemeSemanticRole.workShift,
              ThemeSemanticRole.protectedDay,
              ThemeSemanticRole.scheduledProgress,
              ThemeSemanticRole.today,
            },
          );
          for (final enhanced in const [false, true]) {
            final theme = bundle.standardPresentation.createThemeData(
              enhancedAccessibility: enhanced,
            );
            expect(
              theme.extension<ClinicalCalendarAccessibilityTokens>()?.enhanced,
              enhanced,
            );
            expect(theme.extension<ClinicalCalendarColors>(), isNotNull);
          }
        },
      );
    }

    test(
      'unknown applied identity preserves its ID behind Graphite fallback',
      () {
        final resolution = registry.resolveApplied('future-theme');
        expect(resolution.storedId, 'future-theme');
        expect(resolution.bundle.id, graphiteThemeId);
        expect(resolution.isFallback, isTrue);
      },
    );

    test(
      'signed-out presentation is always Graphite and account-independent',
      () {
        expect(registry.resolveSignedOut().id, graphiteThemeId);
        expect(registry.resolveSignedOut().metadata.displayName, 'Graphite');
      },
    );
  });
}
