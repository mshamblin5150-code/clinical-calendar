import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

void main() {
  test('local adapter participates in application composition', () async {
    final repositories = DeferredRepositoryRegistry();
    expect(repositories.isInitialized, isFalse);
    await repositories.initialize();
    expect(repositories.isInitialized, isTrue);
  });
}
