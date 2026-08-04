import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// SecureStorage boundary backed by the operating system credential store.
final class FlutterSecureStorageService implements SecureStorage {
  const FlutterSecureStorageService([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));

  @override
  Future<String?> read(String key) => _storage.read(key: _key(key));

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _key(key), value: value);
}

/// Resolves the one durable offline Student owner for this installation.
final class StableStudentOwner {
  const StableStudentOwner._();

  static const storageKey = 'clinical_calendar_student_owner_id_v1';
  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static Future<String> loadOrCreate({
    required SecureStorage secureStorage,
    required IdentifierGenerator identifiers,
  }) async {
    final stored = await secureStorage.read(storageKey);
    if (stored != null) return _validatedUuid(stored, source: 'stored');

    final generated = _validatedUuid(
      identifiers.nextIdentifier(),
      source: 'generated',
    );
    await secureStorage.write(storageKey, generated);
    return generated;
  }
}

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

Future<String> clinicalCalendarDatabasePath({
  ApplicationSupportDirectoryProvider? applicationSupportDirectory,
}) async {
  final directory =
      await (applicationSupportDirectory ?? getApplicationSupportDirectory)();
  if (!directory.isAbsolute) {
    throw StateError('Application support directory must be absolute.');
  }
  return '${directory.path}${Platform.pathSeparator}clinical_calendar.sqlite3';
}

/// Ordinary filesystem adapter. Platform content/document URIs are rejected.
final class DartIoFileService implements FileService {
  const DartIoFileService();

  @override
  Future<List<int>> read(Uri location) =>
      File(_filePath(location)).readAsBytes();

  @override
  Future<void> write(Uri location, List<int> bytes) async {
    for (final byte in bytes) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(byte, 'bytes', 'must contain bytes');
      }
    }
    await File(_filePath(location)).writeAsBytes(bytes, flush: true);
  }
}

String _key(String value) {
  final key = value.trim();
  if (key.isEmpty) throw ArgumentError.value(value, 'key', 'must not be empty');
  return key;
}

String _validatedUuid(String value, {required String source}) {
  final normalized = value.trim().toLowerCase();
  if (!StableStudentOwner._uuid.hasMatch(normalized)) {
    throw StateError('The $source Student owner identifier is invalid.');
  }
  return normalized;
}

String _filePath(Uri location) {
  if (location.scheme != 'file') {
    throw ArgumentError.value(
      location,
      'location',
      'only file URIs are supported',
    );
  }
  final path = location.toFilePath(windows: Platform.isWindows);
  if (path.trim().isEmpty) {
    throw ArgumentError.value(location, 'location', 'path must not be empty');
  }
  return path;
}
