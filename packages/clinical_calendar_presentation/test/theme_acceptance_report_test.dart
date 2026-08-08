import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'writes reviewable Pending evidence for every implemented bundle',
    () async {
      const configuredOutput = String.fromEnvironment(
        'THEME_ACCEPTANCE_OUTPUT_DIR',
      );
      final ownsOutput = configuredOutput.isEmpty;
      final output =
          ownsOutput
                ? await Directory.systemTemp.createTemp('theme-acceptance-')
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
        final standard = ThemeRuntimeTokenAuditor.audit(
          bundle: bundle,
          mode: ThemeAccessibilityMode.standard,
        );
        final enhanced = ThemeRuntimeTokenAuditor.audit(
          bundle: bundle,
          mode: ThemeAccessibilityMode.enhanced,
        );
        final tokenReports = [standard, enhanced];
        for (final report in tokenReports) {
          File(
            '${themeDirectory.path}/runtime-tokens-${report.mode.name}.json',
          ).writeAsStringSync(_pretty(report.toJson()));
        }

        final expectedHash = switch (bundle.id) {
          variantFThemeId =>
            '9ff3968a94d497dc6f76f2b14f370c5a24c3bb4969397ee220da005093c15ad7',
          graphiteThemeId =>
            '4865763bc6e0ab118ceda4f437d29595ed0d599078f9454724bb498b3fbc9a15',
          _ => throw StateError('No primary-frame fixture for ${bundle.id}.'),
        };
        final asset = await ThemeAssetAcceptanceAuditor.auditPrimaryFrame(
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
        File(
          '${themeDirectory.path}/primary-frame.json',
        ).writeAsStringSync(_pretty(asset.toJson()));

        const baseline = ThemePerformanceMeasurement(
          frameIntervalMs: 8.333,
          uiThreadFrameTimeMsP95: 3.403,
          rasterThreadFrameTimeMsP95: 5.627,
          retainedMemoryBytes: 219508000,
          releaseSizeBytes: 0,
        );
        const pendingPerformance = ThemePerformanceEvidence(
          baseline: baseline,
          candidate: baseline,
          swapLatencyMs: 0,
          retainedMemoryAfterCyclesBytes: 219508000,
          monotonicRetainedMemoryGrowth: false,
          attributedReleaseGrowthBytes: 0,
        );
        File(
          '${themeDirectory.path}/performance-schema-example.json',
        ).writeAsStringSync(_pretty(pendingPerformance.toJson()));

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
            'performance-schema-example.json',
          ],
          captureUris: const [],
          contrastExceptions: const [],
          gates: [
            ThemeAcceptanceGateResult(
              gateId: ThemeAcceptanceGateId.runtimeTokens,
              passed: tokenFailures.isEmpty,
              failures: tokenFailures,
            ),
            registryGate,
            asset.gate,
            pendingPerformance.evaluate(),
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
