import 'export_models.dart';

final class ExportWorkflowService {
  const ExportWorkflowService({
    required this.data,
    required this.encoder,
    required this.reauthentication,
    required this.fileSaver,
  });

  final ExportSnapshotSource data;
  final ExportEncoder encoder;
  final ExportReauthenticationGate reauthentication;
  final NativeByteFileSaver fileSaver;

  Future<ExportOutcome> exportPlacementPdf(String placementId) async => _save(
    await encoder.encodePlacementPdf(await data.placement(placementId)),
  );

  Future<ExportOutcome> exportPlacementCsv(String placementId) async => _save(
    await encoder.encodePlacementCsv(await data.placement(placementId)),
  );

  Future<ExportOutcome> exportCompleteJson({
    required bool privacyWarningAcknowledged,
  }) async {
    if (!privacyWarningAcknowledged) {
      throw const ExportPrivacyAcknowledgementRequired();
    }
    final authenticated = await reauthentication.reauthenticate(
      reason: 'Export all Clinical Calendar data',
    );
    if (!authenticated) return ExportOutcome.authenticationFailed;
    final artifact = await encoder.encodeCompleteJson(
      await data.completePortableData(),
    );
    return _save(artifact);
  }

  Future<ExportOutcome> _save(ExportArtifact artifact) async {
    final outcome = await fileSaver.save(
      NativeFileSaveRequest(
        suggestedFileName: artifact.suggestedFileName,
        mimeType: artifact.mimeType,
        bytes: artifact.bytes,
      ),
    );
    return switch (outcome) {
      NativeFileSaveOutcome.saved => ExportOutcome.saved,
      NativeFileSaveOutcome.cancelled => ExportOutcome.cancelled,
    };
  }
}
