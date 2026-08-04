import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../repositories.dart';

enum CommitmentLifecycleKind { workShift, clinicalSession, protectedDay }

sealed class CommitmentLifecycleSnapshot {
  const CommitmentLifecycleSnapshot({
    required this.kind,
    required this.id,
    required this.revision,
  });

  final CommitmentLifecycleKind kind;
  final String id;
  final int revision;
}

final class WorkShiftLifecycleSnapshot extends CommitmentLifecycleSnapshot {
  WorkShiftLifecycleSnapshot({required this.record})
    : super(
        kind: CommitmentLifecycleKind.workShift,
        id: record.value.id,
        revision: record.revision,
      );

  final StoredDomainRecord<WorkShift> record;
}

final class ClinicalSessionLifecycleSnapshot
    extends CommitmentLifecycleSnapshot {
  ClinicalSessionLifecycleSnapshot({
    required this.record,
    required this.clinicalPlacementName,
    required Iterable<Preceptor> attachedPreceptors,
  }) : attachedPreceptors = List.unmodifiable(attachedPreceptors),
       super(
         kind: CommitmentLifecycleKind.clinicalSession,
         id: record.value.id,
         revision: record.revision,
       );

  final StoredDomainRecord<ClinicalSession> record;
  final String clinicalPlacementName;
  final List<Preceptor> attachedPreceptors;

  Preceptor get selectedPreceptor => attachedPreceptors.singleWhere(
    (preceptor) => preceptor.id == record.value.preceptorId,
  );
}

final class ProtectedDayLifecycleSnapshot extends CommitmentLifecycleSnapshot {
  ProtectedDayLifecycleSnapshot({required this.record})
    : super(
        kind: CommitmentLifecycleKind.protectedDay,
        id: record.value.id,
        revision: record.revision,
      );

  final StoredDomainRecord<ProtectedDay> record;
}
