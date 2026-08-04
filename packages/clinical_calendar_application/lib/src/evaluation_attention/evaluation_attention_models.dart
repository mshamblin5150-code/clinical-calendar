import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../placements/placement_models.dart';

enum AttentionKind {
  confirmation,
  protectedDayPlanning,
  evaluation,
  deadline,
  backup,
  synchronization,
}

enum AttentionUrgency { approaching, due, urgent }

enum AttentionDestination {
  confirmClinicalSession,
  planProtectedDay,
  documentEvaluation,
  manageClinicalPlacement,
  createPortableBackup,
  resolveSynchronization,
}

enum BackupAttentionState { current, missing, overdue, unknown }

enum SynchronizationAttentionState {
  healthy,
  offline,
  failed,
  conflict,
  unknown,
}

final class AttentionExternalState {
  const AttentionExternalState({
    this.backup = BackupAttentionState.unknown,
    this.synchronization = SynchronizationAttentionState.unknown,
  });

  final BackupAttentionState backup;
  final SynchronizationAttentionState synchronization;
}

final class AttentionRepositorySnapshot {
  const AttentionRepositorySnapshot({
    required this.awaitingConfirmationSessions,
    required this.protectedDates,
    required this.weekStartsOn,
    required this.pendingSynchronizationCount,
    required this.oldestPendingSynchronizationAtUtc,
  });

  final List<ClinicalSession> awaitingConfirmationSessions;
  final Set<LocalDate> protectedDates;
  final int weekStartsOn;
  final int pendingSynchronizationCount;
  final DateTime? oldestPendingSynchronizationAtUtc;
}

final class AttentionItem {
  const AttentionItem({
    required this.id,
    required this.kind,
    required this.urgency,
    required this.destination,
    required this.title,
    required this.detail,
    this.clinicalPlacementId,
    this.clinicalSessionId,
    this.evaluationRequirementIdentity,
    this.suggestedDate,
  });

  final String id;
  final AttentionKind kind;
  final AttentionUrgency urgency;
  final AttentionDestination destination;
  final String title;
  final String detail;
  final String? clinicalPlacementId;
  final String? clinicalSessionId;
  final EvaluationRequirementIdentity? evaluationRequirementIdentity;
  final LocalDate? suggestedDate;
}

final class EvaluationAttentionSnapshot {
  const EvaluationAttentionSnapshot({
    required this.placements,
    required this.activePlacementId,
    required this.attentionItems,
  });

  final List<PlacementSnapshot> placements;
  final String? activePlacementId;
  final List<AttentionItem> attentionItems;

  PlacementSnapshot? placement(String id) {
    for (final placement in placements) {
      if (placement.placement.id == id) return placement;
    }
    return null;
  }
}
