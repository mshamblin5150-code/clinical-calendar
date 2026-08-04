import 'package:clinical_calendar/main.dart' as app;
import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production composition uses one secure Student owner everywhere',
    () async {
      const studentId = '00000000-0000-4000-8000-000000000021';
      final storage = _MemorySecureStorage();
      final identifiers = _Identifiers(studentId);
      final repositories = _Repositories();
      String? repositoryStudentId;
      SecureStorage? repositoryStorage;

      final root = await app.buildProductionApplication(
        secureStorage: storage,
        identifiers: identifiers,
        repositoryBootstrap: (owner, secureStorage, generator) async {
          repositoryStudentId = owner;
          repositoryStorage = secureStorage;
          expect(generator, same(identifiers));
          return repositories;
        },
      );

      expect(root, isA<ClinicalCalendarApp>());
      expect(root.studentId, studentId);
      expect(root.dependencies.repositories, same(repositories));
      expect(root.dependencies.secureStorage, same(storage));
      expect(root.dependencies.files, isA<DartIoFileService>());
      expect(repositoryStudentId, studentId);
      expect(repositoryStorage, same(storage));
      expect(storage.values[StableStudentOwner.storageKey], studentId);
    },
  );

  testWidgets('startup failure is sanitized and leaves recovery guidance', (
    tester,
  ) async {
    await app.runClinicalCalendar(
      () async => throw StateError('sensitive adapter detail'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clinical Calendar could not start.'), findsOneWidget);
    expect(
      find.textContaining('local data was left unchanged'),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive adapter detail'), findsNothing);
  });
}

final class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final class _Identifiers implements IdentifierGenerator {
  const _Identifiers(this.value);

  final String value;

  @override
  String nextIdentifier() => value;
}

final class _Repositories implements RepositoryRegistry {
  @override
  Future<void> initialize() async {}

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => throw UnimplementedError();

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => throw UnimplementedError();
}
