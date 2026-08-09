import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/theme_acceptance_harness.dart';

void main() {
  testWidgets(
    'writes reviewable Pending evidence for every implemented bundle',
    (tester) async {
      const configuredOutput = String.fromEnvironment(
        'THEME_ACCEPTANCE_OUTPUT_DIR',
      );
      final ownsOutput = configuredOutput.isEmpty;
      final output =
          ownsOutput
                ? (await tester.runAsync(
                    () => Directory.systemTemp.createTemp('theme-acceptance-'),
                  ))!
                : Directory(configuredOutput)
            ..createSync(recursive: true);
      if (ownsOutput) addTearDown(() => output.deleteSync(recursive: true));

      final packageRoot =
          Directory.current.path.endsWith('clinical_calendar_presentation')
          ? Directory.current
          : Directory('packages/clinical_calendar_presentation');
      final registry = ClinicalCalendarThemeBundleRegistry.standard;
      final registryGate = ThemeRegistryAcceptanceAuditor.audit(registry);
      for (final bundle in registry.galleryBundles) {
        final themeDirectory = Directory('${output.path}/${bundle.id}')
          ..createSync(recursive: true);
        final standard = await auditRuntimeBundle(
          tester,
          bundle,
          ThemeAccessibilityMode.standard,
        );
        final enhanced = await auditRuntimeBundle(
          tester,
          bundle,
          ThemeAccessibilityMode.enhanced,
        );
        final tokenReports = [standard, enhanced];
        for (final report in tokenReports) {
          File(
            '${themeDirectory.path}/runtime-tokens-${report.mode.name}.json',
          ).writeAsStringSync(_pretty(report.toJson()));
        }

        final fixture = themeRasterAcceptanceFixture(bundle.id);
        final asset = (await tester.runAsync(
          () async => ThemeAssetAcceptanceAuditor.auditPrimaryFrame(
            bundle: bundle,
            bytes: await File(
              '${packageRoot.path}/${bundle.frame.primaryAsset}',
            ).readAsBytes(),
            evidence: ThemeAssetEvidence(
              assetPath: bundle.frame.primaryAsset,
              expectedSha256: fixture.expectedSha256,
              creationRecordUri: fixture.creationRecordUri,
              comparisonCaptureUri: '',
              originalityReviewer: '',
              originalityApprovedAtUtc: DateTime.utc(2026, 8, 8),
              originalityApproved: false,
              operationalContentAbsent: false,
            ),
          ),
        ))!;
        File(
          '${themeDirectory.path}/primary-frame.json',
        ).writeAsStringSync(_pretty(asset.toJson()));

        File(
          '${themeDirectory.path}/thumbnail-capture-required.json',
        ).writeAsStringSync(
          _pretty({
            'status': 'runtime-capture-required',
            'rendererVersion': bundle.shellRenderer.rendererId,
            'fixture': bundle.gallery.thumbnailFixtureId,
            'width': bundle.gallery.thumbnailViewport.width.round(),
            'height': bundle.gallery.thumbnailViewport.height.round(),
            'sha256': null,
            'capture': null,
            'swatches': [
              for (final swatch in bundle.gallery.swatches)
                {
                  'role': swatch.role.name,
                  'label': swatch.label,
                  'argb': swatch.color.toARGB32(),
                },
            ],
          }),
        );

        File(
          '${themeDirectory.path}/performance-schema-example.json',
        ).writeAsStringSync(
          _pretty({
            'status': 'measurement-required',
            'baselineReport':
                'docs/performance/evidence/containment-drone-profile.json',
            'candidate': {
              'frameIntervalMs': null,
              'uiThreadFrameTimeMsP95': null,
              'rasterThreadFrameTimeMsP95': null,
              'retainedMemoryBytes': null,
              'releaseSizeBytes': null,
              'swapLatencyMs': null,
              'retainedMemoryAfter25CyclesBytes': null,
              'monotonicRetainedMemoryGrowth': null,
              'releaseSizeAttributionByAssetSha256': null,
              'manifestAssetSha256': null,
            },
          }),
        );

        final tokenFailures = [
          for (final report in tokenReports)
            for (final entry in report.entries)
              if (!entry.passed) '${report.mode.name}: ${entry.pairingId}',
        ];
        final manifest = ThemeEvidenceManifest(
          candidateCommit: const String.fromEnvironment(
            'THEME_ACCEPTANCE_COMMIT',
            defaultValue: '0000000000000000000000000000000000000000',
          ),
          buildNumber: const int.fromEnvironment(
            'THEME_ACCEPTANCE_BUILD',
            defaultValue: 1,
          ),
          themeId: bundle.id,
          displayName: bundle.metadata.displayName,
          fixtureId: 'catalog-acceptance-fictional-v1',
          capturedAtUtc: DateTime.now().toUtc(),
          environment: const ThemeAcceptanceEnvironment(
            platform: 'Flutter test host',
            deviceModel: 'automated-contract-runner',
            osVersion: 'host-managed',
            displayMode: 'contract-only',
            orientation: 'not-applicable',
            refreshRateHz: 120,
          ),
          assetHashes: {bundle.frame.primaryAsset: asset.sha256},
          reportUris: const [
            'runtime-tokens-standard.json',
            'runtime-tokens-enhanced.json',
            'primary-frame.json',
            'thumbnail-capture-required.json',
            'performance-schema-example.json',
          ],
          captureUris: const [],
          ciRunUri: '',
          manualChecklistUris: const [],
          accessibilityScannerReportUri: '',
          approvedSignerSha256: '',
          retrievedEvidenceSha256: const {},
          contrastExceptions: const [],
          gates: [
            ThemeAcceptanceGateResult(
              gateId: ThemeAcceptanceGateId.runtimeTokens,
              passed: tokenFailures.isEmpty,
              failures: tokenFailures,
            ),
            registryGate,
            asset.gate,
          ],
          maintainerDecision: ThemeMaintainerDecision.pending,
        );
        final encoded = _pretty(manifest.toJson());
        File('${themeDirectory.path}/manifest.json').writeAsStringSync(encoded);

        expect(manifest.acceptanceState, ThemeAcceptanceState.pending);
        expect(encoded, isNot(contains('@')));
        expect(
          jsonDecode(
            File('${themeDirectory.path}/manifest.json').readAsStringSync(),
          ),
          containsPair('themeId', bundle.id),
        );
      }
    },
  );
}

String _pretty(Object value) =>
    const JsonEncoder.withIndent('  ').convert(value);
