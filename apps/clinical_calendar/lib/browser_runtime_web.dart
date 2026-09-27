import 'dart:async';

import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

import 'browser_runtime_contracts.dart';
import 'web_credential_storage.dart';

BrowserRuntime createBrowserRuntime() => _WebBrowserRuntime();

final class _WebBrowserRuntime implements BrowserRuntime {
  @override
  BrowserKeyValueStore get credentials => const _LocalStorageStore();

  @override
  UnsentChangesGuard createUnsentChangesGuard() => _BrowserUnloadGuard();

  @override
  String get deviceName => _browserDeviceName(web.window.navigator.userAgent);

  @override
  Future<CommonDatabase> openInMemorySqlite() async {
    final sqlite = await WasmSqlite3.loadFromUrlString('sqlite3.wasm');
    return sqlite.openInMemory();
  }
}

final class _LocalStorageStore implements BrowserKeyValueStore {
  const _LocalStorageStore();

  @override
  void delete(String key) => web.window.localStorage.removeItem(key);

  @override
  String? read(String key) => web.window.localStorage.getItem(key);

  @override
  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);
}

final class _BrowserUnloadGuard implements UnsentChangesGuard {
  _BrowserUnloadGuard() {
    _subscription = web.EventStreamProviders.beforeUnloadEvent
        .forTarget(web.window)
        .listen((event) {
          if (!_hasUnsentChanges) return;
          event.preventDefault();
          event.returnValue = '';
        });
  }

  late final StreamSubscription<web.BeforeUnloadEvent> _subscription;
  bool _hasUnsentChanges = false;

  @override
  Future<void> dispose() => _subscription.cancel();

  @override
  void update(bool hasUnsentChanges) => _hasUnsentChanges = hasUnsentChanges;
}

String _browserDeviceName(String userAgent) {
  final browser = userAgent.contains('Edg/')
      ? 'Edge'
      : userAgent.contains('CriOS') || userAgent.contains('Chrome/')
      ? 'Chrome'
      : userAgent.contains('FxiOS') || userAgent.contains('Firefox/')
      ? 'Firefox'
      : userAgent.contains('Safari/')
      ? 'Safari'
      : 'Browser';
  final system = userAgent.contains('iPhone')
      ? 'iPhone'
      : userAgent.contains('iPad')
      ? 'iPad'
      : userAgent.contains('Android')
      ? 'Android'
      : userAgent.contains('Windows')
      ? 'Windows'
      : userAgent.contains('Macintosh')
      ? 'Mac'
      : userAgent.contains('Linux')
      ? 'Linux'
      : 'device';
  return '$browser on $system';
}
