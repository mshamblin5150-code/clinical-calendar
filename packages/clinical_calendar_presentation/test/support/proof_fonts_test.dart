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

  test('proof comparison accepts widespread one-step rasterization noise', () {
    final expected = img.Image(width: 100, height: 100)
      ..clear(img.ColorRgb8(40, 40, 40));
    final actual = img.Image(width: 100, height: 100)
      ..clear(img.ColorRgb8(41, 41, 41));

    expect(proofImagesMatch(expected, actual), isTrue);
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
}
