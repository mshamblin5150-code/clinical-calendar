import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'support/theme_acceptance_harness.dart';

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
        test('${bundle.id} ${mode.name} audits actual runtime state layers', () {
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
          if (bundle.id == federationClassicThemeId ||
              bundle.id == federation2399ThemeId ||
              bundle.id == heritageFieldNotesThemeId) {
            expect(
              report.passed,
              isTrue,
              reason: report.entries
                  .where((entry) => !entry.passed)
                  .map(
                    (entry) =>
                        '${entry.pairingId}: ${entry.contrastRatio.toStringAsFixed(2)} / ${entry.requiredRatio.toStringAsFixed(2)}',
                  )
                  .join('\n'),
            );
          }
          expect(
            report.entries.every(
              (entry) =>
                  entry.compositedForeground.a == 1 &&
                  entry.compositedBackground.a == 1,
            ),
            isTrue,
          );
          expect(report.toJson()['themeId'], bundle.id);
        });
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

    test('resolved pressed overlay participates in the runtime ratio', () {
      final bundle = ClinicalCalendarThemeBundleRegistry.standard.galleryBundles
          .singleWhere((item) => item.id == graphiteThemeId);
      final base = bundle.standardPresentation.createThemeData();
      final theme = base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: (base.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.black),
          ),
        ),
      );
      final report = ThemeRuntimeTokenAuditor.auditThemeData(
        themeId: bundle.id,
        theme: theme,
        colors: theme.extension<ClinicalCalendarColors>()!,
        accessibility: theme.extension<ClinicalCalendarAccessibilityTokens>(),
        mode: ThemeAccessibilityMode.standard,
      );

      final pressed = report.entries.singleWhere(
        (entry) => entry.pairingId == 'filled-pressed',
      );
      expect(pressed.compositedBackground, Colors.black);
      expect(pressed.passed, isFalse);
    });
  });

  group('reviewable evidence', () {
    test('contrast exceptions identify an exact Enhanced state', () {
      const valid = ThemeContrastException(
        pairingId: 'filled-pressed',
        state: ThemeTokenState.pressed,
        contentKind: ThemeContrastContentKind.normalText,
        mode: ThemeAccessibilityMode.enhanced,
        standardMeasuredRatio: 4.8,
        measuredRatio: 6.5,
        rationale: 'Fictional approved large state-layer exception.',
        redundantCue: 'Persistent label and pressed border.',
        maintainerApproved: true,
      );
      expect(valid.isValidEnhancedException, isTrue);
      expect(
        const ThemeContrastException(
          pairingId: 'filled-pressed',
          state: ThemeTokenState.pressed,
          contentKind: ThemeContrastContentKind.normalText,
          mode: ThemeAccessibilityMode.standard,
          standardMeasuredRatio: 4.8,
          measuredRatio: 4.6,
          rationale: 'Wrong mode.',
          redundantCue: 'Pressed border.',
          maintainerApproved: true,
        ).isValidEnhancedException,
        isFalse,
      );
    });

    test('evidence references reject credential keys and fragments', () {
      for (final key in const [
        'key',
        'api_key',
        'db_key',
        'database-key',
        'privateKey',
        'signing_key',
        'client_secret',
        'secret',
        'auth',
        'authorization',
        'credential',
        'token',
        'signature',
      ]) {
        expect(
          ThemeEvidenceSafety.isSafeReference(
            'https://evidence.invalid/report?$key=fictional-secret',
          ),
          isFalse,
          reason: key,
        );
        expect(
          ThemeEvidenceSafety.isSafeReference(
            'https://evidence.invalid/report#$key=fictional-secret',
          ),
          isFalse,
          reason: 'fragment $key',
        );
      }
      expect(
        ThemeEvidenceSafety.isSafeReference(
          'https://evidence.invalid/report?run=123&theme=graphite',
        ),
        isTrue,
      );
    });

    test('manifest identifies the candidate and rejects identifying fixtures', () {
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
        ciRunUri: 'https://github.com/example/actions/runs/123',
        manualChecklistUris: const ['checklists/android-tablet.md'],
        accessibilityScannerReportUri: 'reports/accessibility-scanner.json',
        approvedSignerSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        retrievedEvidenceSha256: const {
          'reports/runtime-tokens.json':
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          'captures/calendar.png':
              'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          'https://github.com/example/actions/runs/123':
              'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
          'checklists/android-tablet.md':
              'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
          'reports/accessibility-scanner.json':
              'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        },
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
        ciRunUri: manifest.ciRunUri,
        manualChecklistUris: manifest.manualChecklistUris,
        accessibilityScannerReportUri: manifest.accessibilityScannerReportUri,
        approvedSignerSha256: manifest.approvedSignerSha256,
        retrievedEvidenceSha256: manifest.retrievedEvidenceSha256,
        contrastExceptions: const [],
        gates: const [],
        maintainerDecision: ThemeMaintainerDecision.pending,
      );
      expect(unsafe.validationFailures, isNotEmpty);

      final credentialLink = ThemeEvidenceManifest(
        candidateCommit: manifest.candidateCommit,
        buildNumber: manifest.buildNumber,
        themeId: manifest.themeId,
        displayName: manifest.displayName,
        fixtureId: manifest.fixtureId,
        capturedAtUtc: manifest.capturedAtUtc,
        environment: manifest.environment,
        assetHashes: manifest.assetHashes,
        reportUris: const ['https://evidence.invalid/report?token=secret'],
        captureUris: manifest.captureUris,
        ciRunUri: manifest.ciRunUri,
        manualChecklistUris: manifest.manualChecklistUris,
        accessibilityScannerReportUri: manifest.accessibilityScannerReportUri,
        approvedSignerSha256: manifest.approvedSignerSha256,
        retrievedEvidenceSha256: const {
          'https://evidence.invalid/report?token=secret':
              'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
          'captures/calendar.png':
              'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
          'https://github.com/example/actions/runs/123':
              'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
          'checklists/android-tablet.md':
              'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
          'reports/accessibility-scanner.json':
              'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        },
        contrastExceptions: const [],
        gates: const [],
        maintainerDecision: ThemeMaintainerDecision.pending,
      );
      expect(
        credentialLink.validationFailures,
        contains(contains('credentials')),
      );
    });

    for (final bundle
        in ClinicalCalendarThemeBundleRegistry.standard.galleryBundles) {
      test('${bundle.id} performance contract evaluates every measurement', () {
        final manifest = _performanceManifest(bundle);
        final approvedAssetHash = themeRasterAcceptanceFixture(
          bundle.id,
        ).expectedSha256;
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
          releaseSizeAttributionByAssetSha256: {approvedAssetHash: 1000000},
        ).evaluate(manifest: manifest);
        expect(passing.passed, isTrue);

        final failed = ThemePerformanceEvidence(
          baseline: baseline,
          candidate: passingCandidate,
          swapLatencyMs: 251,
          retainedMemoryAfterCyclesBytes: 221000000,
          monotonicRetainedMemoryGrowth: false,
          releaseSizeAttributionByAssetSha256: {approvedAssetHash: 1000000},
        ).evaluate(manifest: manifest);
        expect(failed.passed, isFalse);
        expect(failed.failures, contains(contains('250')));

        final overAttributed = ThemePerformanceEvidence(
          baseline: baseline,
          candidate: passingCandidate,
          swapLatencyMs: 180,
          retainedMemoryAfterCyclesBytes: 221000000,
          monotonicRetainedMemoryGrowth: false,
          releaseSizeAttributionByAssetSha256: {approvedAssetHash: 1000001},
        ).evaluate(manifest: manifest);
        expect(overAttributed.passed, isFalse);
        expect(
          overAttributed.failures,
          contains(contains('exact attribution')),
        );

        const invented = ThemePerformanceMeasurement(
          frameIntervalMs: 8.333,
          uiThreadFrameTimeMsP95: 0,
          rasterThreadFrameTimeMsP95: 0,
          retainedMemoryBytes: 0,
          releaseSizeBytes: 0,
        );
        expect(
          const ThemePerformanceEvidence(
            baseline: baseline,
            candidate: invented,
            swapLatencyMs: 0,
            retainedMemoryAfterCyclesBytes: 0,
            monotonicRetainedMemoryGrowth: false,
            releaseSizeAttributionByAssetSha256: {},
          ).evaluate(manifest: manifest).passed,
          isFalse,
        );
      });
    }
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
          final fixture = themeRasterAcceptanceFixture(bundle.id);
          final report = await ThemeAssetAcceptanceAuditor.auditPrimaryFrame(
            bundle: bundle,
            bytes: await File(
              '${packageRoot.path}/${bundle.frame.primaryAsset}',
            ).readAsBytes(),
            evidence: ThemeAssetEvidence(
              assetPath: bundle.frame.primaryAsset,
              expectedSha256: fixture.expectedSha256,
              creationRecordUri: fixture.creationRecordUri,
              comparisonCaptureUri:
                  'captures/${bundle.id}-originality-comparison.png',
              originalityReviewer: 'Maintainer',
              originalityApprovedAtUtc: DateTime.utc(2026, 8, 8),
              originalityApproved: true,
              operationalContentAbsent: true,
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

    for (final bundle in bundles) {
      test(
        '${bundle.id} thumbnail auditor verifies bytes and runtime swatches',
        () async {
          final bytes = img.encodeBmp(
            img.Image(
              width: bundle.gallery.thumbnailViewport.width.round(),
              height: bundle.gallery.thumbnailViewport.height.round(),
              numChannels: 4,
            ),
          );
          final evidence = ThemeThumbnailEvidence(
            themeId: bundle.id,
            rendererVersion: bundle.shellRenderer.rendererId,
            fixtureId: bundle.gallery.thumbnailFixtureId,
            viewport: bundle.gallery.thumbnailViewport,
            sha256: sha256.convert(bytes).toString(),
            captureUri: 'captures/${bundle.id}-thumbnail.bmp',
            fictionalFixture: true,
            swatches: [
              for (final swatch in bundle.gallery.swatches)
                ThemeThumbnailSwatchEvidence(
                  role: swatch.role,
                  label: swatch.label,
                  color: swatch.color,
                ),
            ],
          );

          expect(
            (await ThemeThumbnailAcceptanceAuditor.audit(
              bundle: bundle,
              bytes: bytes,
              evidence: evidence,
            )).passed,
            isTrue,
          );
          expect(
            (await ThemeThumbnailAcceptanceAuditor.audit(
              bundle: bundle,
              bytes: utf8.encode('stale-thumbnail'),
              evidence: evidence,
            )).passed,
            isFalse,
          );
        },
      );
    }

    testWidgets(
      'Federation Classic thumbnail evidence comes from its real renderer',
      (tester) async {
        final bundle = bundles.singleWhere(
          (item) => item.id == federationClassicThemeId,
        );
        await tester.binding.setSurfaceSize(bundle.gallery.thumbnailViewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox.fromSize(
              size: bundle.gallery.thumbnailViewport,
              child: ThemeRuntimeThumbnail(bundle: bundle),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final thumbnail = find.byKey(
          Key('theme-gallery-thumbnail-${bundle.id}'),
        );
        expect(tester.getSize(thumbnail), bundle.gallery.thumbnailViewport);
        await expectLater(
          thumbnail,
          matchesGoldenFile('goldens/federation_classic_runtime_thumbnail.png'),
        );
        expect(find.byType(FederationClassicNineSliceFrame), findsOneWidget);
        expect(find.byType(GraphiteNineSliceFrame), findsNothing);
        expect(find.byType(VariantFNineSliceFrame), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    test('Federation Classic captured runtime thumbnail is audited', () async {
      final bundle = bundles.singleWhere(
        (item) => item.id == federationClassicThemeId,
      );
      final bytes = await File(
        '${packageRoot.path}/test/goldens/'
        'federation_classic_runtime_thumbnail.png',
      ).readAsBytes();
      final evidence = ThemeThumbnailEvidence(
        themeId: bundle.id,
        rendererVersion: bundle.shellRenderer.rendererId,
        fixtureId: bundle.gallery.thumbnailFixtureId,
        viewport: bundle.gallery.thumbnailViewport,
        sha256: sha256.convert(bytes).toString(),
        captureUri: 'captures/${bundle.id}-runtime-thumbnail.png',
        fictionalFixture: true,
        swatches: [
          for (final swatch in bundle.gallery.swatches)
            ThemeThumbnailSwatchEvidence(
              role: swatch.role,
              label: swatch.label,
              color: swatch.color,
            ),
        ],
      );

      final result = await ThemeThumbnailAcceptanceAuditor.audit(
        bundle: bundle,
        bytes: bytes,
        evidence: evidence,
      );
      expect(result.passed, isTrue, reason: result.failures.join('\n'));
    });

    testWidgets(
      'Federation 2399 thumbnail evidence comes from its real renderer',
      (tester) async {
        final bundle = bundles.singleWhere(
          (item) => item.id == federation2399ThemeId,
        );
        await tester.binding.setSurfaceSize(bundle.gallery.thumbnailViewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox.fromSize(
              size: bundle.gallery.thumbnailViewport,
              child: ThemeRuntimeThumbnail(bundle: bundle),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final thumbnail = find.byKey(
          Key('theme-gallery-thumbnail-${bundle.id}'),
        );
        expect(tester.getSize(thumbnail), bundle.gallery.thumbnailViewport);
        await expectLater(
          thumbnail,
          matchesGoldenFile('goldens/federation_2399_runtime_thumbnail.png'),
        );
        expect(find.byType(Federation2399NineSliceFrame), findsOneWidget);
        expect(find.byType(GraphiteNineSliceFrame), findsNothing);
        expect(find.byType(VariantFNineSliceFrame), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    test('Federation 2399 captured runtime thumbnail is audited', () async {
      final bundle = bundles.singleWhere(
        (item) => item.id == federation2399ThemeId,
      );
      final bytes = await File(
        '${packageRoot.path}/test/goldens/'
        'federation_2399_runtime_thumbnail.png',
      ).readAsBytes();
      final evidence = ThemeThumbnailEvidence(
        themeId: bundle.id,
        rendererVersion: bundle.shellRenderer.rendererId,
        fixtureId: bundle.gallery.thumbnailFixtureId,
        viewport: bundle.gallery.thumbnailViewport,
        sha256: sha256.convert(bytes).toString(),
        captureUri: 'captures/${bundle.id}-runtime-thumbnail.png',
        fictionalFixture: true,
        swatches: [
          for (final swatch in bundle.gallery.swatches)
            ThemeThumbnailSwatchEvidence(
              role: swatch.role,
              label: swatch.label,
              color: swatch.color,
            ),
        ],
      );

      final result = await ThemeThumbnailAcceptanceAuditor.audit(
        bundle: bundle,
        bytes: bytes,
        evidence: evidence,
      );
      expect(result.passed, isTrue, reason: result.failures.join('\n'));
    });

    testWidgets(
      'Field Archive thumbnail evidence comes from its real renderer',
      (tester) async {
        final bundle = bundles.singleWhere(
          (item) => item.id == heritageFieldNotesThemeId,
        );
        await tester.binding.setSurfaceSize(bundle.gallery.thumbnailViewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox.fromSize(
              size: bundle.gallery.thumbnailViewport,
              child: ThemeRuntimeThumbnail(bundle: bundle),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        final thumbnail = find.byKey(
          Key('theme-gallery-thumbnail-${bundle.id}'),
        );
        expect(tester.getSize(thumbnail), bundle.gallery.thumbnailViewport);
        await expectLater(
          thumbnail,
          matchesGoldenFile(
            'goldens/heritage_field_notes_runtime_thumbnail.png',
          ),
        );
        expect(find.byType(HeritageFieldNotesNineSliceFrame), findsOneWidget);
        expect(find.byType(Federation2399NineSliceFrame), findsNothing);
        expect(find.byType(GraphiteNineSliceFrame), findsNothing);
        expect(find.byType(VariantFNineSliceFrame), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    test('Field Archive captured runtime thumbnail is audited', () async {
      final bundle = bundles.singleWhere(
        (item) => item.id == heritageFieldNotesThemeId,
      );
      final bytes = await File(
        '${packageRoot.path}/test/goldens/'
        'heritage_field_notes_runtime_thumbnail.png',
      ).readAsBytes();
      final evidence = ThemeThumbnailEvidence(
        themeId: bundle.id,
        rendererVersion: bundle.shellRenderer.rendererId,
        fixtureId: bundle.gallery.thumbnailFixtureId,
        viewport: bundle.gallery.thumbnailViewport,
        sha256: sha256.convert(bytes).toString(),
        captureUri: 'captures/${bundle.id}-runtime-thumbnail.png',
        fictionalFixture: true,
        swatches: [
          for (final swatch in bundle.gallery.swatches)
            ThemeThumbnailSwatchEvidence(
              role: swatch.role,
              label: swatch.label,
              color: swatch.color,
            ),
        ],
      );

      final result = await ThemeThumbnailAcceptanceAuditor.audit(
        bundle: bundle,
        bytes: bytes,
        evidence: evidence,
      );
      expect(result.passed, isTrue, reason: result.failures.join('\n'));
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
        testWidgets(
          '${source.id} to ${candidate.id} preserves working state and persists only on Apply',
          (tester) async {
            await tester.binding.setSurfaceSize(const Size(800, 600));
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final controller = ThemePreviewController(
              registry: registry,
              authoritativeThemeId: source.id,
              initialRevision: 8,
            );
            addTearDown(controller.dispose);
            final fixtureKey = GlobalKey<_AcceptanceWorkingStateState>();
            await tester.pumpWidget(
              _AcceptanceWorkingState(
                key: fixtureKey,
                previewController: controller,
              ),
            );
            final state = fixtureKey.currentState!;
            final sourceEffectiveId = registry
                .resolveApplied(source.id)
                .bundle
                .id;
            final candidateEffectiveId = registry
                .resolveApplied(candidate.id)
                .bundle
                .id;
            final workflowController = state.workflowController;
            await tester.enterText(
              find.byKey(const Key('acceptance-unsaved-field')),
              'fictional draft edited',
            );
            state.scrollController.jumpTo(312.5);
            state.focusNode.requestFocus();
            await tester.pump();

            await controller.preview(candidate.id, preflight: (_) async {});
            await tester.pump();
            expect(controller.effectiveBundle.id, candidate.id);
            expect(controller.effectiveBundle.helpGuide.themeId, candidate.id);
            expect(controller.authoritativeThemeId, source.id);
            _expectWorkingStatePreserved(
              state,
              workflowController: workflowController,
            );

            controller.revert();
            await tester.pump();
            expect(controller.effectiveBundle.id, sourceEffectiveId);
            expect(
              controller.effectiveBundle.helpGuide.themeId,
              sourceEffectiveId,
            );
            _expectWorkingStatePreserved(
              state,
              workflowController: workflowController,
            );

            await controller.preview(candidate.id, preflight: (_) async {});
            await tester.pump();

            final request = controller.beginApply();
            expect(request, isA<ThemeApplyRequest>());
            expect(request.expectedRevision, 8);
            controller.failApply('fictional persistence failure');
            await tester.pump();
            expect(controller.authoritativeThemeId, source.id);
            expect(controller.canApply, isTrue);

            controller.beginApply();
            controller.completeApply(revision: 9);
            await tester.pump();
            expect(controller.authoritativeThemeId, candidate.id);
            expect(controller.effectiveBundle.id, candidateEffectiveId);
            _expectWorkingStatePreserved(
              state,
              workflowController: workflowController,
            );

            final restarted = ThemePreviewController(
              registry: registry,
              authoritativeThemeId: controller.authoritativeThemeId,
              initialRevision: controller.authoritativeRevision,
            );
            addTearDown(restarted.dispose);
            expect(restarted.effectiveBundle.id, candidateEffectiveId);
            expect(restarted.authoritativeRevision, 9);
          },
        );
      }
    }

    for (final bundle in bundles) {
      test(
        '${bundle.id} resolves complete Help and both accessibility modes',
        () {
          expect(bundle.helpGuide.themeId, bundle.id);
          expect(bundle.helpGuide.title.trim(), isNotEmpty);
          expect(
            bundle.helpGuide.calendarStates.map((state) => state.role),
            const [
              ThemeSemanticRole.clinicalSession,
              ThemeSemanticRole.workShift,
              ThemeSemanticRole.protectedDay,
              ThemeSemanticRole.scheduledProgress,
              ThemeSemanticRole.today,
            ],
          );
          for (final state in bundle.helpGuide.calendarStates) {
            expect(state.label.trim(), isNotEmpty);
            expect(state.description.trim(), isNotEmpty);
            expect(state.nonColorCue.trim(), isNotEmpty);
            expect(state.enhancedBehavior.trim(), isNotEmpty);
            expect(
              bundle.marks.forRole(state.role).description.trim(),
              isNotEmpty,
            );
          }
          for (final enhanced in const [false, true]) {
            final theme = bundle.standardPresentation.createThemeData(
              enhancedAccessibility: enhanced,
            );
            final tokens = theme
                .extension<ClinicalCalendarAccessibilityTokens>()!;
            expect(tokens.enhanced, enhanced);
            expect(tokens.focusWidth, greaterThan(0));
            expect(tokens.selectionWidth, greaterThan(0));
            if (enhanced) {
              expect(tokens.focusWidth, greaterThanOrEqualTo(3));
              expect(tokens.selectionWidth, greaterThanOrEqualTo(3));
            }
            expect(tokens.persistentExpandedLegend, enhanced);
            expect(tokens.decorationOpacity, inInclusiveRange(0, 1));
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
        expect(resolution.bundle.helpGuide.themeId, graphiteThemeId);
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

final class _AcceptanceWorkingState extends StatefulWidget {
  const _AcceptanceWorkingState({super.key, required this.previewController});

  final ThemePreviewController previewController;

  @override
  State<_AcceptanceWorkingState> createState() =>
      _AcceptanceWorkingStateState();
}

final class _AcceptanceWorkingStateState
    extends State<_AcceptanceWorkingState> {
  final textController = TextEditingController(text: 'fictional draft');
  final scrollController = ScrollController();
  final focusNode = FocusNode(debugLabel: 'acceptance-unsaved-field');
  final workflowController = Object();
  final destination = 'Settings';
  final calendarPeriod = 'August 2026';
  final calendarSelection = '2026-08-07';
  final loadedStudentFixture = 'catalog-acceptance-fictional-v1';

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.previewController,
    builder: (context, _) => MaterialApp(
      theme: widget.previewController.effectiveBundle.standardPresentation
          .createThemeData(),
      home: Scaffold(
        body: SingleChildScrollView(
          key: const Key('acceptance-working-scroll'),
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.previewController.effectiveBundle.id,
                key: const Key('acceptance-effective-theme'),
              ),
              Text(destination),
              Text(calendarPeriod),
              Text(calendarSelection),
              Text(loadedStudentFixture),
              TextField(
                key: const Key('acceptance-unsaved-field'),
                controller: textController,
                focusNode: focusNode,
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    ),
  );
}

void _expectWorkingStatePreserved(
  _AcceptanceWorkingStateState state, {
  required Object workflowController,
}) {
  expect(state.mounted, isTrue);
  expect(state.destination, 'Settings');
  expect(state.calendarPeriod, 'August 2026');
  expect(state.calendarSelection, '2026-08-07');
  expect(state.loadedStudentFixture, 'catalog-acceptance-fictional-v1');
  expect(state.textController.text, 'fictional draft edited');
  expect(state.scrollController.offset, closeTo(312.5, .01));
  expect(state.focusNode.hasFocus, isTrue);
  expect(state.workflowController, same(workflowController));
}

ThemeEvidenceManifest _performanceManifest(
  ClinicalCalendarThemeBundle bundle,
) => ThemeEvidenceManifest(
  candidateCommit: '0123456789abcdef0123456789abcdef01234567',
  buildNumber: 41,
  themeId: bundle.id,
  displayName: bundle.metadata.displayName,
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
  assetHashes: {
    bundle.frame.primaryAsset: themeRasterAcceptanceFixture(
      bundle.id,
    ).expectedSha256,
  },
  reportUris: const ['reports/performance.json'],
  captureUris: const ['captures/performance.png'],
  ciRunUri: 'https://github.com/example/actions/runs/123',
  manualChecklistUris: const ['checklists/android-tablet.md'],
  accessibilityScannerReportUri: 'reports/accessibility-scanner.json',
  approvedSignerSha256:
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  retrievedEvidenceSha256: const {
    'reports/performance.json':
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    'captures/performance.png':
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'https://github.com/example/actions/runs/123':
        'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
    'checklists/android-tablet.md':
        'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
    'reports/accessibility-scanner.json':
        'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
  },
  contrastExceptions: const [],
  gates: const [],
  maintainerDecision: ThemeMaintainerDecision.pending,
);
