import 'dart:io';

import 'package:flutter/services.dart';

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
