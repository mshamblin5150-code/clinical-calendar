import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:clinical_calendar_presentation/src/graphite_instrument_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/placement_progress_harness.dart';

void main() {
  testWidgets('Graphite uses live concept-shaped placement instruments', (
    tester,
  ) async {
    final harness = PlacementProgressHarness(
      familyName: 'Acceptance Family Medicine',
    );
    await harness.controller.load();
    await _pump(
      tester,
      GraphiteInstrumentScope(
        child: Row(
          children: [
            SizedBox(
              width: 290,
              child: PlacementDock(
                controller: harness.controller,
                studentId: placementTestStudentId,
              ),
            ),
            SizedBox(
              width: 300,
              child: PlacementProgressRail(
                controller: harness.controller,
                studentId: placementTestStudentId,
              ),
            ),
          ],
        ),
      ),
      size: const Size(620, 820),
    );

    expect(
      find.byKey(const Key('graphite-live-placement-card')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('graphite-live-placement-wheel')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('graphite-live-detailed-wheel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('graphite-live-placement-dependencies')),
      findsNWidgets(2),
    );
    expect(find.byKey(const Key('placement-metric-ledger')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock, wheel, and durable selection stay synchronized', (
    tester,
  ) async {
    final harness = PlacementProgressHarness();
    await harness.controller.load();
    await _pump(
      tester,
      Row(
        children: [
          SizedBox(
            width: 230,
            child: PlacementDock(
              controller: harness.controller,
              studentId: placementTestStudentId,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 270,
            child: PlacementProgressRail(
              controller: harness.controller,
              studentId: placementTestStudentId,
            ),
          ),
        ],
      ),
      size: const Size(560, 620),
    );

    expect(find.text('FAMILY MEDICINE'), findsOneWidget);
    expect(find.byKey(const Key('total-progress-segments')), findsOneWidget);
    expect(
      harness.controller.activePlacement!.placement.name,
      'Family Medicine',
    );

    await tester.tap(find.byKey(const Key('placement-progress-wheel')));
    await tester.pumpAndSettle();

    expect(harness.controller.activePlacement!.placement.name, 'Pediatrics');
    expect(
      harness.repositories.activePlacementSelection
          .find(studentId: placementTestStudentId)!
          .value,
      harness.controller.activePlacementId,
    );
    expect(find.text('PEDIATRICS'), findsOneWidget);
  });

  testWidgets('theme policy places progress wheel beside its metric ledger', (
    tester,
  ) async {
    final harness = PlacementProgressHarness();
    await harness.controller.load();
    await _pump(
      tester,
      InsightRailPresentationPolicy(
        placementProgressLayout: PlacementProgressRailLayout.sideBySide,
        child: SizedBox(
          width: 420,
          child: PlacementProgressRail(
            controller: harness.controller,
            studentId: placementTestStudentId,
          ),
        ),
      ),
      size: const Size(460, 620),
    );

    final progressWheel = tester.getRect(
      find.byKey(const Key('placement-progress-wheel')),
    );
    final metricLedger = tester.getRect(
      find.byKey(const Key('placement-metric-ledger')),
    );
    expect(progressWheel.right, lessThan(metricLedger.left));
    expect(progressWheel.center.dy, closeTo(metricLedger.center.dy, 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('200 percent progress heading keeps its complete name', (
    tester,
  ) async {
    final harness = PlacementProgressHarness(
      familyName: 'Acceptance Family Medicine',
    );
    await harness.controller.load();
    await _pump(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SizedBox(
          width: 300,
          child: PlacementProgressRail(
            controller: harness.controller,
            studentId: placementTestStudentId,
          ),
        ),
      ),
      size: const Size(340, 900),
    );

    final heading = tester.widget<Text>(
      find.text('ACCEPTANCE FAMILY MEDICINE'),
    );
    expect(heading.overflow, isNot(TextOverflow.ellipsis));
    expect(heading.maxLines, isNot(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow placement dock wraps full Clinical Placement names', (
    tester,
  ) async {
    final harness = PlacementProgressHarness();
    await harness.controller.load();
    await _pump(
      tester,
      SizedBox(
        width: 138,
        child: PlacementDock(
          controller: harness.controller,
          studentId: placementTestStudentId,
        ),
      ),
      size: const Size(138, 900),
    );

    final dock = find.byKey(const Key('placement-dock-surface'));
    for (final name in const ['Family Medicine', 'Pediatrics']) {
      final nameFinder = find.descendant(of: dock, matching: find.text(name));
      expect(nameFinder, findsOneWidget);
      final label = tester.widget<Text>(nameFinder);
      expect(
        label.overflow,
        isNot(TextOverflow.ellipsis),
        reason: '$name must continue onto another line instead of truncating.',
      );
      expect(
        label.maxLines,
        isNot(1),
        reason: '$name must have room to continue onto another line.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('management list wraps full Clinical Placement names', (
    tester,
  ) async {
    final harness = PlacementProgressHarness(
      familyName: 'Acceptance Family Medicine',
    );
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: placementTestStudentId,
      ),
      size: const Size(1056, 1691),
    );

    final choice = find.byKey(
      const Key('manage-placement-$placementTestFamilyId'),
    );
    final nameFinder = find.descendant(
      of: choice,
      matching: find.text('Acceptance Family Medicine'),
    );
    expect(nameFinder, findsOneWidget);
    final label = tester.widget<Text>(nameFinder);
    expect(label.overflow, isNot(TextOverflow.ellipsis));
    expect(label.maxLines, isNot(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'progress reconciles Preceptors, Unattributed, pace, and segments',
    (tester) async {
      final harness = PlacementProgressHarness();
      await harness.controller.load();
      await _pump(
        tester,
        SingleChildScrollView(
          child: PlacementMobileSummary(
            controller: harness.controller,
            studentId: placementTestStudentId,
          ),
        ),
        size: const Size(390, 844),
      );

      expect(find.text('270 hr'), findsOneWidget);
      expect(find.text('126 hr'), findsWidgets);
      expect(find.text('108 hr'), findsOneWidget);
      expect(find.text('36 hr'), findsOneWidget);
      expect(find.textContaining('Additional pace required'), findsOneWidget);
      for (var index = 0; index < 8; index++) {
        expect(
          find.byKey(Key('total-progress-segment-$index')),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const Key('toggle-preceptor-breakdown')));
      await tester.pump();
      expect(find.text('Dr. Smith'), findsOneWidget);
      expect(find.text('Dr. Nguyen'), findsOneWidget);
      expect(find.text('Unattributed Historical Hours'), findsOneWidget);
      expect(find.text('PRIMARY'), findsOneWidget);
    },
  );

  testWidgets('management previews blockers then confirms a valid edit', (
    tester,
  ) async {
    final harness = PlacementProgressHarness();
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: placementTestStudentId,
      ),
      size: const Size(1024, 768),
    );

    tester
            .widget<TextField>(
              find.byKey(const Key('placement-deadline-field')),
            )
            .controller!
            .text =
        '08-15-2026';
    await tester.tap(find.byKey(const Key('preview-placement-edit-action')));
    await tester.pumpAndSettle();
    expect(find.text('SAVE BLOCKED'), findsOneWidget);
    expect(find.textContaining('fall outside'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-placement-edit-action')),
          )
          .onPressed,
      isNull,
    );

    tester
            .widget<TextField>(
              find.byKey(const Key('placement-deadline-field')),
            )
            .controller!
            .text =
        '12-31-2026';
    await tester.enterText(
      find.byKey(const Key('placement-target-field')),
      '300',
    );
    await tester.enterText(
      find.byKey(const Key('placement-name-field')),
      'Family Medicine Updated',
    );
    await tester.tap(find.byKey(const Key('preview-placement-edit-action')));
    await tester.pumpAndSettle();
    expect(find.text('IMPACT PREVIEW'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-placement-edit-action')));
    await tester.pumpAndSettle();
    expect(harness.controller.activePlacement!.progress.targetMinutes, 18000);
    expect(
      harness.controller.activePlacement!.placement.name,
      'Family Medicine Updated',
    );
    expect(harness.controller.editPreview, isNull);
  });

  testWidgets(
    'placement deletion previews every category and cancel is inert',
    (tester) async {
      final harness = PlacementProgressHarness();
      await harness.controller.load();
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: placementTestStudentId,
          unsavedSchedulingDraftCount: 2,
        ),
        size: const Size(1024, 900),
      );

      await tester.ensureVisible(
        find.byKey(const Key('move-placement-to-trash-action')),
      );
      await tester.tap(find.byKey(const Key('move-placement-to-trash-action')));
      await tester.pumpAndSettle();
      expect(find.text('Move Family Medicine to Trash?'), findsOneWidget);
      for (final label in [
        'Scheduled Clinical Sessions',
        'Awaiting-confirmation Clinical Sessions',
        'Completed Clinical Sessions',
        'Cancelled Clinical Sessions',
        'Missed Clinical Sessions',
        'Historical Hours Entries',
        'Evaluation Plan requirements',
        'Clinical Session schedule templates',
        'Placement-derived reminders',
        'Attached Preceptor relationships',
        'Unsaved scheduling drafts',
        'Active Clinical Placement selection',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(harness.controller.placements, hasLength(2));
    },
  );

  testWidgets(
    'placement deletion is immediately visible and tappable in management',
    (tester) async {
      final harness = PlacementProgressHarness();
      await harness.controller.load();
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: placementTestStudentId,
        ),
        size: const Size(1024, 900),
      );

      final action = find.byKey(const Key('move-placement-to-trash-action'));
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getRect(action).bottom, lessThanOrEqualTo(900));
    },
  );

  testWidgets(
    'confirming discards disclosed drafts and removes the aggregate',
    (tester) async {
      final harness = PlacementProgressHarness();
      var draftsDiscarded = 0;
      await harness.controller.load();
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: placementTestStudentId,
          unsavedSchedulingDraftCount: 3,
          onDiscardUnsavedSchedulingDrafts: () => draftsDiscarded++,
        ),
        size: const Size(1024, 900),
      );

      await tester.ensureVisible(
        find.byKey(const Key('move-placement-to-trash-action')),
      );
      await tester.tap(find.byKey(const Key('move-placement-to-trash-action')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('confirm-move-placement-to-trash')),
      );
      await tester.pumpAndSettle();
      expect(draftsDiscarded, 1);
      expect(harness.controller.placements, hasLength(1));
      expect(harness.controller.placements.single.placement.name, 'Pediatrics');
    },
  );

  testWidgets('Completed Placement requires its exact name before deletion', (
    tester,
  ) async {
    final harness = PlacementProgressHarness(completed: true);
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: placementTestStudentId,
      ),
      size: const Size(768, 900),
    );
    await tester.drag(
      find.byKey(const Key('placement-management-editor')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('move-placement-to-trash-action')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const Key('confirm-move-placement-to-trash'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('completed-placement-name-confirmation')),
      'Family Medicine',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
  });

  testWidgets('management changes Primary and attaches a new Preceptor', (
    tester,
  ) async {
    final harness = PlacementProgressHarness();
    var openedEvaluations = false;
    await harness.controller.load();
    await _pump(
      tester,
      PlacementManagementSurface(
        controller: harness.controller,
        studentId: placementTestStudentId,
        onOpenEvaluations: () => openedEvaluations = true,
      ),
      size: const Size(1024, 768),
    );

    expect(find.widgetWithText(OutlinedButton, 'Set Primary'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Set Primary'));
    await tester.pumpAndSettle();
    expect(
      harness.controller.activePlacement!.placement.primaryPreceptorId,
      placementTestNguyenId,
    );

    await tester.tap(find.byKey(const Key('add-preceptor-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-preceptor-name')),
      'Dr. Crusher',
    );
    await tester.tap(find.byKey(const Key('confirm-add-preceptor-action')));
    await tester.pumpAndSettle();
    expect(
      harness.controller.activePlacement!.attachedPreceptors,
      hasLength(3),
    );
    expect(
      harness.controller.activePlacement!.attachedPreceptors.map(
        (item) => item.preceptor.name,
      ),
      contains('Dr. Crusher'),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('placement-reviews-evaluations')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('REVIEWS & EVALUATIONS'), findsOneWidget);
    expect(
      find.text('No reviews are configured for this placement.'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('open-placement-evaluations')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-placement-evaluations')));
    expect(openedEvaluations, isTrue);
  });

  testWidgets(
    'Completed Placement locks fields and guarded Reopen restores them',
    (tester) async {
      final harness = PlacementProgressHarness(completed: true);
      await harness.controller.load();
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: placementTestStudentId,
        ),
        size: const Size(768, 900),
      );

      expect(find.textContaining('ORDINARY EDITING LOCKED'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('placement-name-field')))
            .enabled,
        isFalse,
      );
      await tester.ensureVisible(
        find.byKey(const Key('reopen-placement-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reopen-placement-action')));
      await tester.pumpAndSettle();
      expect(
        harness.controller.activePlacement!.placement.state,
        ClinicalPlacementState.active,
      );
      expect(find.byKey(const Key('reopen-placement-action')), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('placement-name-field')))
            .enabled,
        isTrue,
      );
    },
  );

  testWidgets('placement surfaces fit the required responsive matrix', (
    tester,
  ) async {
    final harness = PlacementProgressHarness();
    await harness.controller.load();
    const sizes = [
      Size(320, 568),
      Size(390, 844),
      Size(844, 390),
      Size(768, 1024),
      Size(932, 430),
      Size(1024, 768),
      Size(1440, 900),
    ];
    for (final size in sizes) {
      await _pump(
        tester,
        PlacementManagementSurface(
          controller: harness.controller,
          studentId: placementTestStudentId,
        ),
        size: size,
      );
      expect(tester.takeException(), isNull, reason: 'overflow at $size');
      expect(
        find.byKey(const Key('placement-management-surface')),
        findsOneWidget,
      );
      final progressSurface = size.width >= 960 && size.height >= 600
          ? Row(
              children: [
                SizedBox(
                  width: 216,
                  child: PlacementDock(
                    controller: harness.controller,
                    studentId: placementTestStudentId,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 232,
                  child: PlacementProgressRail(
                    controller: harness.controller,
                    studentId: placementTestStudentId,
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: PlacementMobileSummary(
                controller: harness.controller,
                studentId: placementTestStudentId,
              ),
            );
      await _pump(tester, progressSurface, size: size);
      expect(
        tester.takeException(),
        isNull,
        reason: 'progress overflow at $size',
      );
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildVariantFTheme(),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  await tester.pump();
}
