import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

void main() {
  final concept = img.decodePng(
    File(
      '../../docs/themes/acceptance/proofs/federation-classic-v6/'
      'approved-concept-landscape.png',
    ).readAsBytesSync(),
  )!;
  final runtime = img.decodePng(
    File(
      'test/goldens/federation_classic_v6/'
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

  // Pinned above rejected v4's measured negative baseline: crown 0.8668,
  // left rails 0.9087, right rails 0.7329, and navigation 0.6987.
  const minimumSimilarity = <String, double>{
    'crown': .87,
    'left-rails': .90,
    'right-rails': .735,
    'navigation': .71,
  };
  const panelRegions = <String, ({int left, int top, int width, int height})>{
    'upper-left-elbow': (left: 0, top: 32, width: 205, height: 180),
    'left-spine': (left: 0, top: 195, width: 96, height: 545),
    'lower-left-elbow': (left: 0, top: 720, width: 105, height: 160),
    'lower-left-cap': (left: 130, top: 800, width: 75, height: 80),
    'crown-segments': (left: 440, top: 35, width: 1146, height: 65),
    'right-spine': (left: 1535, top: 330, width: 51, height: 550),
    'lower-right-cap': (left: 1360, top: 815, width: 226, height: 65),
    'navigation-left-cap': (left: 0, top: 880, width: 205, height: 112),
    'navigation-right-cap': (left: 1360, top: 880, width: 226, height: 112),
  };
  const minimumPanelBoundarySimilarity = .80;
  var failed = false;
  for (final entry in regions.entries) {
    final score = _iou(concept, runtime, entry.value);
    stdout.writeln('${entry.key}: ${score.toStringAsFixed(4)}');
    if (score < minimumSimilarity[entry.key]!) failed = true;
  }
  for (final entry in panelRegions.entries) {
    final score = _boundaryF1(concept, runtime, entry.value, tolerance: 4);
    stdout.writeln('${entry.key}-boundary: ${score.toStringAsFixed(4)}');
    if (score < minimumPanelBoundarySimilarity) failed = true;
  }
  if (failed) exitCode = 1;
}

double _boundaryF1(
  img.Image concept,
  img.Image runtime,
  ({int left, int top, int width, int height}) region, {
  required int tolerance,
}) {
  final conceptEdges = _chromeEdges(concept, region);
  final runtimeEdges = _chromeEdges(runtime, region);
  final conceptMatches = _matchedEdges(
    conceptEdges,
    runtimeEdges,
    region.width,
    region.height,
    tolerance,
  );
  final runtimeMatches = _matchedEdges(
    runtimeEdges,
    conceptEdges,
    region.width,
    region.height,
    tolerance,
  );
  final conceptCount = conceptEdges.where((edge) => edge == 1).length;
  final runtimeCount = runtimeEdges.where((edge) => edge == 1).length;
  if (conceptCount == 0 || runtimeCount == 0) return 0;
  final recall = conceptMatches / conceptCount;
  final precision = runtimeMatches / runtimeCount;
  return 2 * precision * recall / (precision + recall);
}

Uint8List _chromeEdges(
  img.Image image,
  ({int left, int top, int width, int height}) region,
) {
  final mask = Uint8List(region.width * region.height);
  for (var y = 1; y < region.height - 1; y++) {
    for (var x = 1; x < region.width - 1; x++) {
      final chrome = _isChrome(image.getPixel(region.left + x, region.top + y));
      if (!chrome) continue;
      final neighbors = <(int, int)>[
        (x - 1, y),
        (x + 1, y),
        (x, y - 1),
        (x, y + 1),
      ];
      if (neighbors.any(
        (point) => !_isChrome(
          image.getPixel(region.left + point.$1, region.top + point.$2),
        ),
      )) {
        mask[y * region.width + x] = 1;
      }
    }
  }
  return mask;
}

int _matchedEdges(
  Uint8List source,
  Uint8List target,
  int width,
  int height,
  int tolerance,
) {
  var matches = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (source[y * width + x] == 0) continue;
      var matched = false;
      for (var dy = -tolerance; dy <= tolerance && !matched; dy++) {
        final targetY = y + dy;
        if (targetY < 0 || targetY >= height) continue;
        for (var dx = -tolerance; dx <= tolerance; dx++) {
          final targetX = x + dx;
          if (targetX < 0 || targetX >= width) continue;
          if (target[targetY * width + targetX] == 1) {
            matched = true;
            break;
          }
        }
      }
      if (matched) matches++;
    }
  }
  return matches;
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
