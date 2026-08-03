import 'package:clinical_calendar_application/clinical_calendar_application.dart';

final class DeferredRepositoryRegistry implements RepositoryRegistry {
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }
}
