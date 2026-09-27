import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/common.dart';

import 'browser_runtime_contracts.dart';
import 'web_credential_storage.dart';

BrowserRuntime createBrowserRuntime() => _StubBrowserRuntime();

final class _StubBrowserRuntime implements BrowserRuntime {
  static final _credentials = _MemoryBrowserStore();

  @override
  BrowserKeyValueStore get credentials => _credentials;

  @override
  UnsentChangesGuard createUnsentChangesGuard() => _StubUnsentChangesGuard();

  @override
  String get deviceName => 'Test browser';

  @override
  Future<CommonDatabase> openInMemorySqlite() async => sqlite3.openInMemory();
}

final class _MemoryBrowserStore implements BrowserKeyValueStore {
  final _values = <String, String>{};

  @override
  void delete(String key) => _values.remove(key);

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;
}

final class _StubUnsentChangesGuard implements UnsentChangesGuard {
  @override
  Future<void> dispose() async {}

  @override
  void update(bool hasUnsentChanges) {}
}
