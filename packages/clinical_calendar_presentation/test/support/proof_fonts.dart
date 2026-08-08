import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _nonWindowsPixelTolerance = 0.025;

Future<void> prepareProofEnvironment() async {
  if (!Platform.isWindows && goldenFileComparator is! _ProofGoldenComparator) {
    goldenFileComparator = _ProofGoldenComparator(goldenFileComparator);
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
  const _ProofGoldenComparator(this.delegate);

  final GoldenFileComparator delegate;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final expectedBytes = await File.fromUri(
      getTestUri(golden, null),
    ).readAsBytes();
    final expected = img.decodePng(expectedBytes);
    final actual = img.decodePng(imageBytes);
    if (expected == null || actual == null) {
      return delegate.compare(imageBytes, golden);
    }
    if (expected.width != actual.width || expected.height != actual.height) {
      return false;
    }

    var changedPixels = 0;
    final pixelCount = expected.width * expected.height;
    for (var y = 0; y < expected.height; y++) {
      for (var x = 0; x < expected.width; x++) {
        final expectedPixel = expected.getPixel(x, y);
        final actualPixel = actual.getPixel(x, y);
        if (expectedPixel.r != actualPixel.r ||
            expectedPixel.g != actualPixel.g ||
            expectedPixel.b != actualPixel.b ||
            expectedPixel.a != actualPixel.a) {
          changedPixels++;
        }
      }
    }
    return changedPixels / pixelCount <= _nonWindowsPixelTolerance;
  }

  @override
  Uri getTestUri(Uri key, int? version) => delegate.getTestUri(key, version);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      delegate.update(golden, imageBytes);
}
