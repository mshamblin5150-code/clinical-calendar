import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation adapts to compact and desktop viewports', (
    tester,
  ) async {
    for (final size in [const Size(390, 844), const Size(1200, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ClinicalCalendarApp(
          dependencies: _dependencies(),
          environmentName: 'test',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRODUCTION FOUNDATION'), findsOneWidget);
      expect(find.text('DOMAIN'), findsOneWidget);
      expect(find.text('PLATFORM ADAPTERS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}

ApplicationDependencies _dependencies() => ApplicationDependencies(
  repositories: _Repositories(),
  clock: _Clock(),
  identifiers: _Identifiers(),
  synchronization: _Synchronization(),
  notifications: _Notifications(),
  secureStorage: _SecureStorage(),
  files: _Files(),
);

final class _Repositories implements RepositoryRegistry {
  @override
  Future<void> initialize() async {}
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026);
}

final class _Identifiers implements IdentifierGenerator {
  @override
  String nextIdentifier() => 'test';
}

final class _Synchronization implements SynchronizationService {
  @override
  Future<SynchronizationResult> synchronize() async =>
      const SynchronizationResult(SynchronizationDisposition.offline);
}

final class _Notifications implements NotificationService {
  @override
  Future<void> reconcileScheduledNotifications() async {}
}

final class _SecureStorage implements SecureStorage {
  @override
  Future<void> delete(String key) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
}

final class _Files implements FileService {
  @override
  Future<List<int>> read(Uri location) async => [];
  @override
  Future<void> write(Uri location, List<int> bytes) async {}
}
