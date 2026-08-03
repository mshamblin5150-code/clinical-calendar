import 'package:clinical_calendar_application/clinical_calendar_application.dart';

final class DeferredRepositoryRegistry implements RepositoryRegistry {
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async {
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Local write repositories are unavailable until persistence is installed.',
    );
  }

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async {
    throw const RepositoryException(
      RepositoryFailureKind.uninitialized,
      'Local read repositories are unavailable until persistence is installed.',
    );
  }
}
