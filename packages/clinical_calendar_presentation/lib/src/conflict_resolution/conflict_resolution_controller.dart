import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/foundation.dart';

final class ConflictResolutionController extends ChangeNotifier {
  ConflictResolutionController(this._service);

  final ConflictResolutionApplicationService _service;

  ConflictResolutionSnapshot? _snapshot;
  bool _busy = false;
  String? _error;

  ConflictResolutionSnapshot? get snapshot => _snapshot;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load() => _run(() async {
    _snapshot = null;
    _snapshot = await _service.load();
  });

  Future<void> resolve({
    required ConflictResolutionItem conflict,
    required SynchronizationConflictResolutionChoice choice,
    Map<String, Object?>? correctedValues,
  }) => _run(() async {
    await _service.resolve(
      conflictId: conflict.record.id,
      choice: choice,
      correctedValues: correctedValues,
    );
    _snapshot = await _service.load();
  });

  Future<void> resolveCrossRecord({
    required ConflictResolutionItem conflict,
    required CrossRecordResolutionAction action,
    Map<String, Object?>? movedValues,
  }) => _run(() async {
    await _service.resolveCrossRecord(
      conflict: conflict,
      action: action,
      movedValues: movedValues,
    );
    _snapshot = await _service.load();
  });

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
