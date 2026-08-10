import 'dart:io';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/proof_fonts.dart';

void main() {
  setUpAll(() {
    if (!Platform.isWindows) {
      goldenFileComparator = createProofGoldenComparator(goldenFileComparator);
    }
  });

  testWidgets(
    'Graphite Calendar is pinned at tablet landscape and 200 percent',
    (tester) async {
      const viewport = Size(1480, 924);
      const bundle = GraphiteThemeBundle();
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: bundle.standardPresentation.createThemeData(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: ClinicalCalendarSemanticMarkScope(
                marks: bundle.marks,
                child: RepaintBoundary(
                  key: const Key('issue-156-tablet-golden'),
                  child: bundle.shellRenderer.build(
                    environmentName: '200% TEXT TEST',
                    onOpenMenu: _ignoreAction,
                    onOpenDestination: _ignoreDestination,
                    onOpenAttention: _ignoreAction,
                    onAddSchedule: _ignoreAction,
                    slots: ResponsiveShellSlots(
                      centralContent: CalendarPeriodView(
                        dataSource: const _EmptyCalendarDataSource(),
                        studentId: '200-percent-calendar-student',
                        today: LocalDate(2026, 8, 10),
                        initialAnchor: LocalDate(2026, 8, 10),
                      ),
                      planningRegion: const SizedBox.shrink(),
                      placementDock: const SizedBox.shrink(),
                      insightRail: const SizedBox.shrink(),
                      mobilePlacementSummary: const SizedBox.shrink(),
                      mobileAttention: const SizedBox.shrink(),
                      profileAvatar: const Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('issue-156-tablet-golden')),
        matchesGoldenFile(
          'goldens/issue_156/graphite_calendar_200_percent_1480x924.png',
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

void _ignoreAction() {}

void _ignoreDestination(ClinicalCalendarDestination _) {}

final class _EmptyCalendarDataSource implements CalendarDataSource {
  const _EmptyCalendarDataSource();

  @override
  Future<CalendarSnapshot> load({
    required String studentId,
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async => CalendarSnapshot([]);
}
