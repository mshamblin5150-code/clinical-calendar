import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:test/test.dart';

void main() {
  test(
    'complete JSON requires privacy acknowledgement before every effect',
    () async {
      final log = <String>[];
      final workflow = _workflow(log);

      await expectLater(
        workflow.exportCompleteJson(privacyWarningAcknowledged: false),
        throwsA(isA<ExportPrivacyAcknowledgementRequired>()),
      );
      expect(log, isEmpty);
    },
  );

  test(
    'failed reauthentication prevents encoding, picker, and write',
    () async {
      final log = <String>[];
      final workflow = _workflow(log, authenticated: false);

      expect(
        await workflow.exportCompleteJson(privacyWarningAcknowledged: true),
        ExportOutcome.authenticationFailed,
      );
      expect(log, ['reauthenticate']);
    },
  );

  test(
    'JSON ordering is reauth, snapshot, encode, picker, then write',
    () async {
      final log = <String>[];
      final workflow = _workflow(log);

      expect(
        await workflow.exportCompleteJson(privacyWarningAcknowledged: true),
        ExportOutcome.saved,
      );
      expect(log, ['reauthenticate', 'snapshot', 'encode', 'picker', 'write']);
    },
  );

  test('cancelled destination does not write', () async {
    final log = <String>[];
    final workflow = _workflow(log, cancelDestination: true);

    expect(
      await workflow.exportCompleteJson(privacyWarningAcknowledged: true),
      ExportOutcome.cancelled,
    );
    expect(log, ['reauthenticate', 'snapshot', 'encode', 'picker']);
  });
}

ExportWorkflowService _workflow(
  List<String> log, {
  bool authenticated = true,
  bool cancelDestination = false,
}) => ExportWorkflowService(
  data: _Source(log),
  encoder: _Encoder(log),
  reauthentication: _Reauthentication(log, authenticated),
  fileSaver: _Saver(log, cancelDestination),
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
      studentId: 'student',
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
      suggestedFileName: 'export.json',
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
  _Reauthentication(this.log, this.result);

  final List<String> log;
  final bool result;

  @override
  Future<bool> reauthenticate({required String reason}) async {
    log.add('reauthenticate');
    return result;
  }
}

final class _Saver implements NativeByteFileSaver {
  _Saver(this.log, this.cancelled);

  final List<String> log;
  final bool cancelled;

  @override
  Future<NativeFileSaveOutcome> save(NativeFileSaveRequest request) async {
    log.add('picker');
    if (cancelled) return NativeFileSaveOutcome.cancelled;
    expect(request.suggestedFileName, 'export.json');
    expect(request.mimeType, 'application/json');
    expect(request.bytes, [123, 125]);
    log.add('write');
    return NativeFileSaveOutcome.saved;
  }
}
