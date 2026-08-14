import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/src/recovery/trash_recovery_surface.dart';
import 'package:clinical_calendar_presentation/src/variant_f_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 8, 4, 12);

void main() {
  testWidgets('Trash restore and permanent delete are deliberate', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Work Shift'), findsOneWidget);
    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();
    expect(harness.restored, 1);
    expect(find.textContaining('queued for synchronization'), findsOneWidget);

    harness.resetTrash();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete permanently'));
    await tester.pumpAndSettle();
    expect(find.text('This cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.deleted, 0);
  });

  testWidgets('snapshot preview does not merge until confirmed', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('snapshot-preview-summary')), findsOneWidget);
    expect(harness.merged, 0);
    await tester.tap(find.byKey(const Key('confirm-snapshot-merge')));
    await tester.pumpAndSettle();
    expect(harness.merged, 1);
  });

  testWidgets('Clinical Placement Trash is shown as one named aggregate', (
    tester,
  ) async {
    final entry = TrashEntry(
      id: '00000000-0000-4000-8000-000000000010',
      entityType: 'clinical_placement_aggregate',
      entityId: '00000000-0000-4000-8000-000000000011',
      deletedAtUtc: _now,
      purgeAfterUtc: _now.add(const Duration(days: 30)),
      displayName: 'Family Medicine',
      dependentRecordCount: 7,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVariantFTheme(),
        home: TrashRecoverySurface(
          loadTrash: () async => [entry],
          restore: (_) async {},
          permanentlyDelete: (_) async {},
          clearTrash: () async {},
          loadSnapshots: () async => [],
          previewSnapshot: (_) async => throw UnimplementedError(),
          restoreSnapshot: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Family Medicine'), findsOneWidget);
    expect(find.textContaining('7 dependent records'), findsOneWidget);
    expect(find.text('Clinical Placement'), findsNothing);
  });

  for (final size in [const Size(320, 568), const Size(1024, 768)]) {
    testWidgets('responsive recovery surface fits ${size.width}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_Harness().app());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Trash & recovery'), findsOneWidget);
    });
  }
}

final class _Harness {
  var restored = 0;
  var deleted = 0;
  var merged = 0;
  var _trash = <TrashEntry>[_entry()];

  void resetTrash() => _trash = [_entry()];

  Widget app() => MaterialApp(
    theme: buildVariantFTheme(),
    home: TrashRecoverySurface(
      loadTrash: () async => List.of(_trash),
      restore: (_) async {
        restored++;
        _trash = [];
      },
      permanentlyDelete: (_) async {
        deleted++;
        _trash = [];
      },
      clearTrash: () async => _trash = [],
      loadSnapshots: () async => [_snapshot()],
      previewSnapshot: (_) async => OperationalRecoveryPreview(
        snapshot: _snapshot(),
        items: const [
          RecoveryMergeItem(
            identity: 'preceptors/id=one',
            disposition: RecoveryMergeDisposition.add,
          ),
        ],
      ),
      restoreSnapshot: (_, _) async => merged++,
    ),
  );
}

TrashEntry _entry() => TrashEntry(
  id: '00000000-0000-4000-8000-000000000001',
  entityType: 'work_shift',
  entityId: '00000000-0000-4000-8000-000000000002',
  deletedAtUtc: _now,
  purgeAfterUtc: _now.add(const Duration(days: 30)),
);

OperationalSnapshotSummary _snapshot() => OperationalSnapshotSummary(
  id: '00000000-0000-4000-8000-000000000003',
  snapshotDate: '2026-08-04',
  createdAtUtc: _now,
  expiresAtUtc: _now.add(const Duration(days: 30)),
);
