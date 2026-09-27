import 'package:sqlite3/common.dart';

import 'web_credential_storage.dart';

abstract interface class UnsentChangesGuard {
  void update(bool hasUnsentChanges);

  Future<void> dispose();
}

abstract interface class BrowserRuntime {
  BrowserKeyValueStore get credentials;

  UnsentChangesGuard createUnsentChangesGuard();

  Future<CommonDatabase> openInMemorySqlite();

  String get deviceName;

  String get timeZoneName;
}
