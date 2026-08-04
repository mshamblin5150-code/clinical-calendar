import 'dart:collection';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/foundation.dart';

final class PlacementProgressController extends ChangeNotifier {
  PlacementProgressController({
    required this.service,
    required String studentId,
  }) : studentId = _requiredText(studentId, 'Student id');

  final PlacementApplicationService service;
  final String studentId;
  final ClinicalPlacementProgressEngine _progressEngine =
      const ClinicalPlacementProgressEngine();

  List<PlacementSnapshot> _placements = const [];
  String? _activePlacementId;
  TotalProgress _totalProgress = const ClinicalPlacementProgressEngine()
      .deriveTotal(const []);
  PlacementEditImpactPreview? _editPreview;
  bool _isBusy = false;
  Object? _error;

  UnmodifiableListView<PlacementSnapshot> get placements =>
      UnmodifiableListView(_placements);
  String? get activePlacementId => _activePlacementId;
  PlacementSnapshot? get activePlacement {
    final id = _activePlacementId;
    if (id == null) return null;
    for (final placement in _placements) {
      if (placement.placement.id == id) return placement;
    }
    return null;
  }

  TotalProgress get totalProgress => _totalProgress;
  PlacementEditImpactPreview? get editPreview => _editPreview;
  bool get isBusy => _isBusy;
  Object? get error => _error;

  Future<void> load() => _perform(() async {
    final listed = await service.placements();
    final active = await service.activePlacement();
    _placements = listed;
    _activePlacementId = active?.placement.id;
    if (_activePlacementId == null && listed.isNotEmpty) {
      await service.selectActivePlacement(listed.first.placement.id);
      _activePlacementId = listed.first.placement.id;
    }
    _totalProgress = _progressEngine.deriveTotal(
      listed.map((snapshot) => snapshot.progress),
    );
    _editPreview = null;
  });

  Future<void> selectPlacement(String clinicalPlacementId) =>
      _perform(() async {
        await service.selectActivePlacement(clinicalPlacementId);
        _activePlacementId = clinicalPlacementId;
        _editPreview = null;
      });

  Future<void> cyclePlacement() async {
    if (_placements.isEmpty) return;
    final current = _placements.indexWhere(
      (item) => item.placement.id == _activePlacementId,
    );
    final next = _placements[(current + 1) % _placements.length];
    await selectPlacement(next.placement.id);
  }

  Future<void> previewEdit(EditPlacementRequest request) async {
    final active = activePlacement;
    if (active == null) return;
    await _perform(() async {
      _editPreview = await service.previewEdit(
        clinicalPlacementId: active.placement.id,
        request: request,
      );
    });
  }

  Future<void> confirmEdit() async {
    final preview = _editPreview;
    if (preview == null) return;
    await _mutateAndReload(() => service.confirmEdit(preview));
  }

  Future<void> createPlacementWithPrimary({
    required String placementName,
    required TargetHours targetHours,
    required LocalDate startDate,
    required LocalDate completionDeadline,
    required String primaryPreceptorName,
    EvaluationPlanConfiguration? evaluationPlanConfiguration,
  }) async {
    await _mutateAndReload(() async {
      final preceptor = await service.createPreceptor(
        name: primaryPreceptorName,
      );
      return service.createPlacement(
        CreatePlacementRequest(
          name: placementName,
          targetHours: targetHours,
          startDate: startDate,
          completionDeadline: completionDeadline,
          primaryPreceptorId: preceptor.id,
          evaluationPlanConfiguration:
              evaluationPlanConfiguration ?? EvaluationPlanConfiguration(),
        ),
      );
    });
  }

  Future<void> createAndAttachPreceptor(String name) async {
    final active = activePlacement;
    if (active == null) return;
    await _mutateAndReload(() async {
      final preceptor = await service.createPreceptor(name: name);
      return service.attachPreceptor(
        clinicalPlacementId: active.placement.id,
        preceptorId: preceptor.id,
        expectedPlacementRevision: active.placementRevision,
      );
    });
  }

  Future<void> editPreceptor(
    PlacementPreceptorSnapshot attached,
    String name,
  ) => _perform(() async {
    await service.editPreceptor(
      preceptorId: attached.preceptor.id,
      expectedRevision: attached.revision,
      name: name,
      organizationOrSite: attached.preceptor.organizationOrSite,
      phone: attached.preceptor.phone,
      email: attached.preceptor.email,
      schedulingNotes: attached.preceptor.schedulingNotes,
    );
    final listed = await service.placements();
    _placements = listed;
    _totalProgress = _progressEngine.deriveTotal(
      listed.map((snapshot) => snapshot.progress),
    );
  });

  Future<void> makePrimary(String preceptorId) async {
    final active = activePlacement;
    if (active == null) return;
    await _mutateAndReload(
      () => service.makePrimaryPreceptor(
        clinicalPlacementId: active.placement.id,
        preceptorId: preceptorId,
        expectedPlacementRevision: active.placementRevision,
        expectedEvaluationPlanRevision: active.evaluationPlanRevision,
      ),
    );
  }

  Future<void> detachPreceptor(String preceptorId) async {
    final active = activePlacement;
    if (active == null) return;
    await _mutateAndReload(
      () => service.detachPreceptor(
        clinicalPlacementId: active.placement.id,
        preceptorId: preceptorId,
        expectedPlacementRevision: active.placementRevision,
      ),
    );
  }

  Future<void> completePlacement() async {
    final active = activePlacement;
    if (active == null) return;
    await _mutateAndReload(
      () => service.completePlacement(
        clinicalPlacementId: active.placement.id,
        expectedPlacementRevision: active.placementRevision,
      ),
    );
  }

  Future<void> reopenPlacement() async {
    final active = activePlacement;
    if (active == null) return;
    await _mutateAndReload(
      () => service.reopenPlacement(
        clinicalPlacementId: active.placement.id,
        expectedPlacementRevision: active.placementRevision,
      ),
    );
  }

  Future<void> _mutateAndReload(
    Future<PlacementSnapshot> Function() mutation,
  ) => _perform(() async {
    final changed = await mutation();
    _activePlacementId = changed.placement.id;
    final listed = await service.placements();
    _placements = listed;
    _totalProgress = _progressEngine.deriveTotal(
      listed.map((snapshot) => snapshot.progress),
    );
    _editPreview = null;
  });

  Future<void> _perform(Future<void> Function() operation) async {
    if (_isBusy) return;
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
    } on Object catch (error) {
      _error = error;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

String _requiredText(String value, String label) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError('$label must not be empty.');
  return normalized;
}
