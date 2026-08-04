import '../ports.dart';
import '../repositories.dart';
import 'recovery_models.dart';

final class RecoveryApplicationService {
  factory RecoveryApplicationService({
    required RecoveryStore store,
    required RecoveryReauthenticationGate reauthentication,
    required IdentifierGenerator identifiers,
  }) => RecoveryApplicationService._(store, reauthentication, identifiers);

  const RecoveryApplicationService._(
    this.store,
    this.reauthentication,
    this._identifiers,
  );

  final RecoveryStore store;
  final RecoveryReauthenticationGate reauthentication;
  final IdentifierGenerator _identifiers;

  Future<void> restoreTrash({
    required String trashId,
    required DateTime nowUtc,
  }) => store.restoreTrash(
    trashId: trashId,
    restoredAtUtc: nowUtc,
    mutation: _mutation(nowUtc),
  );

  Future<void> permanentlyDelete({
    required String trashId,
    required bool confirmed,
    required DateTime nowUtc,
  }) async {
    if (!confirmed) {
      throw const RecoveryException(
        RecoveryFailureKind.confirmationRequired,
        'Permanent deletion requires confirmation.',
      );
    }
    await store.permanentlyDelete(
      trashId: trashId,
      deletedAtUtc: nowUtc,
      mutation: _mutation(nowUtc),
    );
  }

  Future<int> clearTrash({
    required bool confirmed,
    required DateTime nowUtc,
  }) async {
    if (!confirmed) {
      throw const RecoveryException(
        RecoveryFailureKind.confirmationRequired,
        'Clearing Trash requires confirmation.',
      );
    }
    final authenticated = await reauthentication.reauthenticate(
      reason: 'Clear all Clinical Calendar Trash',
    );
    if (!authenticated) {
      throw const RecoveryException(
        RecoveryFailureKind.authenticationFailed,
        'Reauthentication was not completed.',
      );
    }
    final trash = await store.listTrash(nowUtc: nowUtc);
    return store.clearTrash(
      deletedAtUtc: nowUtc,
      mutations: [for (final _ in trash) _mutation(nowUtc)],
    );
  }

  MutationToken _mutation(DateTime nowUtc) => MutationToken(
    operationId: _identifiers.nextIdentifier(),
    idempotencyKey: _identifiers.nextIdentifier(),
    occurredAtUtc: nowUtc,
  );
}
