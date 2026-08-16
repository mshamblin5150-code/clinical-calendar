import '../domain_validation.dart';
import '../time/local_date.dart';
import '../time/zoned_interval.dart';

enum ClinicalSessionState {
  scheduled,
  awaitingConfirmation,
  completed,
  cancelled,
  missed;

  bool canTransitionTo(ClinicalSessionState next) => switch (this) {
    scheduled => next == awaitingConfirmation || next == cancelled,
    awaitingConfirmation =>
      next == scheduled ||
          next == completed ||
          next == cancelled ||
          next == missed,
    completed => next == scheduled || next == awaitingConfirmation,
    cancelled || missed => false,
  };
}

/// A time-zone-specific Clinical Placement commitment.
final class ClinicalSession {
  factory ClinicalSession.schedule({
    required String id,
    required String clinicalPlacementId,
    required String preceptorId,
    required ZonedInterval plannedInterval,
    required DateTime asOfUtc,
  }) => ClinicalSession._(
    id: requireIdentifier(id, 'Clinical Session id'),
    clinicalPlacementId: requireIdentifier(
      clinicalPlacementId,
      'Clinical Placement id',
    ),
    preceptorId: requireIdentifier(preceptorId, 'Preceptor id'),
    plannedInterval: plannedInterval,
    state: _plannedState(plannedInterval, asOfUtc),
  );

  factory ClinicalSession.restore({
    required String id,
    required String clinicalPlacementId,
    required String preceptorId,
    required ZonedInterval plannedInterval,
    required ClinicalSessionState state,
    ZonedInterval? actualInterval,
  }) {
    if (state == ClinicalSessionState.completed && actualInterval == null) {
      throw const DomainValidationException(
        'A Completed Session requires a confirmed actual interval.',
      );
    }
    if (state != ClinicalSessionState.completed && actualInterval != null) {
      throw const DomainValidationException(
        'Only a Completed Session may have a confirmed actual interval.',
      );
    }
    if (actualInterval != null &&
        actualInterval.timeZone != plannedInterval.timeZone) {
      throw const DomainValidationException(
        'A confirmed actual interval must retain the Clinical Session time zone.',
      );
    }
    return ClinicalSession._(
      id: requireIdentifier(id, 'Clinical Session id'),
      clinicalPlacementId: requireIdentifier(
        clinicalPlacementId,
        'Clinical Placement id',
      ),
      preceptorId: requireIdentifier(preceptorId, 'Preceptor id'),
      plannedInterval: plannedInterval,
      state: state,
      actualInterval: actualInterval,
    );
  }

  const ClinicalSession._({
    required this.id,
    required this.clinicalPlacementId,
    required this.preceptorId,
    required this.plannedInterval,
    required this.state,
    this.actualInterval,
  });

  final String id;
  final String clinicalPlacementId;
  final String preceptorId;
  final ZonedInterval plannedInterval;
  final ClinicalSessionState state;
  final ZonedInterval? actualInterval;

  int get plannedMinutes => plannedInterval.elapsedMinutes;

  int get completedMinutes => state == ClinicalSessionState.completed
      ? actualInterval!.elapsedMinutes
      : 0;

  ClinicalSession refreshStatus(DateTime asOfUtc) {
    final next = _plannedState(plannedInterval, asOfUtc);
    if (state == ClinicalSessionState.scheduled &&
        next == ClinicalSessionState.awaitingConfirmation) {
      return _copyWith(state: next);
    }
    return this;
  }

  ClinicalSession complete(ZonedInterval confirmedActualInterval) {
    _requireTransition(ClinicalSessionState.completed);
    if (confirmedActualInterval.timeZone != plannedInterval.timeZone) {
      throw const DomainValidationException(
        'A confirmed actual interval must retain the Clinical Session time zone.',
      );
    }
    return _copyWith(
      state: ClinicalSessionState.completed,
      actualInterval: confirmedActualInterval,
    );
  }

  ClinicalSession cancel() {
    _requireTransition(ClinicalSessionState.cancelled);
    return _copyWith(state: ClinicalSessionState.cancelled);
  }

  ClinicalSession markMissed() {
    _requireTransition(ClinicalSessionState.missed);
    return _copyWith(state: ClinicalSessionState.missed);
  }

  ClinicalSession revisePlannedDetails({
    required ZonedInterval plannedInterval,
    required String preceptorId,
    required LocalDate today,
  }) {
    if (state == ClinicalSessionState.cancelled ||
        state == ClinicalSessionState.missed) {
      throw DomainValidationException(
        'A ${state.name} Clinical Session cannot be rescheduled.',
      );
    }
    final nextState = plannedInterval.startDate.isBefore(today)
        ? ClinicalSessionState.awaitingConfirmation
        : ClinicalSessionState.scheduled;
    if (state != nextState && !state.canTransitionTo(nextState)) {
      throw DomainValidationException(
        'Clinical Session cannot transition from ${state.name} '
        'to ${nextState.name}.',
      );
    }
    return ClinicalSession._(
      id: id,
      clinicalPlacementId: clinicalPlacementId,
      preceptorId: requireIdentifier(preceptorId, 'Preceptor id'),
      plannedInterval: plannedInterval,
      state: nextState,
    );
  }

  void _requireTransition(ClinicalSessionState next) {
    if (!state.canTransitionTo(next)) {
      throw DomainValidationException(
        'Clinical Session cannot transition from ${state.name} '
        'to ${next.name}.',
      );
    }
  }

  ClinicalSession _copyWith({
    required ClinicalSessionState state,
    ZonedInterval? actualInterval,
  }) => ClinicalSession._(
    id: id,
    clinicalPlacementId: clinicalPlacementId,
    preceptorId: preceptorId,
    plannedInterval: plannedInterval,
    state: state,
    actualInterval: actualInterval,
  );
}

ClinicalSessionState _plannedState(ZonedInterval interval, DateTime asOfUtc) =>
    interval.endInstantUtc.isAfter(asOfUtc.toUtc())
    ? ClinicalSessionState.scheduled
    : ClinicalSessionState.awaitingConfirmation;
