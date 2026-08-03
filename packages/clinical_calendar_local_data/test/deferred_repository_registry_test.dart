import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

void main() {
  test('local adapter participates in application composition', () async {
    final repositories = DeferredRepositoryRegistry();
    expect(repositories.isInitialized, isFalse);
    await repositories.initialize();
    expect(repositories.isInitialized, isTrue);
  });

  test(
    'fails closed for reads and mutations even after initialization',
    () async {
      final repositories = DeferredRepositoryRegistry();
      await repositories.initialize();

      await expectLater(
        repositories.read<void>((_) {}),
        throwsA(
          isA<RepositoryException>().having(
            (error) => error.kind,
            'kind',
            RepositoryFailureKind.uninitialized,
          ),
        ),
      );
      await expectLater(
        repositories.mutate<void>((_) {}),
        throwsA(
          isA<RepositoryException>().having(
            (error) => error.kind,
            'kind',
            RepositoryFailureKind.uninitialized,
          ),
        ),
      );
    },
  );
}
