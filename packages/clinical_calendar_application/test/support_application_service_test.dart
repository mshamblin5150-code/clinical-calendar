import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _profileId = '00000000-0000-4000-8000-000000000002';

void main() {
  late _MemoryRegistry registry;
  late _Identifiers identifiers;
  late SupportApplicationService service;

  setUp(() {
    registry = _MemoryRegistry();
    identifiers = _Identifiers();
    service = SupportApplicationService(
      repositories: registry,
      clock: _Clock(),
      identifiers: identifiers,
      studentId: _studentId,
    );
  });

  test(
    'profile derives initials and defensively copies avatar bytes',
    () async {
      final sourceAvatar = <int>[1, 2, 3, 4];
      final saved = await service.saveProfile(
        expectedRevision: 0,
        displayName: '  Alex   Bennett Carter  ',
        program: 'Family Nurse Practitioner',
        accountIdentity: 'alex@example.test',
        avatarBytes: sourceAvatar,
      );
      sourceAvatar[0] = 99;

      expect(saved.value.displayName, 'Alex   Bennett Carter');
      expect(saved.value.initials, 'AB');
      expect(saved.value.avatarBytes, [1, 2, 3, 4]);
      expect(() => saved.value.avatarBytes!.add(5), throwsUnsupportedError);

      final withoutAvatar = await service.saveProfile(
        expectedRevision: saved.revision,
        displayName: saved.value.displayName,
        program: saved.value.program,
        accountIdentity: saved.value.accountIdentity,
      );
      expect(withoutAvatar.value.hasAvatar, isFalse);
      expect(withoutAvatar.value.initials, 'AB');
    },
  );

  test(
    'settings and Schedule Template CRUD persist through repositories',
    () async {
      final settings = StudentSettings(
        weekStart: DateTime.monday,
        timeDisplay: TimeDisplayPreference.twelveHour,
        synchronization: SynchronizationPreference.paused,
        notifications: const NotificationPreferences(
          upcomingCommitmentsEnabled: false,
          weeklySummaryEnabled: false,
        ),
      );
      final savedSettings = await service.saveSettings(
        expectedRevision: 0,
        settings: settings,
      );
      final added = await service.addScheduleTemplate(
        name: 'Clinic morning',
        type: ScheduleTemplateType.clinicalSession,
        startTime: LocalTime(8, 30),
        endTime: LocalTime(12, 0),
        clinicalPlacementId: _id(10),
        preceptorId: _id(11),
      );
      expect(
        added.value.endTime.minutesSinceMidnight -
            added.value.startTime.minutesSinceMidnight,
        210,
      );

      final edited = await service.editScheduleTemplate(
        id: added.value.id,
        expectedRevision: added.revision,
        name: 'Clinic afternoon',
        type: ScheduleTemplateType.clinicalSession,
        startTime: LocalTime(13, 0),
        endTime: LocalTime(17, 30),
        clinicalPlacementId: _id(10),
        preceptorId: _id(11),
      );
      expect(edited.value.name, 'Clinic afternoon');

      final loaded = await service.load();
      expect(loaded.settings.revision, savedSettings.revision);
      expect(loaded.settings.value.weekStart, DateTime.monday);
      expect(
        loaded.settings.value.timeDisplay,
        TimeDisplayPreference.twelveHour,
      );
      expect(
        loaded.settings.value.synchronization,
        SynchronizationPreference.paused,
      );
      expect(loaded.settings.value.notifications.weeklySummaryEnabled, isFalse);
      expect(loaded.scheduleTemplates.single.value.name, 'Clinic afternoon');

      await service.removeScheduleTemplate(
        id: edited.value.id,
        expectedRevision: edited.revision,
      );
      expect((await service.load()).scheduleTemplates, isEmpty);
    },
  );

  test('invalid avatar and stale settings revision fail closed', () async {
    expect(
      () => StudentProfile(
        id: _profileId,
        displayName: 'Student',
        avatarBytes: const [],
      ),
      throwsArgumentError,
    );
    final authoritative = await service.saveSettings(
      expectedRevision: 0,
      settings: StudentSettings(
        themeId: 'future-theme',
        enhancedAccessibility: true,
      ),
    );
    await expectLater(
      service.saveSettings(
        expectedRevision: 0,
        settings: StudentSettings(weekStart: DateTime.monday),
      ),
      throwsA(
        isA<RepositoryException>()
            .having(
              (error) => error.kind,
              'kind',
              RepositoryFailureKind.concurrentModification,
            )
            .having(
              (error) => error.message,
              'actionable message',
              contains('changed'),
            ),
      ),
    );
    final afterFailure = (await service.load()).settings;
    expect(afterFailure.revision, authoritative.revision);
    expect(afterFailure.value.themeId, 'future-theme');
    expect(afterFailure.value.enhancedAccessibility, isTrue);
  });
}

