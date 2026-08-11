import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'proof_fonts.dart';

void main() {
  test('proof golden paths retain Flutter test-file-relative resolution', () {
    final testFile = Uri.file(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'proof_suite${Platform.pathSeparator}sample_test.dart',
    );
    final comparator = LocalFileComparator(testFile);
    final golden = Uri.parse('goldens/sample.png');

    expect(
      resolveProofGolden(comparator, golden),
      comparator.basedir.resolveUri(golden),
    );
  });

  test(
    'proof comparison accepts distributed low-delta rasterization noise',
    () {
      final expected = img.Image(width: 100, height: 100)
        ..clear(img.ColorRgb8(40, 40, 40));
      final actual = img.Image.from(expected);
      final changedPositions = <int>{};

      for (var index = 0; index < 390; index++) {
        final position = (index * 37) % (actual.width * actual.height);
        changedPositions.add(position);
        final x = position % actual.width;
        final y = position ~/ actual.width;
        actual.setPixelRgb(x, y, 48, 48, 48);
      }

      expect(changedPositions, hasLength(390));
      expect(proofImagesMatch(expected, actual), isTrue);
    },
  );

  test('proof comparison rejects low-delta noise above its ceiling', () {
    final expected = img.Image(width: 100, height: 100)
      ..clear(img.ColorRgb8(40, 40, 40));
    final actual = img.Image.from(expected);

    for (var index = 0; index < 410; index++) {
      final position = (index * 37) % (actual.width * actual.height);
      actual.setPixelRgb(
        position % actual.width,
        position ~/ actual.width,
        48,
        48,
        48,
      );
    }

    expect(proofImagesMatch(expected, actual), isFalse);
  });

  test('proof comparison rejects a localized high-contrast deletion', () {
    final expected = img.Image(width: 100, height: 100)
      ..clear(img.ColorRgb8(245, 245, 245));
    final actual = img.Image.from(expected);

    img.fillRect(
      actual,
      x1: 45,
      y1: 45,
      x2: 54,
      y2: 54,
      color: img.ColorRgb8(20, 20, 20),
    );

    expect(proofImagesMatch(expected, actual), isFalse);
  });

  test(
    'catalog proof allowance does not weaken the default high-delta bound',
    () {
      final expected = img.Image(width: 100, height: 100)
        ..clear(img.ColorRgb8(245, 245, 245));
      final actual = img.Image.from(expected);

      for (var index = 0; index < 40; index++) {
        final position = (index * 37) % (actual.width * actual.height);
        actual.setPixelRgb(
          position % actual.width,
          position ~/ actual.width,
          20,
          20,
          20,
        );
      }

      expect(proofImagesMatch(expected, actual), isFalse);
      expect(
        proofImagesMatch(expected, actual, highDeltaPixelTolerance: .0045),
        isTrue,
      );
    },
  );

  test(
    'reconfiguring a proof comparator replaces its prior tolerance',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'clinical-calendar-proof-comparator-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final goldenDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}goldens',
      );
      await goldenDirectory.create();
      final expected = img.Image(width: 100, height: 100)
        ..clear(img.ColorRgb8(245, 245, 245));
      final actual = img.Image.from(expected);
      for (var index = 0; index < 26; index++) {
        final position = (index * 37) % (actual.width * actual.height);
        actual.setPixelRgb(
          position % actual.width,
          position ~/ actual.width,
          20,
          20,
          20,
        );
      }
      await File(
        '${goldenDirectory.path}${Platform.pathSeparator}sample.png',
      ).writeAsBytes(img.encodePng(expected));
      final localComparator = LocalFileComparator(
        Uri.file('${directory.path}${Platform.pathSeparator}sample_test.dart'),
      );
      final defaultComparator = createProofGoldenComparator(localComparator);
      final reconfiguredComparator = createProofGoldenComparator(
        defaultComparator,
        highDeltaPixelTolerance: .00265,
      );

      expect(
        await defaultComparator.compare(
          img.encodePng(actual),
          Uri.parse('goldens/sample.png'),
        ),
        isFalse,
      );
      expect(
        await reconfiguredComparator.compare(
          img.encodePng(actual),
          Uri.parse('goldens/sample.png'),
        ),
        isTrue,
      );
    },
  );
}
