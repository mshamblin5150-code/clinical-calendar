import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Preceptor', () {
    test('validates and normalizes reusable person details', () {
      final preceptor = Preceptor(
        id: 'preceptor-1',
        name: ' Dr. Kathryn Janeway ',
        organizationOrSite: ' Sickbay ',
        email: 'janeway@example.test',
      );

      expect(preceptor.name, 'Dr. Kathryn Janeway');
      expect(preceptor.organizationOrSite, 'Sickbay');
      expect(
        () => Preceptor(id: 'preceptor-2', name: ' ', email: 'invalid'),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('ClinicalPlacement relationships', () {
    test('requires a valid date window and attached Primary Preceptor', () {
      expect(
        () => _placement(
          startDate: LocalDate(2026, 9, 1),
          completionDeadline: LocalDate(2026, 8, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => _placement(primaryPreceptorId: 'not-attached'),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => TargetHours.fromMinutes(0),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('changes Primary without changing identities or attached history', () {
      final original = _placement();
      final changed = original.changePrimaryPreceptor('preceptor-2');

      expect(changed.id, original.id);
      expect(changed.evaluationPlanId, original.evaluationPlanId);
      expect(changed.primaryPreceptorId, 'preceptor-2');
      expect(changed.attachedPreceptorIds, {'preceptor-1', 'preceptor-2'});
    });

    test('rejects detaching Primary or referenced Preceptors', () {
      final placement = _placement();
      final noReferences = PreceptorReferenceSummary(
        clinicalSessionCount: 0,
        historicalHoursEntryCount: 0,
        evaluationRecordCount: 0,
      );
      final referenced = PreceptorReferenceSummary(
        clinicalSessionCount: 1,
        historicalHoursEntryCount: 0,
        evaluationRecordCount: 0,
      );

      expect(
        () => placement.detachPreceptor('preceptor-1', noReferences),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => placement.detachPreceptor('preceptor-2', referenced),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        placement
            .detachPreceptor('preceptor-2', noReferences)
            .attachedPreceptorIds,
        {'preceptor-1'},
      );
    });

    test('validates Clinical Session membership and inclusive window', () {
      final placement = _placement();
      placement.validateClinicalSession(
        _session(date: LocalDate(2026, 8, 30), end: '0200', start: '2200'),
      );

      expect(
        () => placement.validateClinicalSession(
          _session(date: LocalDate(2026, 9, 1)),
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => placement.validateClinicalSession(
          _session(date: LocalDate(2026, 8, 15), preceptorId: 'detached'),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('blocks a window change that strands an existing session', () {
      final placement = _placement();
      final existing = _session(date: LocalDate(2026, 8, 10));

      expect(
        () => placement.changeWindow(
          startDate: LocalDate(2026, 8, 11),
          completionDeadline: LocalDate(2026, 8, 31),
          existingSessions: [existing],
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('HistoricalHoursEntry', () {
    test('supports attached Preceptor or Unattributed ownership', () {
      final placement = _placement();
      final attributed = _historical(preceptorId: 'preceptor-2');
      final unattributed = _historical();

      placement.validateHistoricalHoursEntry(attributed);
      placement.validateHistoricalHoursEntry(unattributed);
      expect(attributed.isUnattributed, isFalse);
      expect(unattributed.isUnattributed, isTrue);
      expect(unattributed.completedMinutes, 375);
    });

    test('rejects detached Preceptor attribution and nonpositive minutes', () {
      final placement = _placement();

      expect(
        () => placement.validateHistoricalHoursEntry(
          _historical(preceptorId: 'detached'),
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => HistoricalHoursEntry(
          id: 'historical-2',
          clinicalPlacementId: 'placement-1',
          completedMinutes: 0,
          effectiveDate: LocalDate(2026, 8, 1),
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('Clinical Placement lifecycle', () {
    test('requires every settled condition before Ready to Complete', () {
      final placement = _placement();
      final insufficient = PlacementCompletionEvidence(
        completedMinutes: 270 * 60 - 1,
        allRequiredEvaluationsDocumented: true,
        awaitingConfirmationSessionCount: 0,
        scheduledFutureSessionCount: 0,
      );
      final unresolved = PlacementCompletionEvidence(
        completedMinutes: 270 * 60,
        allRequiredEvaluationsDocumented: true,
        awaitingConfirmationSessionCount: 1,
        scheduledFutureSessionCount: 0,
      );
      final ready = PlacementCompletionEvidence(
        completedMinutes: 270 * 60,
        allRequiredEvaluationsDocumented: true,
        awaitingConfirmationSessionCount: 0,
        scheduledFutureSessionCount: 0,
      );

      expect(
        placement.evaluateReadiness(insufficient).state,
        ClinicalPlacementState.active,
      );
      expect(
        placement.evaluateReadiness(unresolved).state,
        ClinicalPlacementState.active,
      );
      expect(
        placement.evaluateReadiness(ready).state,
        ClinicalPlacementState.readyToComplete,
      );
    });

    test(
      'completes explicitly, locks edits, and reopens without data loss',
      () {
        final ready = _placement().evaluateReadiness(
          PlacementCompletionEvidence(
            completedMinutes: 270 * 60,
            allRequiredEvaluationsDocumented: true,
            awaitingConfirmationSessionCount: 0,
            scheduledFutureSessionCount: 0,
          ),
        );
        final completed = ready.complete();

        expect(completed.state, ClinicalPlacementState.completed);
        expect(
          () => completed.attachPreceptor('preceptor-3'),
          throwsA(isA<DomainValidationException>()),
        );

        final reopened = completed.reopen();
        expect(reopened.state, ClinicalPlacementState.active);
        expect(reopened.attachedPreceptorIds, completed.attachedPreceptorIds);
        expect(reopened.primaryPreceptorId, completed.primaryPreceptorId);
        expect(reopened.evaluationPlanId, completed.evaluationPlanId);
      },
    );

    test('permits permanent deletion only for an empty mistaken placement', () {
      final placement = _placement();
      final empty = PlacementContentSummary(
        clinicalSessionCount: 0,
        historicalHoursEntryCount: 0,
        evaluationRecordCount: 0,
      );
      final referenced = PlacementContentSummary(
        clinicalSessionCount: 0,
        historicalHoursEntryCount: 1,
        evaluationRecordCount: 0,
      );

      expect(placement.isEligibleForPermanentDeletion(empty), isTrue);
      expect(
        () => placement.requireEligibleForPermanentDeletion(referenced),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });
}

ClinicalPlacement _placement({
  LocalDate? startDate,
  LocalDate? completionDeadline,
  String primaryPreceptorId = 'preceptor-1',
}) => ClinicalPlacement.create(
  id: 'placement-1',
  name: 'Family Medicine',
  targetHours: TargetHours.fromWholeHours(270),
  startDate: startDate ?? LocalDate(2026, 8, 1),
  completionDeadline: completionDeadline ?? LocalDate(2026, 8, 31),
  attachedPreceptorIds: const ['preceptor-1', 'preceptor-2'],
  primaryPreceptorId: primaryPreceptorId,
  evaluationPlanId: 'evaluation-plan-1',
);

ClinicalSession _session({
  required LocalDate date,
  String start = '0800',
  String end = '1200',
  String preceptorId = 'preceptor-1',
}) => ClinicalSession.schedule(
  id: 'session-1',
  clinicalPlacementId: 'placement-1',
  preceptorId: preceptorId,
  plannedInterval: ZonedInterval(
    startDate: date,
    startTime: LocalTime.parseMilitary(start),
    endTime: LocalTime.parseMilitary(end),
    timeZone: TimeZoneId('America/New_York'),
    startOffset: UtcOffset.inMinutes(-240),
    endOffset: UtcOffset.inMinutes(-240),
  ),
  asOfUtc: DateTime.utc(2026, 7, 1),
);

HistoricalHoursEntry _historical({String? preceptorId}) => HistoricalHoursEntry(
  id: 'historical-1',
  clinicalPlacementId: 'placement-1',
  completedMinutes: 375,
  effectiveDate: LocalDate(2026, 8, 1),
  preceptorId: preceptorId,
  note: 'Imported aggregate from prior tracking.',
);
