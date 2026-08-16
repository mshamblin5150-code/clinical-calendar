import 'dart:io';

import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/src/canonical_delta_mark.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inScopeThemes = <ClinicalCalendarThemeBundle>[
    VariantFThemeBundle(),
    GraphiteThemeBundle(),
    CoastalLightThemeBundle(),
    BotanicalStudyThemeBundle(),
    HeritageFieldNotesThemeBundle(),
    FederationClassicThemeBundle(),
    Federation2399ThemeBundle(),
  ];

  testWidgets('all seven themes render the canonical delta source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final bundle in inScopeThemes) {
      expect(
        bundle.frame.assetPaths,
        contains(canonicalDeltaMarkAsset),
        reason: '${bundle.id} must declare the canonical delta dependency',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: bundle.standardPresentation.createThemeData(),
          home: bundle.shellRenderer.build(
            slots: _slots,
            environmentName: 'TEST',
            onOpenMenu: _noop,
            onOpenDestination: _ignoreDestination,
            onOpenAttention: _noop,
            onAddSchedule: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(CanonicalDeltaMark),
        findsOneWidget,
        reason: '${bundle.id} must render through the shared mark widget',
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('the package bundles exactly one delta mark raster', () async {
    final assetDirectory = _assetDirectory();
    final deltaAssets = await assetDirectory
        .list(recursive: true)
        .where((entry) => entry is File)
        .map((entry) => entry.path.replaceAll('\\', '/'))
        .where(
          (path) => RegExp(
            r'(?:axion.*delta|delta.*mark)',
            caseSensitive: false,
          ).hasMatch(path),
        )
        .map((path) => path.substring(path.indexOf('assets/')))
        .toList();

    expect(deltaAssets, [canonicalDeltaMarkAsset]);
    final canonicalFile = File(
      '${assetDirectory.parent.path}${Platform.pathSeparator}'
      '$canonicalDeltaMarkAsset',
    );
    final canonicalDigest = sha256.convert(await canonicalFile.readAsBytes());
    expect(
      canonicalDigest.toString(),
      '9e5c841e8781d518fe4b8052f7febe921a3a26899cc1deb769ddf0feacfeacc7',
      reason: 'the canonical source must retain the approved metallic mark',
    );

    final identicalAssets = <String>[];
    final allAssets = await assetDirectory
        .list(recursive: true)
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    for (final asset in allAssets) {
      if (sha256.convert(await asset.readAsBytes()) == canonicalDigest) {
        identicalAssets.add(
          asset.path
              .replaceAll('\\', '/')
              .substring(asset.path.replaceAll('\\', '/').indexOf('assets/')),
        );
      }
    }
    expect(
      identicalAssets,
      [canonicalDeltaMarkAsset],
      reason: 'a renamed byte-for-byte delta copy is still a duplicate',
    );
  });

  test(
    'theme sources cannot restore local Axion delta painters or assets',
    () async {
      final packageDirectory = _assetDirectory().parent;
      const shellPaths = [
        'lib/src/graphite_shell.dart',
        'lib/src/coastal_light_shell.dart',
        'lib/src/botanical_study_shell.dart',
        'lib/src/heritage_field_notes_shell.dart',
        'lib/src/federation_classic_shell.dart',
        'lib/src/federation_2399_shell.dart',
        'lib/src/containment_drone_shell.dart',
      ];
      final localDeltaPainter = RegExp(
        r'class\s+\S*(?:Axion|Delta)\S*Painter',
        caseSensitive: false,
      );

      for (final relativePath in shellPaths) {
        final source = await File(
          '${packageDirectory.path}${Platform.pathSeparator}'
          '${relativePath.replaceAll('/', Platform.pathSeparator)}',
        ).readAsString();
        final expectedReferences = switch (relativePath) {
          'lib/src/graphite_shell.dart' ||
          'lib/src/heritage_field_notes_shell.dart' => 2,
          'lib/src/containment_drone_shell.dart' => 2,
          _ => 1,
        };
        expect(
          RegExp(r'CanonicalDeltaMark\(').allMatches(source),
          hasLength(expectedReferences),
          reason:
              '$relativePath must use the canonical mark in every '
              'theme-owned crown',
        );
        expect(
          localDeltaPainter.hasMatch(source),
          isFalse,
          reason: '$relativePath must not redraw the Axion delta',
        );
      }

      final directDeltaAssets = <String>[];
      final sourceFiles =
          await Directory(
                '${packageDirectory.path}${Platform.pathSeparator}lib'
                '${Platform.pathSeparator}src',
              )
              .list(recursive: true)
              .where((entry) => entry is File)
              .cast<File>()
              .toList();
      final deltaAssetLiteral = RegExp(
        r'''["']assets/[^"']*(?:axion|delta)[^"']*["']''',
        caseSensitive: false,
      );
      for (final sourceFile in sourceFiles) {
        final source = await sourceFile.readAsString();
        directDeltaAssets.addAll(
          deltaAssetLiteral.allMatches(source).map((match) => match.group(0)!),
        );
      }
      expect(directDeltaAssets, ["'$canonicalDeltaMarkAsset'"]);
    },
  );

  testWidgets('Containment Drone consumes the canonical delta', (tester) async {
    const containment = VariantFThemeBundle();
    expect(containment.frame.assetPaths, contains(canonicalDeltaMarkAsset));

    await tester.pumpWidget(
      MaterialApp(
        theme: containment.standardPresentation.createThemeData(),
        home: containment.shellRenderer.build(
          slots: _slots,
          environmentName: 'TEST',
          onOpenMenu: _noop,
          onOpenDestination: _ignoreDestination,
          onOpenAttention: _noop,
          onAddSchedule: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CanonicalDeltaMark), findsOneWidget);
  });
}

const _slots = ResponsiveShellSlots(
  centralContent: Center(child: Text('Calendar fixture')),
  planningRegion: Text('Planning fixture'),
  placementDock: Text('Placement fixture'),
  insightRail: Text('Insight fixture'),
  mobilePlacementSummary: Text('Placement summary fixture'),
  mobileAttention: Text('Attention fixture'),
  profileAvatar: SizedBox.square(dimension: 44),
);

void _noop() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}

Directory _assetDirectory() {
  for (final candidate in [
    Directory('assets'),
    Directory('packages/clinical_calendar_presentation/assets'),
  ]) {
    if (candidate.existsSync()) return candidate;
  }
  throw StateError('Could not locate the presentation package assets.');
}
