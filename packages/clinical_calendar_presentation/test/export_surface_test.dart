import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('complete JSON warning precedes every export side effect', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(_app(log));

    await tester.tap(find.byKey(const Key('export-complete-json')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('complete-json-privacy-warning')), findsOne);
    expect(log, isEmpty);

    await tester.tap(find.byKey(const Key('cancel-json-export')));
    await tester.pumpAndSettle();
    expect(log, isEmpty);

    await tester.tap(find.byKey(const Key('export-complete-json')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acknowledge-json-privacy')));
    await tester.pumpAndSettle();

    expect(log, ['reauthenticate', 'snapshot', 'encode', 'picker', 'write']);
    expect(find.text('Export saved.'), findsOne);
  });

  testWidgets('failed JSON reauthentication never opens destination picker', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(_app(log, authenticated: false));

    await tester.tap(find.byKey(const Key('export-complete-json')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acknowledge-json-privacy')));
    await tester.pumpAndSettle();

    expect(log, ['reauthenticate']);
    expect(
      find.text('Reauthentication was not completed. Nothing was exported.'),
      findsOne,
    );
  });

  testWidgets('all export actions fit a compact phone width', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(<String>[]));

    expect(find.byKey(const Key('export-placement-pdf')), findsOne);
    expect(find.byKey(const Key('export-placement-csv')), findsOne);
    expect(find.byKey(const Key('export-complete-json')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('placement exports disable without an active placement', (
    tester,
  ) async {
    await tester.pumpWidget(_app(<String>[], clinicalPlacementId: null));

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('export-placement-pdf')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('export-placement-csv')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('export-complete-json')))
          .onPressed,
      isNotNull,
    );
  });
}

Widget _app(
  List<String> log, {
  bool authenticated = true,
  String? clinicalPlacementId = 'placement-1',
}) => MaterialApp(
  theme: buildVariantFTheme(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: ExportSurface(
        workflow: ExportWorkflowService(
          data: _Source(log),
          encoder: _Encoder(log),
          reauthentication: _Reauthentication(log, authenticated),
          fileSaver: _Saver(log),
        ),
        clinicalPlacementId: clinicalPlacementId,
      ),
    ),
  ),
);

final class _Source implements ExportSnapshotSource {
  _Source(this.log);

  final List<String> log;

  @override
  Future<PortableExportSnapshot> completePortableData() async {
    log.add('snapshot');
    return PortableExportSnapshot(
      schemaName: PortableExportSnapshot.currentSchemaName,
      schemaVersion: PortableExportSnapshot.currentSchemaVersion,
      exportedAtUtc: DateTime.utc(2026, 8, 3),
      studentId: 'student-1',
      document: const {'schema_version': 1},
    );
  }

  @override
  Future<PlacementExportSnapshot> placement(String placementId) =>
      throw UnimplementedError();
}

final class _Encoder implements ExportEncoder {
  _Encoder(this.log);

  final List<String> log;

  @override
  Future<ExportArtifact> encodeCompleteJson(
    PortableExportSnapshot snapshot,
  ) async {
    log.add('encode');
    return ExportArtifact(
      format: ExportFormat.completeJson,
      suggestedFileName: 'clinical-calendar-export.json',
      mimeType: 'application/json',
      bytes: const [123, 125],
    );
  }

  @override
  Future<ExportArtifact> encodePlacementCsv(PlacementExportSnapshot snapshot) =>
      throw UnimplementedError();

  @override
  Future<ExportArtifact> encodePlacementPdf(PlacementExportSnapshot snapshot) =>
      throw UnimplementedError();
}

final class _Reauthentication implements ExportReauthenticationGate {
  _Reauthentication(this.log, this.authenticated);

  final List<String> log;
  final bool authenticated;

  @override
  Future<bool> reauthenticate({required String reason}) async {
    log.add('reauthenticate');
    return authenticated;
  }
}

final class _Saver implements NativeByteFileSaver {
  _Saver(this.log);

  final List<String> log;

  @override
  Future<NativeFileSaveOutcome> save(NativeFileSaveRequest request) async {
    log.add('picker');
    log.add('write');
    return NativeFileSaveOutcome.saved;
  }
}
