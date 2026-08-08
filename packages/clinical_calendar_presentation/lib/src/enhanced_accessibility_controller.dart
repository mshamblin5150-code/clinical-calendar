import 'package:flutter/foundation.dart';

typedef PersistEnhancedAccessibility = Future<void> Function(bool enabled);

/// Owns the independent Enhanced accessibility preference at presentation
/// boundaries while persistence remains authoritative.
final class EnhancedAccessibilityController extends ChangeNotifier {
  EnhancedAccessibilityController({required bool initialValue})
    : _enabled = initialValue,
      _authoritativeValue = initialValue;

  bool _enabled;
  bool _authoritativeValue;
  bool _isSaving = false;
  String? _errorMessage;

  bool get enabled => _enabled;
  bool get authoritativeValue => _authoritativeValue;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> setEnabled(
    bool value, {
    required PersistEnhancedAccessibility persist,
  }) async {
    if (_isSaving || value == _enabled) return;
    _enabled = value;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await persist(value);
      _authoritativeValue = value;
    } on Object {
      _enabled = _authoritativeValue;
      _errorMessage = 'Enhanced accessibility could not be saved. Try again.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void acceptAuthoritative(bool value) {
    final changed =
        _authoritativeValue != value ||
        (!_isSaving && _enabled != value) ||
        _errorMessage != null;
    _authoritativeValue = value;
    if (!_isSaving) _enabled = value;
    _errorMessage = null;
    if (changed) notifyListeners();
  }
}
