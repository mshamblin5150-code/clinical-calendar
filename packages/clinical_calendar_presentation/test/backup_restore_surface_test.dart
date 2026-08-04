import 'package:clinical_calendar_presentation/src/backup/backup_restore_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backup requires matching twelve-character passphrases', (
    tester,
  ) async {
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BackupRestoreSurface(
          onCreateBackup: (_) async => created = true,
          onChooseBackup: (_) async => null,
          onApplyRestore: (_) async {},
        ),
      ),
    );

    final create = find.byKey(const Key('create-encrypted-backup'));
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('backup-passphrase')),
      'long secure passphrase',
    );
    await tester.enterText(
      find.byKey(const Key('backup-passphrase-confirmation')),
      'long secure passphrase',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(create).onPressed, isNotNull);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(created, isTrue);
    expect(find.text('Encrypted backup created.'), findsOneWidget);
  });

  testWidgets(
    'restore has no replace action and requires every conflict choice',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, BackupConflictSelection>? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: BackupRestoreSurface(
            onCreateBackup: (_) async {},
            onChooseBackup: (_) async => const BackupRestorePreviewViewModel(
              additions: 2,
              backupUpdates: 1,
              localRecordsKept: 3,
              conflicts: [
                BackupConflictViewModel(
                  identity: 'preceptors/id=1',
                  title: 'Preceptor record',
                  localSummary: 'Current revision',
                  backupSummary: 'Backup revision',
                ),
              ],
            ),
            onApplyRestore: (choices) async => applied = choices,
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('backup-passphrase')),
        'long secure passphrase',
      );
      await tester.enterText(
        find.byKey(const Key('backup-passphrase-confirmation')),
        'long secure passphrase',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('choose-backup-file')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no-replace-warning')), findsOneWidget);
      expect(find.textContaining('Replace Everything'), findsOneWidget);
      final apply = find.byKey(const Key('apply-restore'));
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);

      await tester.tap(find.text('Use backup'));
      await tester.pump();
      expect(tester.widget<FilledButton>(apply).onPressed, isNotNull);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(applied, {'preceptors/id=1': BackupConflictSelection.useBackup});
      expect(find.text('Restore applied successfully.'), findsOneWidget);
    },
  );

  testWidgets('callback errors disclose no private backup detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BackupRestoreSurface(
          onCreateBackup: (_) async =>
              throw StateError('private schedule data'),
          onChooseBackup: (_) async => null,
          onApplyRestore: (_) async {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('backup-passphrase')),
      'long secure passphrase',
    );
    await tester.enterText(
      find.byKey(const Key('backup-passphrase-confirmation')),
      'long secure passphrase',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create-encrypted-backup')));
    await tester.pumpAndSettle();
    expect(
      find.text('The backup operation could not be completed safely.'),
      findsOneWidget,
    );
    expect(find.textContaining('private schedule data'), findsNothing);
  });
}
