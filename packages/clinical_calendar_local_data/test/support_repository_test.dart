import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_local_data/clinical_calendar_local_data.dart';
import 'package:test/test.dart';

const _key =
    '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';
const _studentId = '00000000-0000-4000-8000-000000000001';
final _baseTime = DateTime.now().toUtc().add(const Duration(hours: 1));

void main() {
  late Directory temporaryDirectory;
  late String databasePath;
  late ClinicalCalendarDatabase database;
  late SqliteRepositoryRegistry registry;
  late _Identifiers identifiers;
  var databaseIsOpen = false;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'clinical-calendar-support-',
    );
    databasePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}calendar.db';
    database = await ClinicalCalendarDatabase.open(
      path: databasePath,
      secureStorage: _MemorySecureStorage(_key),
    );
    databaseIsOpen = true;
    identifiers = _Identifiers();
    registry = _registry(database, identifiers);
    await registry.initialize();
  });

  tearDown(() async {
    if (databaseIsOpen) await database.close();
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'profile, avatar, settings, and template survive offline restart',
    () async {
      final sourceAvatar = <int>[137, 80, 78, 71, 13, 10, 26, 10];
      await registry.mutate((repositories) {
        final support = repositories as SupportLocalWriteRepositories;
        final currentProfile = support.studentProfile.find(
          studentId: _studentId,
        )!;
        support.studentProfile.put(
          studentId: _studentId,
          profile: StudentProfile(
            id: currentProfile.value.id,
            displayName: 'Alex Bennett',
            program: 'Family Nurse Practitioner',
            accountIdentity: 'alex@example.test',
            avatarBytes: sourceAvatar,
          ),
          expectedRevision: currentProfile.revision,
          mutation: _mutation(1),
        );
        support.studentSettings.put(
          studentId: _studentId,
          settings: StudentSettings(
            weekStart: DateTime.monday,
            timeDisplay: TimeDisplayPreference.twelveHour,
            synchronization: SynchronizationPreference.paused,
            notifications: const NotificationPreferences(
              upcomingCommitmentsEnabled: false,
              weeklySummaryEnabled: false,
              backupRemindersEnabled: true,
            ),
          ),
          expectedRevision: 0,
          mutation: _mutation(2),
        );
        repositories.scheduleTemplates.put(
          studentId: _studentId,
          value: ScheduleTemplate(
            id: _id(20),
            name: 'Overnight Work Shift',
            type: ScheduleTemplateType.workShift,
            startTime: LocalTime(19, 0),
            endTime: LocalTime(7, 0),
          ),
          expectedRevision: 0,
          mutation: _mutation(3),
        );
      });
      sourceAvatar[0] = 0;

      await database.close();
      databaseIsOpen = false;
      database = await ClinicalCalendarDatabase.open(
        path: databasePath,
        secureStorage: _MemorySecureStorage(_key),
      );
      databaseIsOpen = true;
      registry = _registry(database, identifiers);
      await registry.initialize();

      await registry.read((repositories) {
        final support = repositories as SupportLocalReadRepositories;
        final profile = support.studentProfile.find(studentId: _studentId)!;
        expect(profile.value.displayName, 'Alex Bennett');
        expect(profile.value.initials, 'AB');
        expect(profile.value.avatarBytes, [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(() => profile.value.avatarBytes!.add(1), throwsUnsupportedError);
        final settings = support.studentSettings.find(studentId: _studentId)!;
        expect(settings.value.weekStart, DateTime.monday);
        expect(settings.value.timeDisplay, TimeDisplayPreference.twelveHour);
        expect(settings.value.themeId, StudentSettings.graphiteThemeId);
        expect(
          settings.value.synchronization,
          SynchronizationPreference.paused,
        );
        expect(
          settings.value.notifications.upcomingCommitmentsEnabled,
          isFalse,
        );
        expect(settings.value.notifications.weeklySummaryEnabled, isFalse);
        final template = repositories.scheduleTemplates
            .list(studentId: _studentId)
            .single
            .value;
        expect(template.name, 'Overnight Work Shift');
        expect(template.isOvernight, isTrue);

        final entityTypes = repositories.outbox
            .pending(
              studentId: _studentId,
              asOfUtc: _baseTime.add(const Duration(hours: 1)),
            )
            .map((operation) => operation.entityType)
            .toSet();
        expect(
          entityTypes,
          containsAll(['student_profile', 'settings', 'schedule_template']),
        );
      });
    },
  );

  test(
    'settings and active Placement preserve each other in both directions',
    () async {
      await registry.mutate((repositories) {
        final support = repositories as SupportLocalWriteRepositories;
        support.studentSettings.put(
          studentId: _studentId,
          settings: StudentSettings(
            weekStart: DateTime.saturday,
            timeDisplay: TimeDisplayPreference.twelveHour,
            synchronization: SynchronizationPreference.paused,
            notifications: const NotificationPreferences(
              backupRemindersEnabled: false,
            ),
          ),
          expectedRevision: 0,
          mutation: _mutation(10),
        );
      });
      final preceptorId = _id(30);
      final placementId = _id(31);
      final planId = _id(32);
      await registry.mutate((repositories) {
        repositories.preceptors.put(
          studentId: _studentId,
          value: Preceptor(id: preceptorId, name: 'Jordan Lee'),
          expectedRevision: 0,
          mutation: _mutation(11),
        );
        repositories.clinicalPlacements.put(
          studentId: _studentId,
          value: ClinicalPlacement.create(
            id: placementId,
            name: 'Family Medicine',
            targetHours: TargetHours.fromWholeHours(270),
            startDate: LocalDate(2026, 8, 1),
            completionDeadline: LocalDate(2026, 12, 31),
            attachedPreceptorIds: [preceptorId],
            primaryPreceptorId: preceptorId,
            evaluationPlanId: planId,
          ),
          expectedRevision: 0,
          mutation: _mutation(12),
        );
        repositories.evaluationPlans.put(
          studentId: _studentId,
          value: EvaluationPlan.restore(
            id: planId,
            configuration: EvaluationPlanConfiguration(),
            requirements: const [],
          ),
          expectedRevision: 0,
          mutation: _mutation(13),
        );
        final active = repositories.activePlacementSelection.find(
          studentId: _studentId,
        )!;
        repositories.activePlacementSelection.put(
          studentId: _studentId,
          clinicalPlacementId: placementId,
          expectedRevision: active.revision,
          mutation: _mutation(14),
        );
      });

      await registry.read((repositories) {
        final settings = (repositories as SupportLocalReadRepositories)
            .studentSettings
            .find(studentId: _studentId)!;
        expect(settings.value.weekStart, DateTime.saturday);
        expect(settings.value.timeDisplay, TimeDisplayPreference.twelveHour);
        expect(
          settings.value.synchronization,
          SynchronizationPreference.paused,
        );
        expect(settings.value.notifications.backupRemindersEnabled, isFalse);
        expect(
          repositories.activePlacementSelection
              .find(studentId: _studentId)!
              .value,
          placementId,
        );
      });

      await registry.mutate((repositories) {
        final support = repositories as SupportLocalWriteRepositories;
        final current = support.studentSettings.find(studentId: _studentId)!;
        support.studentSettings.put(
          studentId: _studentId,
          settings: StudentSettings(
            weekStart: DateTime.monday,
            notifications: const NotificationPreferences(
              upcomingCommitmentsEnabled: false,
            ),
          ),
          expectedRevision: current.revision,
          mutation: _mutation(15),
        );
      });
      await registry.read((repositories) {
        expect(
          repositories.activePlacementSelection
              .find(studentId: _studentId)!
              .value,
          placementId,
        );
        final settings = (repositories as SupportLocalReadRepositories)
            .studentSettings
            .find(studentId: _studentId)!;
        expect(settings.value.weekStart, DateTime.monday);
        expect(
          settings.value.notifications.upcomingCommitmentsEnabled,
          isFalse,
        );
      });
    },
  );

  test('profile and settings enforce revisions and idempotency', () async {
    final profileMutation = _mutation(20);
    await registry.mutate((repositories) {
      final support = repositories as SupportLocalWriteRepositories;
      final profile = support.studentProfile.find(studentId: _studentId)!;
      support.studentProfile.put(
        studentId: _studentId,
        profile: StudentProfile(
          id: profile.value.id,
          displayName: 'Student Name',
        ),
        expectedRevision: 0,
        mutation: profileMutation,
      );
    });
    final replay = await registry.mutate((repositories) {
      final support = repositories as SupportLocalWriteRepositories;
      final profile = support.studentProfile.find(studentId: _studentId)!;
      return support.studentProfile.put(
        studentId: _studentId,
        profile: StudentProfile(
          id: profile.value.id,
          displayName: 'Student Name',
        ),
        expectedRevision: 0,
        mutation: profileMutation,
      );
    });
    expect(replay.replayed, isTrue);
    expect(replay.record.revision, 1);

    await expectLater(
      registry.mutate((repositories) {
        final support = repositories as SupportLocalWriteRepositories;
        final profile = support.studentProfile.find(studentId: _studentId)!;
        support.studentProfile.put(
          studentId: _studentId,
          profile: StudentProfile(
            id: profile.value.id,
            displayName: 'Different Name',
          ),
          expectedRevision: 0,
          mutation: MutationToken(
            operationId: _id(999),
            idempotencyKey: profileMutation.idempotencyKey,
            occurredAtUtc: profileMutation.occurredAtUtc,
          ),
        );
      }),
      throwsA(
        isA<RepositoryException>().having(
          (error) => error.kind,
          'kind',
          RepositoryFailureKind.idempotencyConflict,
        ),
      ),
    );
  });
}

SqliteRepositoryRegistry _registry(
  ClinicalCalendarDatabase database,
  IdentifierGenerator identifiers,
) => SqliteRepositoryRegistry(
  studentId: _studentId,
  database: database,
  identifierGenerator: identifiers,
);

MutationToken _mutation(int sequence) => MutationToken(
  operationId: _id(1000 + sequence * 2),
  idempotencyKey: _id(1001 + sequence * 2),
  occurredAtUtc: _baseTime.add(Duration(minutes: sequence)),
);

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

final class _Identifiers implements IdentifierGenerator {
  int _next = 900000;

  @override
  String nextIdentifier() => _id(_next++);
}

final class _MemorySecureStorage implements SecureStorage {
  _MemorySecureStorage(String initialValue) {
    values[ClinicalCalendarDatabase.encryptionKeyStorageKey] = initialValue;
  }

  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
