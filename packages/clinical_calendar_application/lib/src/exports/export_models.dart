import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../placements/placement_models.dart';
import '../repositories.dart';

enum ExportFormat { placementPdf, placementCsv, completeJson }

final class PlacementExportSnapshot {
  PlacementExportSnapshot({
    required this.generatedAtUtc,
    required this.placement,
    required Iterable<StoredDomainRecord<ClinicalSession>> sessions,
    required Iterable<StoredDomainRecord<HistoricalHoursEntry>> historicalHours,
    required this.evaluationPlan,
  }) : sessions = List.unmodifiable(sessions),
       historicalHours = List.unmodifiable(historicalHours);

  final DateTime generatedAtUtc;
  final PlacementSnapshot placement;
  final List<StoredDomainRecord<ClinicalSession>> sessions;
  final List<StoredDomainRecord<HistoricalHoursEntry>> historicalHours;
  final StoredDomainRecord<EvaluationPlan> evaluationPlan;
}

final class PortableExportSnapshot {
  const PortableExportSnapshot({
    required this.schemaName,
    required this.schemaVersion,
    required this.exportedAtUtc,
    required this.studentId,
    required this.document,
  });

  static const currentSchemaName = 'clinical-calendar-portable-export';
  static const currentSchemaVersion = 1;

  final String schemaName;
  final int schemaVersion;
  final DateTime exportedAtUtc;
  final String studentId;
  final Map<String, Object?> document;
}

abstract interface class ExportSnapshotSource {
  Future<PlacementExportSnapshot> placement(String placementId);

  Future<PortableExportSnapshot> completePortableData();
}

final class ExportArtifact {
  ExportArtifact({
    required this.format,
    required this.suggestedFileName,
    required this.mimeType,
    required Iterable<int> bytes,
  }) : bytes = List.unmodifiable(bytes);

  final ExportFormat format;
  final String suggestedFileName;
  final String mimeType;
  final List<int> bytes;
}

final class NativeFileSaveRequest {
  NativeFileSaveRequest({
    required this.suggestedFileName,
    required this.mimeType,
    required Iterable<int> bytes,
  }) : bytes = List.unmodifiable(bytes);

  final String suggestedFileName;
  final String mimeType;
  final List<int> bytes;
}

abstract interface class ExportEncoder {
  Future<ExportArtifact> encodePlacementPdf(PlacementExportSnapshot snapshot);

  Future<ExportArtifact> encodePlacementCsv(PlacementExportSnapshot snapshot);

  Future<ExportArtifact> encodeCompleteJson(PortableExportSnapshot snapshot);
}

abstract interface class ExportReauthenticationGate {
  Future<bool> reauthenticate({required String reason});
}

enum NativeFileSaveOutcome { saved, cancelled }

/// Opens the platform's native save UI and writes [NativeFileSaveRequest.bytes]
/// to the destination chosen by the user.
///
/// This byte-oriented boundary is also suitable for portable backup artifacts;
/// callers never need filesystem-path access to Android/iOS document URIs.
abstract interface class NativeByteFileSaver {
  Future<NativeFileSaveOutcome> save(NativeFileSaveRequest request);
}

enum ExportOutcome { saved, cancelled, authenticationFailed }

final class ExportPrivacyAcknowledgementRequired implements Exception {
  const ExportPrivacyAcknowledgementRequired();

  @override
  String toString() =>
      'Complete JSON export requires acknowledgement of its privacy warning.';
}
