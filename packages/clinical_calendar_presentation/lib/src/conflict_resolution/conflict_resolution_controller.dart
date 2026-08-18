import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/foundation.dart';

final class ConflictResolutionController extends ChangeNotifier {
  ConflictResolutionController(this._service);

  final ConflictResolutionApplicationService _service;

  ConflictResolutionSnapshot? _snapshot;
  bool _busy = false;
  String? _error;
  Completer<void>? _operationIdle;
  Completer<void>? _loadCycle;
  bool _reloadRequested = false;

  ConflictResolutionSnapshot? get snapshot => _snapshot;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> load() {
    final activeCycle = _loadCycle;
    if (activeCycle != null) {
      _reloadRequested = true;
      return activeCycle.future;
    }
    final cycle = Completer<void>();
    _loadCycle = cycle;
    unawaited(_loadUntilCurrent(cycle));
    return cycle.future;
  }

  Future<void> _loadUntilCurrent(Completer<void> cycle) async {
    try {
      do {
        _reloadRequested = false;
        final operationIdle = _operationIdle;
        if (operationIdle != null) await operationIdle.future;
        await _run(() async {
          _snapshot = null;
          _snapshot = await _service.load();
        });
      } while (_reloadRequested);
      cycle.complete();
    } on Object catch (error, stackTrace) {
      cycle.completeError(error, stackTrace);
    } finally {
      if (identical(_loadCycle, cycle)) _loadCycle = null;
    }
  }

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
    final operationIdle = Completer<void>();
    _operationIdle = operationIdle;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _busy = false;
      _operationIdle = null;
      operationIdle.complete();
      notifyListeners();
    }
  }
}
