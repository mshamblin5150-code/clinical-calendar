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
      final changedPositions = <int>{};

      for (var index = 0; index < 240; index++) {
        final position = (index * 37) % (actual.width * actual.height);
        changedPositions.add(position);
        final x = position % actual.width;
        final y = position ~/ actual.width;
        actual.setPixelRgb(x, y, 48, 48, 48);
      }

      expect(changedPositions, hasLength(240));
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
