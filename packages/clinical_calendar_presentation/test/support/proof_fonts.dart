import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadProofFonts() async {
  final candidates = <Directory>[];

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

  throw StateError('Bundled Flutter proof fonts were not found.');
}

Future<void> _loadFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}
