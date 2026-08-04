import 'dart:async';
import 'dart:io';

// Public constructor names describe capabilities; private field names do not.
// ignore_for_file: prefer_initializing_formals

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';

typedef LocalRemovalPreviewLoader = Future<LocalRemovalPreview> Function();
typedef LocalRemovalLifecycleStopper = Future<void> Function();

/// Deletes only the known SQLCipher database for this installation.
///
/// The connection and synchronization lifecycle must stop successfully before
/// any file or credential is touched. File removal is deliberately
/// non-recursive and limited to the database plus SQLite's exact WAL/SHM
/// sidecars. Credentials remain available if shutdown or file removal fails,
/// allowing the Student to retry without creating an unrecoverable database.
final class ProductionLocalDeviceCopyController
    implements LocalDeviceCopyController {
  ProductionLocalDeviceCopyController({
    required String databasePath,
    required SecureStorage secureStorage,
    required LocalRemovalPreviewLoader preview,
    required LocalRemovalLifecycleStopper stopLifecycleAndCloseDatabase,
    required Iterable<String> credentialKeys,
  }) : _databasePath = _validatedDatabasePath(databasePath),
       _secureStorage = secureStorage,
       _preview = preview,
       _stopLifecycleAndCloseDatabase = stopLifecycleAndCloseDatabase,
       _credentialKeys = Set.unmodifiable(
         credentialKeys.map(_validatedCredentialKey),
       ) {
    if (_credentialKeys.isEmpty) {
      throw ArgumentError.value(credentialKeys, 'credentialKeys');
    }
  }

  final String _databasePath;
  final SecureStorage _secureStorage;
  final LocalRemovalPreviewLoader _preview;
  final LocalRemovalLifecycleStopper _stopLifecycleAndCloseDatabase;
  final Set<String> _credentialKeys;
  Future<void>? _removal;
  bool _removed = false;

  @override
  Future<LocalRemovalPreview> previewRemoval() {
    if (_removed) throw const IdentityException('local_copy_unavailable');
    return _preview();
  }

  @override
  Future<void> removeLocalCopy() {
    if (_removed) return Future<void>.value();
    final active = _removal;
    if (active != null) return active;
    final removal = _remove();
    _removal = removal;
    return removal.whenComplete(() => _removal = null);
  }

  Future<void> _remove() async {
    await _stopLifecycleAndCloseDatabase();
    for (final path in _exactDatabaseTargets(_databasePath)) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    for (final key in _credentialKeys) {
      await _secureStorage.delete(key);
    }
    _removed = true;
  }
}

String _validatedDatabasePath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) throw ArgumentError.value(value, 'databasePath');
  final file = File(trimmed);
  if (!file.isAbsolute) {
    throw ArgumentError.value(value, 'databasePath', 'must be absolute');
  }
  final absolute = file.absolute.path;
  final expectedSuffix = '${Platform.pathSeparator}clinical_calendar.sqlite3';
  if (!absolute.endsWith(expectedSuffix)) {
    throw ArgumentError.value(
      value,
      'databasePath',
      'must identify the Clinical Calendar database',
    );
  }
  return absolute;
}

String _validatedCredentialKey(String value) {
  final key = value.trim();
  if (key.isEmpty) throw ArgumentError.value(value, 'credentialKeys');
  return key;
}

List<String> _exactDatabaseTargets(String databasePath) {
  final parent = File(databasePath).parent.absolute.path;
  final targets = [databasePath, '$databasePath-wal', '$databasePath-shm'];
  for (final target in targets) {
    if (File(target).parent.absolute.path != parent) {
      throw StateError('A local-copy deletion target escaped its directory.');
    }
  }
  return targets;
}
