import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_sync/clinical_calendar_sync.dart';
import 'package:test/test.dart';

void main() {
  test('unconfigured synchronization is explicit and offline', () async {
    final result = await const OfflineSynchronizationService().synchronize();
    expect(result.disposition, SynchronizationDisposition.offline);
  });
}
