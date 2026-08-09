import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main() {
  final concept = img.decodePng(
    File(
      '../../docs/themes/acceptance/proofs/federation-classic-v4/'
      'approved-concept-landscape.png',
    ).readAsBytesSync(),
  )!;
  final runtime = img.decodePng(
    File(
      'test/goldens/federation_classic_v4/'
      'federation_classic_landscape_1586x992.png',
    ).readAsBytesSync(),
  )!;
  if (concept.width != runtime.width || concept.height != runtime.height) {
    throw StateError('Images must have identical dimensions.');
  }

  final regions = <String, ({int left, int top, int width, int height})>{
    'crown': (left: 0, top: 32, width: 1586, height: 72),
    'left-rails': (left: 0, top: 96, width: 210, height: 780),
    'right-rails': (left: 1370, top: 96, width: 216, height: 780),
    'navigation': (left: 0, top: 875, width: 1586, height: 117),
  };

  // Pinned against rejected v3: its right rail (0.6280) and navigation
  // (0.6091) must remain below this acceptance floor.
  const minimumSimilarity = 0.68;
  var failed = false;
  for (final entry in regions.entries) {
    final score = _iou(concept, runtime, entry.value);
    stdout.writeln('${entry.key}: ${score.toStringAsFixed(4)}');
    if (score < minimumSimilarity) failed = true;
  }
  if (failed) exitCode = 1;
}

double _iou(
  img.Image concept,
  img.Image runtime,
  ({int left, int top, int width, int height}) region,
) {
  final conceptMask = Uint8List(region.width * region.height);
  final runtimeMask = Uint8List(region.width * region.height);
  var offset = 0;
  for (var y = region.top; y < region.top + region.height; y++) {
    for (var x = region.left; x < region.left + region.width; x++) {
      conceptMask[offset] = _isChrome(concept.getPixel(x, y)) ? 1 : 0;
      runtimeMask[offset] = _isChrome(runtime.getPixel(x, y)) ? 1 : 0;
      offset++;
    }
  }

  var intersection = 0;
  var union = 0;
  for (var index = 0; index < conceptMask.length; index++) {
    final inConcept = conceptMask[index] == 1;
    final inRuntime = runtimeMask[index] == 1;
    if (inConcept && inRuntime) intersection++;
    if (inConcept || inRuntime) union++;
  }
  return union == 0 ? 1 : intersection / union;
}

bool _isChrome(img.Pixel pixel) {
  final red = pixel.rNormalized;
  final green = pixel.gNormalized;
  final blue = pixel.bNormalized;
  final maximum = [red, green, blue].reduce((a, b) => a > b ? a : b);
  final minimum = [red, green, blue].reduce((a, b) => a < b ? a : b);
  final saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum;
  return maximum > 0.30 && saturation > 0.24;
}
