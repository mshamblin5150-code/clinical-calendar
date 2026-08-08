import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'proof_fonts.dart';

void main() {
  test(
    'proof comparison accepts distributed low-delta rasterization noise',
    () {
      final expected = img.Image(width: 100, height: 100)
        ..clear(img.ColorRgb8(40, 40, 40));
      final actual = img.Image.from(expected);

      for (var index = 0; index < 200; index++) {
        final x = (index * 37) % actual.width;
        final y = (index * 61) % actual.height;
        actual.setPixelRgb(x, y, 48, 48, 48);
      }

      expect(proofImagesMatch(expected, actual), isTrue);
    },
  );

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
