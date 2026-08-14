import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// Current Linux proof rasterization peaks at 3.92% low-delta pixels across the
// catalog. High-delta and aggregate-error bounds below remain authoritative
// for rejecting localized or structural UI changes.
const _nonWindowsPixelTolerance = 0.04;
const _nonWindowsMeanChannelErrorTolerance = 0.003;
const _nonWindowsHighDeltaPixelTolerance = 0.0025;
const _highDeltaThreshold = 128;

GoldenFileComparator createProofGoldenComparator(
  GoldenFileComparator delegate, {
  double highDeltaPixelTolerance = _nonWindowsHighDeltaPixelTolerance,
  double meanChannelErrorTolerance = _nonWindowsMeanChannelErrorTolerance,
}) => _ProofGoldenComparator(
  _unwrapProofGoldenComparator(delegate),
  highDeltaPixelTolerance: highDeltaPixelTolerance,
  meanChannelErrorTolerance: meanChannelErrorTolerance,
);

GoldenFileComparator _unwrapProofGoldenComparator(
  GoldenFileComparator comparator,
) {
  while (comparator is _ProofGoldenComparator) {
    comparator = comparator.delegate;
  }
  return comparator;
}

Future<void> prepareProofEnvironment() async {
  if (!Platform.isWindows && goldenFileComparator is! _ProofGoldenComparator) {
    goldenFileComparator = createProofGoldenComparator(goldenFileComparator);
  }
  await loadProofFonts();
}

Future<void> loadProofFonts() async {
  final candidates = <Directory>[];
  final fontPairs = <({File roboto, File icons})>[];

  for (final variable in ['FLUTTER_ROOT', 'FLUTTER_HOME']) {
    final flutterRoot = Platform.environment[variable];
    if (flutterRoot == null || flutterRoot.isEmpty) continue;
    candidates.add(
      Directory(
        '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
        'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
        'material_fonts',
      ),
    );
    fontPairs.add(
      _devToolsFontPair('$flutterRoot${Platform.pathSeparator}bin'),
    );
  }

  final path = Platform.environment['PATH'] ?? '';
  for (final entry in path.split(Platform.isWindows ? ';' : ':')) {
    if (entry.isEmpty) continue;
    candidates.add(
      Directory(
        '$entry${Platform.pathSeparator}cache${Platform.pathSeparator}'
        'artifacts${Platform.pathSeparator}material_fonts',
      ),
    );
    fontPairs.add(_devToolsFontPair(entry));
  }

  var executableRoot = File(Platform.resolvedExecutable).parent;
  while (executableRoot.parent.path != executableRoot.path) {
    candidates
      ..add(
        Directory(
          '${executableRoot.path}${Platform.pathSeparator}material_fonts',
        ),
      )
      ..add(
        Directory(
          '${executableRoot.path}${Platform.pathSeparator}artifacts'
          '${Platform.pathSeparator}material_fonts',
        ),
      )
      ..add(
        Directory(
          '${executableRoot.path}${Platform.pathSeparator}cache'
          '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
          'material_fonts',
        ),
      );
    executableRoot = executableRoot.parent;
  }

  var root = Directory.current.absolute;
  while (root.parent.path != root.path) {
    candidates.add(
      Directory(
        '${root.path}${Platform.pathSeparator}.tooling'
        '${Platform.pathSeparator}flutter${Platform.pathSeparator}bin'
        '${Platform.pathSeparator}cache${Platform.pathSeparator}artifacts'
        '${Platform.pathSeparator}material_fonts',
      ),
    );
    root = root.parent;
  }

  for (final directory in candidates) {
    final roboto = File(
      '${directory.path}${Platform.pathSeparator}roboto-regular.ttf',
    );
    final icons = File(
      '${directory.path}${Platform.pathSeparator}materialicons-regular.otf',
    );
    if (roboto.existsSync() && icons.existsSync()) {
      await _loadFont('ProofRoboto', roboto);
      await _loadFont('MaterialIcons', icons);
      return;
    }
  }

  for (final pair in fontPairs) {
    if (!pair.roboto.existsSync() || !pair.icons.existsSync()) continue;
    await _loadFont('ProofRoboto', pair.roboto);
    await _loadFont('MaterialIcons', pair.icons);
    return;
  }

  throw StateError('Bundled Flutter proof fonts were not found.');
}

({File roboto, File icons}) _devToolsFontPair(String flutterBin) {
  final root =
      '$flutterBin${Platform.pathSeparator}cache${Platform.pathSeparator}'
      'dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}resources'
      '${Platform.pathSeparator}devtools${Platform.pathSeparator}assets'
      '${Platform.pathSeparator}fonts';
  return (
    roboto: File(
      '$root${Platform.pathSeparator}Roboto${Platform.pathSeparator}'
      'Roboto-Regular.ttf',
    ),
    icons: File('$root${Platform.pathSeparator}MaterialIcons-Regular.otf'),
  );
}

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

