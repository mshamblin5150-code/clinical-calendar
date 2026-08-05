import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/src/scheduling/batch_scheduling_controller.dart';
import 'package:clinical_calendar_presentation/src/scheduling/staged_batch_scheduling_tray.dart';
import 'package:clinical_calendar_presentation/src/variant_f_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reset intents preserve dates and set correct defaults', () {
    final controller = _controller();
    addTearDown(controller.dispose);

    expect(controller.type, BatchCommitmentType.clinicalSession);
    expect(controller.clinicalPlacementId, 'placement-active');
    expect(controller.preceptorId, 'preceptor-primary');

    controller.reset(BatchSchedulingReset.planningIncomplete);
    expect(controller.type, BatchCommitmentType.protectedDay);
    expect(controller.selectedDates, hasLength(2));
    expect(controller.stage, BatchSchedulingStage.typeAndTime);

    controller.reset(
      BatchSchedulingReset.addSchedule,
      activeClinicalPlacementId: 'placement-active',
    );
    expect(controller.type, BatchCommitmentType.clinicalSession);
    expect(controller.selectedDates, hasLength(2));
    expect(controller.preceptorId, 'preceptor-primary');
  });

  test('12-hour entry keeps time and AM/PM separate', () {
    final controller = _controller(useTwelveHourTime: true);
    addTearDown(controller.dispose);

    controller.setStartInput('1130');
    controller.setStartPeriod('PM');
    controller.setEndInput('1:15');
    controller.setEndPeriod('AM');

    expect(controller.startTime, LocalTime(23, 30));
    expect(controller.endTime, LocalTime(1, 15));
    expect(controller.durationMinutes, 105);
  });

  test('calculated duration reports differing exact offset durations', () {
    final controller = _controller(
      selectedDates: [
        _date(3),
        ZonedScheduleDate(
          date: LocalDate(2026, 11, 1),
          timeZone: TimeZoneId('America/New_York'),
          startOffset: UtcOffset.inMinutes(-240),
          endOffset: UtcOffset.inMinutes(-300),
        ),
      ],
    );
    addTearDown(controller.dispose);

    expect(controller.durationVaries, isTrue);
    expect(controller.durationMinutes, isNull);
  });

  testWidgets('template, flexible time, Back, and overrides persist', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const Key('batch-template')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Late clinic').last);
    await tester.pumpAndSettle();
    expect(controller.startTime, LocalTime(13, 15));
    expect(controller.endTime, LocalTime(21, 45));
    expect(controller.durationMinutes, 510);
    expect(find.text('8 hr 30 min'), findsOne);

    controller.chooseStartTime(LocalTime(14, 15));
    controller.chooseEndTime(LocalTime(22, 0));
    await tester.pump();
    expect(controller.durationMinutes, 465);

    await tester.tap(find.byKey(const Key('batch-next')));
    await tester.pumpAndSettle();
    expect(controller.stage, BatchSchedulingStage.assignment);

    await tester.tap(find.byKey(const Key('batch-preceptor-placement-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zoë Müller').last);
    await tester.pumpAndSettle();
    expect(controller.preceptorId, 'preceptor-other');

    await tester.tap(find.byKey(const Key('batch-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-back')));
    await tester.pumpAndSettle();
    expect(controller.preceptorId, 'preceptor-other');
  });

  testWidgets('every date and conflict is reviewed before one apply call', (
    tester,
  ) async {
    final operations = _Operations(conflictingDates: {LocalDate(2026, 8, 4)});
    final controller = _controller(operations: operations);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const Key('batch-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('batch-review-2026-08-03')), findsOne);
    expect(find.byKey(const Key('batch-review-2026-08-04')), findsOne);
    expect(find.textContaining('Schedule Conflict'), findsOne);
    final blocked = tester.widget<FilledButton>(
      find.byKey(const Key('batch-apply')),
    );
    expect(blocked.onPressed, isNull);

    await tester.tap(find.byKey(const Key('remove-batch-date-2026-08-04')));
    await tester.pumpAndSettle();
    expect(controller.selectedDates, hasLength(1));
    expect(find.textContaining('Schedule Conflict'), findsNothing);

    await tester.tap(find.byKey(const Key('batch-apply')));
    await tester.pumpAndSettle();
    expect(operations.applyCalls, 1);
    expect(operations.lastAppliedDraft?.dates, hasLength(1));
    expect(find.text('1 schedule item saved.'), findsOne);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('batch-apply')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('failed apply keeps the complete unsaved batch', (tester) async {
    final operations = _Operations(failApply: true);
    final controller = _controller(operations: operations);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(controller));

    await tester.tap(find.byKey(const Key('batch-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-apply')));
    await tester.pumpAndSettle();

    expect(controller.stage, BatchSchedulingStage.review);
    expect(controller.selectedDates, hasLength(2));
    expect(controller.clinicalPlacementId, 'placement-active');
    expect(find.textContaining('staged entries are unchanged'), findsOne);
  });

  testWidgets(
    'compact tray stays in flow without overflow and uses 44px actions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller));

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('batch-next'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(find.byKey(const Key('batch-scheduling-tray')), findsOne);
    },
  );
}

BatchSchedulingController _controller({
  _Operations? operations,
  bool useTwelveHourTime = false,
  Iterable<ZonedScheduleDate>? selectedDates,
}) => BatchSchedulingController(
  operations: operations ?? _Operations(),
  studentId: 'student-1',
  placements: [
    BatchClinicalPlacementOption(
      id: 'placement-active',
      name: 'Family Medicine',
      primaryPreceptorId: 'preceptor-primary',
      preceptors: const [
        BatchPreceptorOption(id: 'preceptor-primary', name: 'José Álvarez'),
        BatchPreceptorOption(id: 'preceptor-other', name: 'Zoë Müller'),
      ],
    ),
  ],
  templates: [
    ScheduleTemplate(
      id: 'template-late',
      name: 'Late clinic',
      type: ScheduleTemplateType.clinicalSession,
      startTime: LocalTime(13, 15),
      endTime: LocalTime(21, 45),
      clinicalPlacementId: 'placement-active',
      preceptorId: 'preceptor-other',
    ),
  ],
  selectedDates: selectedDates ?? [_date(3), _date(4)],
  useTwelveHourTime: useTwelveHourTime,
  activeClinicalPlacementId: 'placement-active',
);

Widget _app(BatchSchedulingController controller) => MaterialApp(
  theme: buildVariantFTheme(),
  home: Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: StagedBatchSchedulingTray(controller: controller),
      ),
    ),
  ),
);

