import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../ports.dart';
import '../repositories.dart';
import 'scheduling_requests.dart';

/// Transactional scheduling use cases. Every mutation validates and writes in
/// one synchronous repository callback; synchronization never runs here.
final class SchedulingApplicationService {
  SchedulingApplicationService(
    this._repositories,
    this._clock,
    this._identifiers, {
    SchedulingInvariantEngine? invariantEngine,
    ClinicalPlacementProgressEngine? progressEngine,
  }) : _invariants = invariantEngine ?? SchedulingInvariantEngine(),
       _progress = progressEngine ?? const ClinicalPlacementProgressEngine();

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;
  final SchedulingInvariantEngine _invariants;
  final ClinicalPlacementProgressEngine _progress;

  Future<SchedulingMutationResult<WorkShift>> createWorkShiftBatch(
    WorkShiftBatchRequest request,
  ) => _repositories.mutate((repositories) {
    _requireNonempty(request.intervals);
    _requireUniqueDates(
      request.intervals.map((interval) => interval.startDate),
    );
    final now = _clock.nowUtc();
    final proposed = [
      for (final interval in request.intervals)
        WorkShift(id: _identifiers.nextIdentifier(), plannedInterval: interval),
    ];
    final validation = _invariants.validateBatch(
      existing: _state(repositories, request.studentId),
      batch: SchedulingBatch(workShifts: proposed),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<WorkShift>.conflicted(validation.errors);
    }
    final records = <StoredDomainRecord<WorkShift>>[];
    for (final shift in proposed) {
      records.add(
        repositories.workShifts
            .put(
              studentId: request.studentId,
              value: shift,
              expectedRevision: 0,
              mutation: _mutation(now),
            )
            .record,
      );
    }
    return SchedulingMutationResult<WorkShift>.committed(records);
  });

  Future<SchedulingMutationResult<ClinicalSession>> createClinicalSessionBatch(
    ClinicalSessionBatchRequest request,
  ) => _repositories.mutate((repositories) {
    _requireNonempty(request.intervals);
    _requireUniqueDates(
      request.intervals.map((interval) => interval.startDate),
    );
    final placement = _placement(
      repositories,
      request.studentId,
      request.clinicalPlacementId,
    );
    _requirePlacementOpen(placement.value);
    final now = _clock.nowUtc();
    final proposed = [
      for (final interval in request.intervals)
        ClinicalSession.schedule(
          id: _identifiers.nextIdentifier(),
          clinicalPlacementId: request.clinicalPlacementId,
          preceptorId: request.preceptorId,
          plannedInterval: interval,
          asOfUtc: now,
        ),
    ];
    for (final session in proposed) {
      placement.value.validateClinicalSession(session);
    }
    final validation = _invariants.validateBatch(
      existing: _state(repositories, request.studentId),
      batch: SchedulingBatch(clinicalSessions: proposed),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<ClinicalSession>.conflicted(
        validation.errors,
      );
    }
    final records = <StoredDomainRecord<ClinicalSession>>[];
    for (final session in proposed) {
      records.add(
        repositories.clinicalSessions
            .put(
              studentId: request.studentId,
              value: session,
              expectedRevision: 0,
              mutation: _mutation(now),
            )
            .record,
      );
    }
    return SchedulingMutationResult<ClinicalSession>.committed(records);
  });

  Future<SchedulingMutationResult<ProtectedDay>> createProtectedDayBatch(
    ProtectedDayBatchRequest request,
  ) => _repositories.mutate((repositories) {
    _requireNonempty(request.dates);
    _requireUniqueDates(request.dates);
    final now = _clock.nowUtc();
    final proposed = [
      for (final date in request.dates)
        ProtectedDay(id: _identifiers.nextIdentifier(), date: date),
    ];
    final validation = _invariants.validateBatch(
      existing: _state(repositories, request.studentId),
      batch: SchedulingBatch(protectedDays: proposed),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<ProtectedDay>.conflicted(
        validation.errors,
      );
    }
    final records = <StoredDomainRecord<ProtectedDay>>[];
    for (final day in proposed) {
      records.add(
        repositories.protectedDays
            .put(
              studentId: request.studentId,
              value: day,
              expectedRevision: 0,
              mutation: _mutation(now),
            )
            .record,
      );
    }
    return SchedulingMutationResult<ProtectedDay>.committed(records);
  });

