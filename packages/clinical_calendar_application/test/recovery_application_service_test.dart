import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 8, 4, 12);

void main() {
  test('permanent deletion requires explicit confirmation', () async {
    final store = _Store();
    final service = RecoveryApplicationService(
      store: store,
      reauthentication: _Gate(true),
      identifiers: _Identifiers(),
    );

    await expectLater(
      service.permanentlyDelete(
        trashId: 'trash',
        confirmed: false,
        nowUtc: _now,
      ),
      throwsA(
        isA<RecoveryException>().having(
          (error) => error.kind,
          'kind',
          RecoveryFailureKind.confirmationRequired,
        ),
      ),
    );
    expect(store.permanentDeletes, 0);

    await service.permanentlyDelete(
      trashId: 'trash',
      confirmed: true,
      nowUtc: _now,
    );
    expect(store.permanentDeletes, 1);
  });

  test('clearing Trash requires successful reauthentication', () async {
    final store = _Store();
    final denied = RecoveryApplicationService(
      store: store,
      reauthentication: _Gate(false),
      identifiers: _Identifiers(),
    );
    await expectLater(
      denied.clearTrash(confirmed: true, nowUtc: _now),
      throwsA(
        isA<RecoveryException>().having(
          (error) => error.kind,
          'kind',
          RecoveryFailureKind.authenticationFailed,
        ),
      ),
    );
    expect(store.clears, 0);

    final allowed = RecoveryApplicationService(
      store: store,
      reauthentication: _Gate(true),
      identifiers: _Identifiers(),
    );
    expect(await allowed.clearTrash(confirmed: true, nowUtc: _now), 2);
    expect(store.clears, 1);
  });
}

final class _Store implements RecoveryStore {
  var permanentDeletes = 0;
  var clears = 0;

  @override
  Future<int> clearTrash({
    required DateTime deletedAtUtc,
    required List<MutationToken> mutations,
  }) async {
    clears++;
    return 2;
  }

  @override
  Future<void> permanentlyDelete({
    required String trashId,
    required DateTime deletedAtUtc,
    required MutationToken mutation,
  }) async {
    permanentDeletes++;
  }

  @override
  Future<OperationalSnapshotSummary> createDailySnapshot({
    required DateTime nowUtc,
  }) => throw UnimplementedError();

  @override
  Future<List<TrashEntry>> listTrash({required DateTime nowUtc}) async => [];

  @override
  Future<List<OperationalSnapshotSummary>> listSnapshots({
    required DateTime nowUtc,
  }) async => [];

  @override
  Future<OperationalRecoveryPreview> previewSnapshot({
    required String snapshotId,
    required DateTime nowUtc,
  }) => throw UnimplementedError();

  @override
  Future<int> purgeExpired({required DateTime nowUtc}) async => 0;

  @override
  Future<void> restoreTrash({
    required String trashId,
    required DateTime restoredAtUtc,
    required MutationToken mutation,
  }) async {}

  @override
  Future<RecoveryApplyResult> restoreSnapshot({
    required String snapshotId,
    required Map<String, RecoveryConflictChoice> choices,
    required DateTime nowUtc,
  }) => throw UnimplementedError();
}

final class _Gate implements RecoveryReauthenticationGate {
  const _Gate(this.allowed);
  final bool allowed;

  @override
  Future<bool> reauthenticate({required String reason}) async => allowed;
}

final class _Identifiers implements IdentifierGenerator {
  var next = 1;

  @override
  String nextIdentifier() =>
      '00000000-0000-4000-8000-${(next++).toString().padLeft(12, '0')}';
}