ZonedScheduleDate _date(int day) => ZonedScheduleDate(
  date: LocalDate(2026, 8, day),
  timeZone: TimeZoneId('America/New_York'),
  startOffset: UtcOffset.inMinutes(-240),
  endOffset: UtcOffset.inMinutes(-240),
);

final class _Operations implements BatchSchedulingOperations {
  _Operations({Set<LocalDate>? conflictingDates, this.failApply = false})
    : conflictingDates = conflictingDates ?? {};

  final Set<LocalDate> conflictingDates;
  final bool failApply;
  int applyCalls = 0;
  BatchSchedulingDraft? lastAppliedDraft;

  @override
  Future<BatchSchedulingReview> review(BatchSchedulingDraft draft) async =>
      BatchSchedulingReview(
        items: [
          for (var index = 0; index < draft.dates.length; index++)
            BatchSchedulingReviewItem(
              date: draft.dates[index].date,
              durationMinutes: draft.type == BatchCommitmentType.protectedDay
                  ? null
                  : draft.intervals[index].elapsedMinutes,
              conflicts: conflictingDates.contains(draft.dates[index].date)
                  ? [
                      SchedulingError(
                        violation: ScheduleInvariantViolation.commitmentOverlap,
                        proposedId: 'preview-$index',
                        proposedDate: draft.dates[index].date,
                        conflictingId: 'existing-1',
                        conflictDate: draft.dates[index].date,
                      ),
                    ]
                  : const [],
            ),
        ],
      );

  @override
  Future<BatchSchedulingApplyResult> apply(BatchSchedulingDraft draft) async {
    applyCalls++;
    lastAppliedDraft = draft;
    if (failApply) throw StateError('simulated persistence failure');
    return BatchSchedulingApplyResult(
      persistedCount: draft.dates.length,
      conflicts: const [],
    );
  }
}