final class _ProofGoldenComparator implements GoldenFileComparator {
  const _ProofGoldenComparator(
    this.delegate, {
    this.highDeltaPixelTolerance = _nonWindowsHighDeltaPixelTolerance,
    this.meanChannelErrorTolerance = _nonWindowsMeanChannelErrorTolerance,
  });

  final GoldenFileComparator delegate;
  final double highDeltaPixelTolerance;
  final double meanChannelErrorTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final expectedUri = resolveProofGolden(delegate, golden);
    if (expectedUri == null) {
      return delegate.compare(imageBytes, golden);
    }
    final expectedBytes = await File.fromUri(expectedUri).readAsBytes();
    final expected = img.decodePng(expectedBytes);
    final actual = img.decodePng(imageBytes);
    if (expected == null || actual == null) {
      return delegate.compare(imageBytes, golden);
    }
    final difference = _proofImageDifference(expected, actual);
    final matches =
        difference != null &&
        _differenceIsAccepted(
          difference,
          highDeltaPixelTolerance: highDeltaPixelTolerance,
          meanChannelErrorTolerance: meanChannelErrorTolerance,
        );
    if (!matches && difference != null) {
      stderr.writeln(
        'Proof golden delta for $golden: '
        'changed=${difference.changedRatio}, '
        'highDelta=${difference.highDeltaRatio}, '
        'meanChannelError=${difference.meanChannelError}',
      );
    }
    return matches;
  }

  @override
  Uri getTestUri(Uri key, int? version) => delegate.getTestUri(key, version);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      delegate.update(golden, imageBytes);
}

Uri? resolveProofGolden(GoldenFileComparator comparator, Uri golden) {
  if (comparator case final LocalFileComparator localComparator) {
    return localComparator.basedir.resolveUri(golden);
  }
  return null;
}

bool proofImagesMatch(
  img.Image expected,
  img.Image actual, {
  double highDeltaPixelTolerance = _nonWindowsHighDeltaPixelTolerance,
  double meanChannelErrorTolerance = _nonWindowsMeanChannelErrorTolerance,
}) {
  final difference = _proofImageDifference(expected, actual);
  return difference != null &&
      _differenceIsAccepted(
        difference,
        highDeltaPixelTolerance: highDeltaPixelTolerance,
        meanChannelErrorTolerance: meanChannelErrorTolerance,
      );
}

typedef _ProofImageDifference = ({
  double changedRatio,
  double highDeltaRatio,
  double meanChannelError,
});

_ProofImageDifference? _proofImageDifference(
  img.Image expected,
  img.Image actual,
) {
  if (expected.width != actual.width || expected.height != actual.height) {
    return null;
  }

  var changedPixels = 0;
  var highDeltaPixels = 0;
  var totalChannelError = 0;
  final pixelCount = expected.width * expected.height;
  for (var y = 0; y < expected.height; y++) {
    for (var x = 0; x < expected.width; x++) {
      final expectedPixel = expected.getPixel(x, y);
      final actualPixel = actual.getPixel(x, y);
      final channelErrors = <int>[
        (expectedPixel.r - actualPixel.r).abs().toInt(),
        (expectedPixel.g - actualPixel.g).abs().toInt(),
        (expectedPixel.b - actualPixel.b).abs().toInt(),
        (expectedPixel.a - actualPixel.a).abs().toInt(),
      ];
      final pixelError = channelErrors.reduce((left, right) => left + right);
      if (pixelError == 0) {
        continue;
      }
      changedPixels++;
      totalChannelError += pixelError;
      if (channelErrors.any((error) => error >= _highDeltaThreshold)) {
        highDeltaPixels++;
      }
    }
  }

  final changedRatio = changedPixels / pixelCount;
  final highDeltaRatio = highDeltaPixels / pixelCount;
  final meanChannelError = totalChannelError / (pixelCount * 4 * 255);
  return (
    changedRatio: changedRatio,
    highDeltaRatio: highDeltaRatio,
    meanChannelError: meanChannelError,
  );
}

bool _differenceIsAccepted(
  _ProofImageDifference difference, {
  required double highDeltaPixelTolerance,
  required double meanChannelErrorTolerance,
}) =>
    difference.changedRatio <= _nonWindowsPixelTolerance &&
    difference.highDeltaRatio <= highDeltaPixelTolerance &&
    difference.meanChannelError <= meanChannelErrorTolerance;