final class _MemoryRegistry implements RepositoryRegistry {
  _MemoryRegistry() : repositories = _MemoryRepositories();

  final _MemoryRepositories repositories;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(repositories);
}

final class _MemoryRepositories implements SupportLocalWriteRepositories {
  _MemoryRepositories()
    : studentProfile = _MemoryStudentProfileRepository(),
      studentSettings = _MemoryStudentSettingsRepository();

  @override
  final _MemoryStudentProfileRepository studentProfile;
  @override
  final _MemoryStudentSettingsRepository studentSettings;
  @override
  final _MemoryEntityRepository<ScheduleTemplate> scheduleTemplates =
      _MemoryEntityRepository((value) => value.id);

  @override
  Never get activePlacementSelection => throw UnimplementedError();
  @override
  Never get clinicalPlacements => throw UnimplementedError();
  @override
  Never get clinicalSessions => throw UnimplementedError();
  @override
  Never get evaluationPlans => throw UnimplementedError();
  @override
  Never get historicalHoursEntries => throw UnimplementedError();
  @override
  Never get outbox => throw UnimplementedError();
  @override
  Never get preceptors => throw UnimplementedError();
  @override
  Never get protectedDays => throw UnimplementedError();
  @override
  Never get syncCursors => throw UnimplementedError();
  @override
  Never get workShifts => throw UnimplementedError();
}

final class _MemoryStudentProfileRepository
    implements StudentProfileRepository {
  StoredDomainRecord<StudentProfile> _record = StoredDomainRecord(
    value: StudentProfile(id: _profileId, displayName: 'Student'),
    studentId: _studentId,
    revision: 0,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );

  @override
  StoredDomainRecord<StudentProfile>? find({required String studentId}) =>
      studentId == _studentId ? _record : null;

  @override
  MutationReceipt<StudentProfile> put({
    required String studentId,
    required StudentProfile profile,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    _expected(expectedRevision, _record.revision);
    _record = StoredDomainRecord(
      value: profile,
      studentId: studentId,
      revision: _record.revision + 1,
      createdAtUtc: _record.createdAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: _record, replayed: false);
  }
}

final class _MemoryStudentSettingsRepository
    implements StudentSettingsRepository {
  StoredDomainRecord<StudentSettings>? _record;

  @override
  StoredDomainRecord<StudentSettings>? find({required String studentId}) =>
      _record;

  @override
  MutationReceipt<StudentSettings> put({
    required String studentId,
    required StudentSettings settings,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    _expected(expectedRevision, _record?.revision ?? 0);
    _record = StoredDomainRecord(
      value: settings,
      studentId: studentId,
      revision: (_record?.revision ?? 0) + 1,
      createdAtUtc: _record?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: _record!, replayed: false);
  }
}

final class _MemoryEntityRepository<T> implements MutableRepository<T> {
  _MemoryEntityRepository(this._idOf);

  final String Function(T) _idOf;
  final Map<String, StoredDomainRecord<T>> _records = {};

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => _records[id];

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => _records.values.toList(growable: false);

  @override
  MutationReceipt<T> put({
    required String studentId,
    required T value,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final id = _idOf(value);
    final existing = _records[id];
    _expected(expectedRevision, existing?.revision ?? 0);
    final record = StoredDomainRecord(
      value: value,
      studentId: studentId,
      revision: (existing?.revision ?? 0) + 1,
      createdAtUtc: existing?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    _records[id] = record;
    return MutationReceipt(record: record, replayed: false);
  }

  @override
  MutationReceipt<T> tombstone({
    required String studentId,
    required String id,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final existing = _records[id];
    if (existing == null) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'Record not found.',
      );
    }
    _expected(expectedRevision, existing.revision);
    _records.remove(id);
    return MutationReceipt(
      record: StoredDomainRecord(
        value: existing.value,
        studentId: studentId,
        revision: existing.revision + 1,
        createdAtUtc: existing.createdAtUtc,
        updatedAtUtc: mutation.occurredAtUtc,
        deletedAtUtc: mutation.occurredAtUtc,
      ),
      replayed: false,
    );
  }
}

void _expected(int expected, int actual) {
  if (expected != actual) {
    throw const RepositoryException(
      RepositoryFailureKind.concurrentModification,
      'Revision mismatch.',
    );
  }
}

final class _Clock implements Clock {
  int _minutes = 0;

  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 3, 12, _minutes++);
}

final class _Identifiers implements IdentifierGenerator {
  int _next = 100;

  @override
  String nextIdentifier() => _id(_next++);
}

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';
