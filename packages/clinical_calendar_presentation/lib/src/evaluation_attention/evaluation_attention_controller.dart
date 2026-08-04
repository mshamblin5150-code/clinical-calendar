import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/foundation.dart';

final class EvaluationAttentionController extends ChangeNotifier {
  EvaluationAttentionController({
    required this.service,
    this.externalState = const AttentionExternalState(),
  });

  final EvaluationAttentionApplicationService service;
  AttentionExternalState externalState;

  EvaluationAttentionSnapshot? _snapshot;
  String? _selectedPlacementId;
  PlacementEditImpactPreview? _configurationPreview;
  bool _isBusy = false;
  Object? _error;

  EvaluationAttentionSnapshot? get snapshot => _snapshot;
  String? get selectedPlacementId => _selectedPlacementId;
  PlacementEditImpactPreview? get configurationPreview => _configurationPreview;
  bool get isBusy => _isBusy;
  Object? get error => _error;

  PlacementSnapshot? get selectedPlacement {
    final value = _snapshot;
    final selected = _selectedPlacementId;
    return value == null || selected == null ? null : value.placement(selected);
  }

  List<AttentionItem> get attentionItems =>
      _snapshot?.attentionItems ?? const [];

  Future<void> load() => _perform(_reload);

  void selectPlacement(String id) {
    if (_snapshot?.placement(id) == null) return;
    _selectedPlacementId = id;
    _configurationPreview = null;
    notifyListeners();
  }

  Future<void> previewConfiguration(
    EvaluationPlanConfiguration configuration,
  ) => _perform(() async {
    final placement = selectedPlacement;
    if (placement == null) return;
    _configurationPreview = await service.previewConfiguration(
      placement: placement,
      configuration: configuration,
    );
  });

  Future<void> confirmConfiguration() => _perform(() async {
    final preview = _configurationPreview;
    if (preview == null) return;
    await service.confirmConfiguration(preview);
    _configurationPreview = null;
    await _reload();
  });

  Future<void> documentRequirement({
    required EvaluationRequirementIdentity identity,
    required EvaluationDocumentation documentation,
  }) => _perform(() async {
    final placement = selectedPlacement;
    if (placement == null) return;
    await service.documentRequirement(
      placement: placement,
      identity: identity,
      documentation: documentation,
    );
    await _reload();
  });

  Future<void> updateExternalState(AttentionExternalState value) =>
      _perform(() async {
        externalState = value;
        await _reload();
      });

  Future<void> _reload() async {
    final loaded = await service.load(externalState: externalState);
    _snapshot = loaded;
    final selected = _selectedPlacementId;
    if (selected != null && loaded.placement(selected) != null) return;
    _selectedPlacementId =
        loaded.activePlacementId ??
        (loaded.placements.isEmpty
            ? null
            : loaded.placements.first.placement.id);
  }

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