  Future<SchedulingMutationResult<Object>> applyTemplate(
    TemplateBatchRequest request,
  ) => _repositories.mutate((repositories) {
    _requireNonempty(request.dates);
    _requireUniqueDates(request.dates.map((date) => date.date));
    final template = _required(
      repositories.scheduleTemplates.find(
        studentId: request.studentId,
        id: request.templateId,
      ),
      'Schedule Template',
    ).value;
    final intervals = [
      for (final date in request.dates)
        date.interval(startTime: template.startTime, endTime: template.endTime),
    ];
    final now = _clock.nowUtc();
    switch (template.type) {
      case ScheduleTemplateType.workShift:
        if (request.clinicalPlacementId != null ||
            request.preceptorId != null) {
          throw const SchedulingUseCaseException(
            SchedulingUseCaseFailureKind.templateTypeMismatch,
            'A Work Shift template cannot apply a clinical assignment.',
          );
        }
        final proposed = [
          for (final interval in intervals)
            WorkShift(
              id: _identifiers.nextIdentifier(),
              plannedInterval: interval,
            ),
        ];
        final validation = _invariants.validateBatch(
          existing: _state(repositories, request.studentId),
          batch: SchedulingBatch(workShifts: proposed),
        );
        if (!validation.canCommit) {
          return SchedulingMutationResult<Object>.conflicted(validation.errors);
        }
        return SchedulingMutationResult<Object>.committed([
          for (final value in proposed)
            repositories.workShifts
                .put(
                  studentId: request.studentId,
                  value: value,
                  expectedRevision: 0,
                  mutation: _mutation(now),
                )
                .record,
        ]);
      case ScheduleTemplateType.clinicalSession:
        final placementId =
            request.clinicalPlacementId ?? template.clinicalPlacementId;
        final preceptorId = request.preceptorId ?? template.preceptorId;
        if ((request.clinicalPlacementId == null) !=
                (request.preceptorId == null) ||
            placementId == null ||
            preceptorId == null) {
          throw const SchedulingUseCaseException(
            SchedulingUseCaseFailureKind.incompleteClinicalAssignment,
            'A Clinical Session template requires a Clinical Placement and '
            'Preceptor supplied together.',
          );
        }
        final placement = _placement(
          repositories,
          request.studentId,
          placementId,
        ).value;
        _requirePlacementOpen(placement);
        final proposed = [
          for (final interval in intervals)
            ClinicalSession.schedule(
              id: _identifiers.nextIdentifier(),
              clinicalPlacementId: placementId,
              preceptorId: preceptorId,
              plannedInterval: interval,
              asOfUtc: now,
            ),
        ];
        for (final session in proposed) {
          placement.validateClinicalSession(session);
        }
        final validation = _invariants.validateBatch(
          existing: _state(repositories, request.studentId),
          batch: SchedulingBatch(clinicalSessions: proposed),
        );
        if (!validation.canCommit) {
          return SchedulingMutationResult<Object>.conflicted(validation.errors);
        }
        return SchedulingMutationResult<Object>.committed([
          for (final value in proposed)
            repositories.clinicalSessions
                .put(
                  studentId: request.studentId,
                  value: value,
                  expectedRevision: 0,
                  mutation: _mutation(now),
                )
                .record,
        ]);
    }
  });

