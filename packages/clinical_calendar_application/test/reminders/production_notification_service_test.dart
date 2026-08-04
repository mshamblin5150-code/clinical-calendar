import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:test/test.dart';

void main() {
  test('reconciles source truth and persists synchronized snooze', () async {
    final now = DateTime.utc(2026, 8, 4, 12);
    final repositories = _Registry(now);
    final platform = _Platform();
    final delivery = _DeliveryStore();
    final taps = <NotificationInteraction>[];
    final service = ProductionNotificationService(
      source: _Source(now.add(const Duration(hours: 2))),
      policy: ReminderPolicy(_UtcResolver()),
      reconciler: NotificationReconciler(platform, delivery),
      states: ReminderStateApplicationService(repositories),
      devicePolicies: _PolicyStore(),
      clock: _Clock(now),
      identifiers: _Identifiers(),
      studentId: _id(1),
      deviceClass: NotificationDeviceClass.phone,
      deviceTimeZoneId: 'UTC',
      onBodyTap: taps.add,
    );

    await service.reconcileScheduledNotifications();
    expect(platform.scheduled, hasLength(1));
    final interaction = NotificationInteraction.decode(
      platform.scheduled.single.$2,
    );
    await service.handleInteraction(interaction);
    expect(taps, [interaction]);

    await service.handleInteraction(
      NotificationInteraction.decode(
        platform.scheduled.single.$2,
        actionId: 'snooze.oneHour',
      ),
    );

    final states = await ReminderStateApplicationService(
      repositories,
    ).synchronizedSnoozes(studentId: _id(1));
    expect(states.values.single, now.add(const Duration(hours: 1)));
    expect(platform.scheduled.last.$1, now.add(const Duration(hours: 1)));
  });
}

final class _Source implements ReminderCandidateSource {
  const _Source(this.at);
  final DateTime at;

  @override
  Future<ReminderCandidatePlan> load(DateTime nowUtc) async =>
      ReminderCandidatePlan(
        candidates: [
          ReminderCandidate(
            kind: ReminderKind.upcomingWorkShift,
            subjectId: _id(2),
            anchorUtc: at,
            title: 'Upcoming work shift',
            route: '/reminders/commitment/work/${_id(2)}',
          ),
        ],
      );
}

final class _Clock implements Clock {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime nowUtc() => value;
}

final class _Identifiers implements IdentifierGenerator {
  int next = 10;
  @override
  String nextIdentifier() => _id(next++);
}

final class _UtcResolver implements ReminderTimeZoneResolver {
  @override
  DateTime fromLocal(DateTime localWallClock, String timeZoneId) =>
      localWallClock.toUtc();
  @override
  DateTime toLocal(DateTime utc, String timeZoneId) => utc.toUtc();
}

final class _Platform implements NotificationPlatform {
  final List<(DateTime, String)> scheduled = [];
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<NotificationPermission> permission() async =>
      NotificationPermission.granted;
  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.granted;
  @override
  Future<void> schedule({
    required int id,
    required DateTime atUtc,
    required String title,
    required String body,
    required String payload,
    required List<NotificationAction> actions,
  }) async => scheduled.add((atUtc, payload));
}

final class _DeliveryStore implements NotificationDeliveryStore {
  Map<String, NotificationDeliveryRecord> records = {};
  @override
  Future<Map<String, NotificationDeliveryRecord>> readAll() async =>
      Map.of(records);
  @override
  Future<void> replaceAll(
    Map<String, NotificationDeliveryRecord> records,
  ) async => this.records = Map.of(records);
}

final class _PolicyStore implements NotificationDevicePolicyStore {
  @override
  Future<NotificationDevicePolicy?> read(
    NotificationDeviceClass deviceClass,
  ) async => NotificationDevicePolicy(deviceClass: deviceClass);
  @override
  Future<void> write(NotificationDevicePolicy policy) async {}
}

final class _Registry implements RepositoryRegistry {
  _Registry(DateTime now) : values = _Repositories(now);
  final _Repositories values;
  @override
  Future<void> initialize() async {}
  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(values);
  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(values);
}

final class _Repositories implements ReminderLocalWriteRepositories {
  _Repositories(DateTime now) : reminderStates = _ReminderRepository(now);
  @override
  final MutableRepository<ReminderState> reminderStates;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReminderRepository implements MutableRepository<ReminderState> {
  _ReminderRepository(this.now);
  final DateTime now;
  final Map<String, StoredDomainRecord<ReminderState>> records = {};
  @override
  StoredDomainRecord<ReminderState>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => records[id];
  @override
  List<StoredDomainRecord<ReminderState>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records.values.toList();
  @override
  MutationReceipt<ReminderState> put({
    required String studentId,
    required ReminderState value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final record = StoredDomainRecord(
      value: value,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: now,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    records[value.id] = record;
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<ReminderState> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) => throw UnimplementedError();
}

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
