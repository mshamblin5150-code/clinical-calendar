import '../repositories.dart';

/// Coordinates synchronized snooze/resolution state. Native dismissal is
/// deliberately absent because it is device-local delivery state.
final class ReminderStateApplicationService {
  const ReminderStateApplicationService(this.repositories);

  final RepositoryRegistry repositories;

  Future<StoredDomainRecord<ReminderState>?> findByOccurrenceKey({
    required String studentId,
    required String occurrenceKey,
  }) => repositories.read((values) {
    for (final record in _read(
      values,
    ).reminderStates.list(studentId: studentId)) {
      if (record.value.occurrenceKey == occurrenceKey) return record;
    }
    return null;
  });

  Future<Map<String, DateTime>> synchronizedSnoozes({
    required String studentId,
  }) => repositories.read((values) {
    final reminderValues = _read(values);
    return {
      for (final record in reminderValues.reminderStates.list(
        studentId: studentId,
      ))
        if (!record.value.isResolved && record.value.snoozedUntilUtc != null)
          record.value.occurrenceKey: record.value.snoozedUntilUtc!,
    };
  });

  Future<MutationReceipt<ReminderState>> put({
    required String studentId,
    required ReminderState value,
    required int expectedRevision,
    required MutationToken mutation,
  }) => repositories.mutate(
    (repositories) => _write(repositories).reminderStates.put(
      studentId: studentId,
      value: value,
      expectedRevision: expectedRevision,
      mutation: mutation,
    ),
  );

  ReminderLocalReadRepositories _read(LocalReadRepositories repositories) {
    if (repositories case final ReminderLocalReadRepositories values) {
      return values;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Reminder persistence is unavailable.',
    );
  }

  ReminderLocalWriteRepositories _write(LocalWriteRepositories repositories) {
    if (repositories case final ReminderLocalWriteRepositories values) {
      return values;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Reminder persistence is unavailable.',
    );
  }
}