  Future<SchedulingMutationResult<WorkShift>> moveWorkShift({
    required String studentId,
    required String id,
    required ZonedInterval plannedInterval,
  }) => _repositories.mutate((repositories) {
    final current = _required(
      repositories.workShifts.find(studentId: studentId, id: id),
      'Work Shift',
    );
    final moved = WorkShift(id: id, plannedInterval: plannedInterval);
    final validation = _invariants.validateBatch(
      existing: _state(repositories, studentId, excludingId: id),
      batch: SchedulingBatch(workShifts: [moved]),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<WorkShift>.conflicted(validation.errors);
    }
    final record = repositories.workShifts
        .put(
          studentId: studentId,
          value: moved,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
    return SchedulingMutationResult<WorkShift>.committed([record]);
  });

  Future<SchedulingMutationResult<ClinicalSession>> moveClinicalSession({
    required String studentId,
    required String id,
    required ZonedInterval plannedInterval,
  }) => _repositories.mutate((repositories) {
    final current = _required(
      repositories.clinicalSessions.find(studentId: studentId, id: id),
      'Clinical Session',
    );
    final placement = _placement(
      repositories,
      studentId,
      current.value.clinicalPlacementId,
    ).value;
    _requirePlacementOpen(placement);
    final moved = current.value.reschedule(
      plannedInterval: plannedInterval,
      today: _today(_clock.nowUtc(), plannedInterval.startOffset),
    );
    placement.validateClinicalSession(moved);
    final validation = _invariants.validateBatch(
      existing: _state(repositories, studentId, excludingId: id),
      batch: SchedulingBatch(clinicalSessions: [moved]),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<ClinicalSession>.conflicted(
        validation.errors,
      );
    }
    final record = repositories.clinicalSessions
        .put(
          studentId: studentId,
          value: moved,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
    return SchedulingMutationResult<ClinicalSession>.committed([record]);
  });

  Future<SchedulingMutationResult<ClinicalSession>> confirmClinicalSession({
    required String studentId,
    required String id,
    required ZonedInterval actualInterval,
    required String preceptorId,
  }) => _repositories.mutate((repositories) {
    final current = _required(
      repositories.clinicalSessions.find(studentId: studentId, id: id),
      'Clinical Session',
    );
    final placement = _placement(
      repositories,
      studentId,
      current.value.clinicalPlacementId,
    ).value;
    _requirePlacementOpen(placement);
    final corrected = ClinicalSession.restore(
      id: current.value.id,
      clinicalPlacementId: current.value.clinicalPlacementId,
      preceptorId: preceptorId,
      plannedInterval: current.value.plannedInterval,
      state: current.value.state,
    ).complete(actualInterval);
    placement.validateClinicalSession(corrected);
    final validation = _invariants.validateBatch(
      existing: _state(repositories, studentId, excludingId: id),
      batch: SchedulingBatch(clinicalSessions: [corrected]),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<ClinicalSession>.conflicted(
        validation.errors,
      );
    }
    final record = repositories.clinicalSessions
        .put(
          studentId: studentId,
          value: corrected,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
    return SchedulingMutationResult<ClinicalSession>.committed([record]);
  });

  Future<StoredDomainRecord<ClinicalSession>> cancelClinicalSession({
    required String studentId,
    required String id,
  }) => _changeSession(
    studentId: studentId,
    id: id,
    change: (session) => session.cancel(),
  );

  Future<StoredDomainRecord<ClinicalSession>> markClinicalSessionMissed({
    required String studentId,
    required String id,
  }) => _changeSession(
    studentId: studentId,
    id: id,
    change: (session) => session.markMissed(),
  );

  Future<StoredDomainRecord<ClinicalSession>> _changeSession({
    required String studentId,
    required String id,
    required ClinicalSession Function(ClinicalSession) change,
  }) => _repositories.mutate((repositories) {
    final current = _required(
      repositories.clinicalSessions.find(studentId: studentId, id: id),
      'Clinical Session',
    );
    final placement = _placement(
      repositories,
      studentId,
      current.value.clinicalPlacementId,
    ).value;
    _requirePlacementOpen(placement);
    return repositories.clinicalSessions
        .put(
          studentId: studentId,
          value: change(current.value),
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
  });

  Future<StoredDomainRecord<WorkShift>> deleteWorkShift(
    ErroneousDeletionRequest request,
  ) => _repositories.mutate((repositories) {
    _requireConfirmedDeletion(request);
    final current = _required(
      repositories.workShifts.find(
        studentId: request.studentId,
        id: request.id,
      ),
      'Work Shift',
    );
    return repositories.workShifts
        .tombstone(
          studentId: request.studentId,
          id: request.id,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
  });

  Future<StoredDomainRecord<ClinicalSession>> deleteClinicalSession(
    ErroneousDeletionRequest request,
  ) => _repositories.mutate((repositories) {
    _requireConfirmedDeletion(request);
    final current = _required(
      repositories.clinicalSessions.find(
        studentId: request.studentId,
        id: request.id,
      ),
      'Clinical Session',
    );
    return repositories.clinicalSessions
        .tombstone(
          studentId: request.studentId,
          id: request.id,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
  });

  Future<SchedulingMutationResult<ProtectedDay>> moveProtectedDay({
    required String studentId,
    required String id,
    required LocalDate destination,
  }) => _repositories.mutate((repositories) {
    final current = _required(
      repositories.protectedDays.find(studentId: studentId, id: id),
      'Protected Day',
    );
    if (_invariants.weekContaining(current.value.date) !=
        _invariants.weekContaining(destination)) {
      throw const SchedulingUseCaseException(
        SchedulingUseCaseFailureKind.protectedDayMoveChangesWeek,
        'A Protected Day must be moved within its existing calendar week.',
      );
    }
    final moved = ProtectedDay(id: id, date: destination);
    final validation = _invariants.validateBatch(
      existing: _state(repositories, studentId, excludingId: id),
      batch: SchedulingBatch(protectedDays: [moved]),
    );
    if (!validation.canCommit) {
      return SchedulingMutationResult<ProtectedDay>.conflicted(
        validation.errors,
      );
    }
    final record = repositories.protectedDays
        .put(
          studentId: studentId,
          value: moved,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
    return SchedulingMutationResult<ProtectedDay>.committed([record]);
  });

  Future<StoredDomainRecord<ProtectedDay>> removeProtectedDay({
    required String studentId,
    required String id,
  }) => _repositories.mutate((repositories) {
    final current = _required(
      repositories.protectedDays.find(studentId: studentId, id: id),
      'Protected Day',
    );
    return repositories.protectedDays
        .tombstone(
          studentId: studentId,
          id: id,
          expectedRevision: current.revision,
          mutation: _mutation(_clock.nowUtc()),
        )
        .record;
  });

  Future<List<CalendarWeek>> missingProtectedDayWeeks({
    required String studentId,
    required int year,
    required int month,
  }) => _repositories.read((repositories) {
    return _invariants.missingProtectedDayWeeksForMonth(
      year: year,
      month: month,
      protectedDays: repositories.protectedDays
          .list(studentId: studentId)
          .map((record) => record.value),
    );
  });

  Future<ClinicalPlacementProgress> readPlacementProgress({
    required String studentId,
    required String clinicalPlacementId,
    required LocalDate today,
  }) => _repositories.read((repositories) {
    final placement = _placement(
      repositories,
      studentId,
      clinicalPlacementId,
    ).value;
    return _progress.derivePlacement(
      placement: placement,
      sessions: repositories.clinicalSessions
          .list(studentId: studentId)
          .map((record) => record.value),
      historicalHoursEntries: repositories.historicalHoursEntries
          .list(studentId: studentId)
          .map((record) => record.value),
      today: today,
    );
  });

  SchedulingState _state(
    LocalReadRepositories repositories,
    String studentId, {
    String? excludingId,
  }) => SchedulingState(
    workShifts: repositories.workShifts
        .list(studentId: studentId)
        .map((record) => record.value)
        .where((value) => value.id != excludingId),
    clinicalSessions: repositories.clinicalSessions
        .list(studentId: studentId)
        .map((record) => record.value)
        .where((value) => value.id != excludingId),
    protectedDays: repositories.protectedDays
        .list(studentId: studentId)
        .map((record) => record.value)
        .where((value) => value.id != excludingId),
  );

  StoredDomainRecord<ClinicalPlacement> _placement(
    LocalReadRepositories repositories,
    String studentId,
    String id,
  ) => _required(
    repositories.clinicalPlacements.find(studentId: studentId, id: id),
    'Clinical Placement',
  );

  MutationToken _mutation(DateTime occurredAtUtc) => MutationToken(
    operationId: _identifiers.nextIdentifier(),
    idempotencyKey: _identifiers.nextIdentifier(),
    occurredAtUtc: occurredAtUtc,
  );
}

StoredDomainRecord<T> _required<T>(
  StoredDomainRecord<T>? record,
  String entityName,
) {
  if (record == null) {
    throw SchedulingUseCaseException(
      SchedulingUseCaseFailureKind.notFound,
      '$entityName was not found.',
    );
  }
  return record;
}

void _requireNonempty(Iterable<Object> values) {
  if (values.isEmpty) {
    throw const SchedulingUseCaseException(
      SchedulingUseCaseFailureKind.emptyBatch,
      'A scheduling batch must contain at least one date.',
    );
  }
}

void _requireUniqueDates(Iterable<LocalDate> dates) {
  final observed = <LocalDate>{};
  for (final date in dates) {
    if (!observed.add(date)) {
      throw const SchedulingUseCaseException(
        SchedulingUseCaseFailureKind.duplicateDate,
        'A scheduling batch cannot contain the same selected date twice.',
      );
    }
  }
}

void _requirePlacementOpen(ClinicalPlacement placement) {
  if (placement.state == ClinicalPlacementState.completed) {
    throw const SchedulingUseCaseException(
      SchedulingUseCaseFailureKind.completedPlacement,
      'Completed Placements reject scheduling changes until reopened.',
    );
  }
}

void _requireConfirmedDeletion(ErroneousDeletionRequest request) {
  if (!request.confirmed) {
    throw const SchedulingUseCaseException(
      SchedulingUseCaseFailureKind.deletionNotConfirmed,
      'Permanent deletion of an erroneous or duplicate entry requires '
      'confirmation.',
    );
  }
}

LocalDate _today(DateTime nowUtc, UtcOffset offset) {
  final local = nowUtc.toUtc().add(offset.duration);
  return LocalDate(local.year, local.month, local.day);
}
