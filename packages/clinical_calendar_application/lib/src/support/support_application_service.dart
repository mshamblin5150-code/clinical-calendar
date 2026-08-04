import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../ports.dart';
import '../repositories.dart';

final class SupportApplicationService {
  factory SupportApplicationService({
    required RepositoryRegistry repositories,
    required Clock clock,
    required IdentifierGenerator identifiers,
    required String studentId,
  }) => SupportApplicationService._(
    repositories,
    clock,
    identifiers,
    requireIdentifier(studentId, 'Student id'),
  );

  const SupportApplicationService._(
    this._repositories,
    this._clock,
    this._identifiers,
    this._studentId,
  );

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;
  final String _studentId;

  Future<SupportSnapshot> load() => _repositories.read((repositories) {
    final support = _readSupport(repositories);
    final profile = support.studentProfile.find(studentId: _studentId);
    if (profile == null) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'The Student Profile does not exist.',
      );
    }
    final settings = support.studentSettings.find(studentId: _studentId);
    return SupportSnapshot(
      profile: StoredSupportRecord(
        value: profile.value,
        revision: profile.revision,
      ),
      settings: StoredSupportRecord(
        value: settings?.value ?? StudentSettings(),
        revision: settings?.revision ?? 0,
      ),
      scheduleTemplates: repositories.scheduleTemplates
          .list(studentId: _studentId)
          .map(
            (record) => StoredSupportRecord(
              value: record.value,
              revision: record.revision,
            ),
          )
          .toList(growable: false),
    );
  });

  Future<StoredSupportRecord<StudentProfile>> saveProfile({
    required int expectedRevision,
    required String displayName,
    String? program,
    String? accountIdentity,
    List<int>? avatarBytes,
  }) {
    final occurredAtUtc = _now();
    return _repositories.mutate((repositories) {
      final support = _writeSupport(repositories);
      final existing = support.studentProfile.find(studentId: _studentId);
      if (existing == null) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'The Student Profile does not exist.',
        );
      }
      final receipt = support.studentProfile.put(
        studentId: _studentId,
        profile: StudentProfile(
          id: existing.value.id,
          displayName: displayName,
          program: program,
          accountIdentity: accountIdentity,
          avatarBytes: avatarBytes,
        ),
        expectedRevision: expectedRevision,
        mutation: _mutation(occurredAtUtc),
      );
      return StoredSupportRecord(
        value: receipt.record.value,
        revision: receipt.record.revision,
      );
    });
  }

  Future<StoredSupportRecord<StudentSettings>> saveSettings({
    required int expectedRevision,
    required StudentSettings settings,
  }) {
    final occurredAtUtc = _now();
    return _repositories.mutate((repositories) {
      final receipt = _writeSupport(repositories).studentSettings.put(
        studentId: _studentId,
        settings: settings,
        expectedRevision: expectedRevision,
        mutation: _mutation(occurredAtUtc),
      );
      return StoredSupportRecord(
        value: receipt.record.value,
        revision: receipt.record.revision,
      );
    });
  }

  Future<StoredSupportRecord<ScheduleTemplate>> addScheduleTemplate({
    required String name,
    required ScheduleTemplateType type,
    required LocalTime startTime,
    required LocalTime endTime,
    String? clinicalPlacementId,
    String? preceptorId,
  }) => _putScheduleTemplate(
    expectedRevision: 0,
    template: ScheduleTemplate(
      id: _identifiers.nextIdentifier(),
      name: name,
      type: type,
      startTime: startTime,
      endTime: endTime,
      clinicalPlacementId: clinicalPlacementId,
      preceptorId: preceptorId,
    ),
  );

  Future<StoredSupportRecord<ScheduleTemplate>> editScheduleTemplate({
    required String id,
    required int expectedRevision,
    required String name,
    required ScheduleTemplateType type,
    required LocalTime startTime,
    required LocalTime endTime,
    String? clinicalPlacementId,
    String? preceptorId,
  }) => _putScheduleTemplate(
    expectedRevision: expectedRevision,
    template: ScheduleTemplate(
      id: id,
      name: name,
      type: type,
      startTime: startTime,
      endTime: endTime,
      clinicalPlacementId: clinicalPlacementId,
      preceptorId: preceptorId,
    ),
  );

  Future<void> removeScheduleTemplate({
    required String id,
    required int expectedRevision,
  }) {
    final occurredAtUtc = _now();
    return _repositories.mutate((repositories) {
      repositories.scheduleTemplates.tombstone(
        studentId: _studentId,
        id: id,
        expectedRevision: expectedRevision,
        mutation: _mutation(occurredAtUtc),
      );
    });
  }

  Future<StoredSupportRecord<ScheduleTemplate>> _putScheduleTemplate({
    required int expectedRevision,
    required ScheduleTemplate template,
  }) {
    final occurredAtUtc = _now();
    return _repositories.mutate((repositories) {
      final receipt = repositories.scheduleTemplates.put(
        studentId: _studentId,
        value: template,
        expectedRevision: expectedRevision,
        mutation: _mutation(occurredAtUtc),
      );
      return StoredSupportRecord(
        value: receipt.record.value,
        revision: receipt.record.revision,
      );
    });
  }

  MutationToken _mutation(DateTime occurredAtUtc) => MutationToken(
    operationId: _identifiers.nextIdentifier(),
    idempotencyKey: _identifiers.nextIdentifier(),
    occurredAtUtc: occurredAtUtc,
  );

  DateTime _now() {
    final value = _clock.nowUtc();
    if (!value.isUtc) {
      throw StateError('Clock must return UTC.');
    }
    return value;
  }

  SupportLocalReadRepositories _readSupport(
    LocalReadRepositories repositories,
  ) {
    if (repositories case final SupportLocalReadRepositories support) {
      return support;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Support repositories are unavailable.',
    );
  }

  SupportLocalWriteRepositories _writeSupport(
    LocalWriteRepositories repositories,
  ) {
    if (repositories case final SupportLocalWriteRepositories support) {
      return support;
    }
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Support repositories are unavailable.',
    );
  }
}
