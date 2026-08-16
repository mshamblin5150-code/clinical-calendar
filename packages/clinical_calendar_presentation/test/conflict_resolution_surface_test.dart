import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/src/conflict_resolution/conflict_resolution_controller.dart';
import 'package:clinical_calendar_presentation/src/conflict_resolution/conflict_resolution_surface.dart';
import 'package:clinical_calendar_presentation/src/variant_f_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
const _entityId = '00000000-0000-4000-8000-000000000002';
const _conflictId = '00000000-0000-4000-8000-000000000003';
const _affectedId = '00000000-0000-4000-8000-000000000004';
final _now = DateTime.utc(2026, 8, 3, 12);

void main() {
  testWidgets('shows both originals and resolves through an explicit choice', (
    tester,
  ) async {
    final harness = _Harness(_sameRecordConflict());
    await harness.controller.load();
    await _pump(tester, harness.controller, const Size(390, 844));

    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Other device'), findsOneWidget);
    expect(find.textContaining('This Device'), findsOneWidget);
    expect(find.textContaining('Other Device'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-local-conflict-version')));
    await tester.pumpAndSettle();

    expect(find.text('No Sync Conflicts need attention.'), findsOneWidget);
    expect(
      harness.repository.lastChoice,
      SynchronizationConflictResolutionChoice.localVersion,
    );
    expect(harness.repository.originalLocal, contains('This Device'));
    expect(harness.repository.originalRemote, contains('Other Device'));
  });

  testWidgets('compose correction is explicit and dialog lifecycle is safe', (
    tester,
  ) async {
    final harness = _Harness(_sameRecordConflict());
    await harness.controller.load();
    await _pump(tester, harness.controller, const Size(768, 900));

    await tester.tap(
      find.byKey(const Key('compose-corrected-conflict-version')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'This Device'),
      'Merged',
    );
    await tester.tap(find.byKey(const Key('save-corrected-conflict-version')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      harness.repository.lastChoice,
      SynchronizationConflictResolutionChoice.correctedVersion,
    );
    expect(harness.repository.correctedValueJson, contains('Merged'));
  });

  testWidgets('malformed conflict version cannot be selected', (tester) async {
    final original = _sameRecordConflict();
    final harness = _Harness(
      SynchronizationConflictRecord(
        id: original.id,
        studentId: original.studentId,
        entityType: original.entityType,
        entityId: original.entityId,
        localRevision: original.localRevision,
        remoteRevision: original.remoteRevision,
        localSnapshotJson: 'legacy payload',
        remoteSnapshotJson: original.remoteSnapshotJson,
        rejectionCode: original.rejectionCode,
        rejectionJson: original.rejectionJson,
        detectedAtUtc: original.detectedAtUtc,
        affectedRecords: original.affectedRecords,
      ),
    );
    await harness.controller.load();
    await _pump(tester, harness.controller, const Size(390, 844));

    final local = tester.widget<FilledButton>(
      find.byKey(const Key('choose-local-conflict-version')),
    );
    final remote = tester.widget<FilledButton>(
      find.byKey(const Key('choose-remote-conflict-version')),
    );

    expect(local.onPressed, isNull);
    expect(remote.onPressed, isNotNull);
    expect(find.text('Complete version not received yet.'), findsOneWidget);
  });

  testWidgets('failed reload removes stale conflict actions', (tester) async {
    final harness = _Harness(_sameRecordConflict());
    await harness.controller.load();
    harness.repository.failLoads = true;

    await harness.controller.load();
    await _pump(tester, harness.controller, const Size(390, 844));

    expect(
      find.text('Synchronization conflicts could not be loaded.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry-conflict-load-action')), findsOneWidget);
    expect(find.byKey(Key('sync-conflict-$_conflictId')), findsNothing);
    expect(
      find.byKey(const Key('choose-local-conflict-version')),
      findsNothing,
    );
  });

  testWidgets('malformed cross-record conflict disables resolution actions', (
    tester,
  ) async {
    final original = _protectedDayConflict();
    final harness = _Harness(
      SynchronizationConflictRecord(
        id: original.id,
        studentId: original.studentId,
        entityType: original.entityType,
        entityId: original.entityId,
        localRevision: original.localRevision,
        remoteRevision: original.remoteRevision,
        localSnapshotJson: 'legacy payload',
        remoteSnapshotJson: original.remoteSnapshotJson,
        rejectionCode: original.rejectionCode,
        rejectionJson: original.rejectionJson,
        detectedAtUtc: original.detectedAtUtc,
        affectedRecords: original.affectedRecords,
        planningWeekStartDate: original.planningWeekStartDate,
      ),
    );
    await harness.controller.load();
    await _pump(tester, harness.controller, const Size(390, 844));

    final move = tester.widget<OutlinedButton>(
      find.byKey(const Key('move-conflicting-record-action')),
    );
    final delete = tester.widget<OutlinedButton>(
      find.byKey(const Key('delete-conflicting-record-action')),
    );

    expect(move.onPressed, isNull);
    expect(delete.onPressed, isNull);
    expect(
      find.text(
        'A complete version is required before resolving this conflict.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'cross-record conflict shows every record and truthful Planning Incomplete',
    (tester) async {
      final harness = _Harness(_protectedDayConflict());
      await harness.controller.load();
      SynchronizationConflictEntityReference? opened;
      CrossRecordResolutionAction? action;

      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(932, 430),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildVariantFTheme(),
            home: Scaffold(
              body: SynchronizationConflictResolutionSurface(
                controller: harness.controller,
                onOpenRecordAction: (record, selectedAction) {
                  opened = record;
                  action = selectedAction;
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(const Key('synchronization-conflict-resolution-surface')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'overflow at $size');
      }
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      expect(find.text('Planning Incomplete'), findsOneWidget);
      expect(
        find.byKey(Key('affected-conflict-record-$_entityId')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('affected-conflict-record-$_affectedId')),
        findsOneWidget,
      );
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Delete if eligible'), findsOneWidget);
      await tester.tap(find.byKey(Key('affected-conflict-record-$_entityId')));
      expect(opened!.entityId, _entityId);
      expect(action, CrossRecordResolutionAction.move);
      await tester.ensureVisible(
        find.byKey(const Key('delete-conflicting-record-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('delete-conflicting-record-action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete conflicting record?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('confirm-delete-conflicting-record')),
      );
      await tester.pumpAndSettle();
      expect(
        harness.repository.lastChoice,
        SynchronizationConflictResolutionChoice.deleteVersion,
      );
      expect(find.text('No Sync Conflicts need attention.'), findsOneWidget);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  ConflictResolutionController controller,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildVariantFTheme(),
      home: Scaffold(
        body: SynchronizationConflictResolutionSurface(controller: controller),
      ),
    ),
  );
  await tester.pump();
}

final class _Harness {
  _Harness(SynchronizationConflictRecord conflict)
    : repository = _ConflictRepository(conflict) {
    controller = ConflictResolutionController(
      ConflictResolutionApplicationService(
        repositories: _Registry(_Repositories(repository)),
        clock: _Clock(),
        identifiers: _Identifiers(),
        studentId: _studentId,
      ),
    );
  }

  final _ConflictRepository repository;
  late final ConflictResolutionController controller;
}

SynchronizationConflictRecord _sameRecordConflict() =>
    SynchronizationConflictRecord(
      id: _conflictId,
      studentId: _studentId,
      entityType: 'preceptor',
      entityId: _entityId,
      localRevision: 2,
      remoteRevision: 2,
      localSnapshotJson: _envelope('preceptor', {'name': 'This Device'}),
      remoteSnapshotJson: _envelope('preceptor', {'name': 'Other Device'}),
      rejectionCode: 'stale_revision',
      rejectionJson: '{"code":"stale_revision"}',
      detectedAtUtc: _now,
      affectedRecords: [
        SynchronizationConflictEntityReference(
          entityType: 'preceptor',
          entityId: _entityId,
        ),
      ],
    );

SynchronizationConflictRecord _protectedDayConflict() =>
    SynchronizationConflictRecord(
      id: _conflictId,
      studentId: _studentId,
      entityType: 'protected_day',
      entityId: _entityId,
      localRevision: 1,
      remoteRevision: 0,
      localSnapshotJson: _envelope('protected_day', {
        'local_date': '2026-08-05',
        'week_start_date': '2026-08-03',
      }, revision: 1),
      remoteSnapshotJson: _envelope('protected_day', {
        'local_date': '2026-08-05',
        'week_start_date': '2026-08-03',
      }, revision: 0),
      rejectionCode: 'protected_day_violation',
      rejectionJson: '{"code":"protected_day_violation"}',
      detectedAtUtc: _now,
      planningWeekStartDate: LocalDate(2026, 8, 3),
      affectedRecords: [
        SynchronizationConflictEntityReference(
          entityType: 'protected_day',
          entityId: _entityId,
        ),
        SynchronizationConflictEntityReference(
          entityType: 'work_shift',
          entityId: _affectedId,
        ),
      ],
    );

String _envelope(
  String entityType,
  Map<String, Object?> value, {
  int revision = 2,
}) => jsonEncode({
  'schema_version': 1,
  'entity_type': entityType,
  'entity_id': _entityId,
  'student_id': _studentId,
  'revision': revision,
  'created_at_utc': _now.toIso8601String(),
  'updated_at_utc': _now.toIso8601String(),
  'deleted_at_utc': null,
  'value': value,
});

final class _Registry implements RepositoryRegistry {
  _Registry(this.repositories);
  final _Repositories repositories;

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

final class _Repositories implements SynchronizationLocalWriteRepositories {
  _Repositories(this.synchronization);

  @override
  final SynchronizationLocalRepository synchronization;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ConflictRepository implements SynchronizationLocalRepository {
  _ConflictRepository(this.record)
    : originalLocal = record.localSnapshotJson,
      originalRemote = record.remoteSnapshotJson;

  SynchronizationConflictRecord record;
  final String originalLocal;
  final String originalRemote;
  SynchronizationConflictResolutionChoice? lastChoice;
  String? correctedValueJson;
  bool failLoads = false;

  @override
  SynchronizationConflictRecord? findConflict({
    required String studentId,
    required String conflictId,
  }) => record.id == conflictId ? record : null;

  @override
  List<SynchronizationConflictRecord> listConflicts({
    required String studentId,
    bool includeResolved = false,
  }) {
    if (failLoads) {
      throw const RepositoryException(
        RepositoryFailureKind.corruptData,
        'A synchronization conflict snapshot is invalid.',
      );
    }
    return record.isResolved && !includeResolved ? [] : [record];
  }

  @override
  SynchronizationConflictResolutionReceipt resolveConflict({
    required String studentId,
    required String conflictId,
    required SynchronizationConflictResolutionChoice choice,
    String? correctedValueJson,
    required MutationToken mutation,
  }) {
    lastChoice = choice;
    this.correctedValueJson = correctedValueJson;
    record = SynchronizationConflictRecord(
      id: record.id,
      studentId: record.studentId,
      entityType: record.entityType,
      entityId: record.entityId,
      localRevision: record.localRevision,
      remoteRevision: record.remoteRevision,
      localSnapshotJson: record.localSnapshotJson,
      remoteSnapshotJson: record.remoteSnapshotJson,
      rejectionCode: record.rejectionCode,
      rejectionJson: record.rejectionJson,
      detectedAtUtc: record.detectedAtUtc,
      affectedRecords: record.affectedRecords,
      planningWeekStartDate: record.planningWeekStartDate,
      resolvedAtUtc: mutation.occurredAtUtc,
      resolutionJson: jsonEncode({'choice': choice.name}),
    );
    return SynchronizationConflictResolutionReceipt(
      conflict: record,
      operation: OutboxOperation(
        mutation: mutation,
        studentId: studentId,
        entityType: record.entityType,
        entityId: record.entityId,
        type: choice == SynchronizationConflictResolutionChoice.deleteVersion
            ? OutboxOperationType.delete
            : OutboxOperationType.resolveConflict,
        baseRevision: record.remoteRevision,
        payloadJson: correctedValueJson ?? record.localSnapshotJson,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => _now;
}

final class _Identifiers implements IdentifierGenerator {
  int next = 20;

  @override
  String nextIdentifier() =>
      '00000000-0000-4000-8000-${(next++).toString().padLeft(12, '0')}';
}
