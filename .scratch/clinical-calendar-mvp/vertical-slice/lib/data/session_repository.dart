import '../domain/scheduling.dart';

abstract interface class SessionRepository {
  Future<List<ScheduleCommitment>> loadAll();

  Future<void> save(ScheduleCommitment commitment);

  Future<void> close();
}

final class MemorySessionRepository implements SessionRepository {
  final List<ScheduleCommitment> _sessions = [];

  @override
  Future<List<ScheduleCommitment>> loadAll() async => List.of(_sessions);

  @override
  Future<void> save(ScheduleCommitment commitment) async {
    _sessions.add(commitment);
  }

  @override
  Future<void> close() async {}
}
