import 'dart:io';

Future<void> main() async {
  final repositoryRoot = Directory.current.absolute;
  final dart = Platform.resolvedExecutable;
  final flutter = _findFlutterExecutable();

  _verifyProductionSourcePolicy(repositoryRoot);

  await _run(dart, const [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    'apps',
    'packages',
    'tool',
  ], repositoryRoot);

  for (final path in _dartPackages) {
    await _run(dart, const ['analyze', '--fatal-infos'], Directory(path));
    await _run(dart, const ['test'], Directory(path));
  }

  for (final path in _flutterPackages) {
    await _run(flutter, const ['analyze', '--fatal-infos'], Directory(path));
    await _run(flutter, const ['test'], Directory(path));
  }

  stdout.writeln('Clinical Calendar quality gate passed.');
}

const _dartPackages = <String>[
  'packages/clinical_calendar_domain',
  'packages/clinical_calendar_application',
  'packages/clinical_calendar_local_data',
  'packages/clinical_calendar_sync',
];

const _flutterPackages = <String>[
  'packages/clinical_calendar_presentation',
  'packages/clinical_calendar_platform',
  'apps/clinical_calendar',
];

void _verifyProductionSourcePolicy(Directory repositoryRoot) {
  final forbiddenCredentials = RegExp(
    r'(SUPABASE_SERVICE_ROLE_KEY|github_pat_|gho_|'
    r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|'
    r'sk-[A-Za-z0-9_-]{20,})',
  );
  final forbiddenDependencies = RegExp(
    r'(^|[\s/])(react|node_modules)([\s/:]|$)|package\.json',
    caseSensitive: false,
  );
  final violations = <String>[];

  for (final rootName in const ['apps', 'packages']) {
    final root = Directory('${repositoryRoot.path}/$rootName');
    final files = root.listSync(recursive: true).whereType<File>().where((
      file,
    ) {
      final normalized = file.path.replaceAll('\\', '/');
      return !normalized.contains('/build/') &&
          !normalized.contains('/.dart_tool/') &&
          _sourceExtensions.any(normalized.endsWith);
    });
    for (final file in files) {
      final contents = file.readAsStringSync();
      if (forbiddenCredentials.hasMatch(contents)) {
        violations.add('${file.path}: privileged credential pattern');
      }
      if (file.path.endsWith('pubspec.yaml') &&
          forbiddenDependencies.hasMatch(contents)) {
        violations.add('${file.path}: React/Node production dependency');
      }
    }
  }

  if (violations.isNotEmpty) {
    throw StateError(
      'Production source policy failed:\n${violations.join('\n')}',
    );
  }
}

const _sourceExtensions = <String>[
  '.dart',
  '.yaml',
  '.yml',
  '.json',
  '.xml',
  '.gradle',
  '.kts',
  '.swift',
  '.plist',
  '.xcconfig',
  '.pbxproj',
];

String _findFlutterExecutable() {
  final configured = Platform.environment['FLUTTER_BIN'];
  if (configured != null && configured.isNotEmpty) {
    return configured;
  }

  var directory = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 8; depth += 1) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}'
      '${Platform.isWindows ? 'flutter.bat' : 'flutter'}',
    );
    if (candidate.existsSync()) {
      return candidate.path;
    }
    directory = directory.parent;
  }
  return Platform.isWindows ? 'flutter.bat' : 'flutter';
}

Future<void> _run(
  String executable,
  List<String> arguments,
  Directory workingDirectory,
) async {
  stdout.writeln(
    '\n> $executable ${arguments.join(' ')} '
    '(${workingDirectory.path})',
  );
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(executable, arguments, 'Command failed', exitCode);
  }
}
