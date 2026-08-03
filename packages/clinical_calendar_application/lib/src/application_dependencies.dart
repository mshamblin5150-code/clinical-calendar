import 'ports.dart';
import 'repositories.dart';

/// Explicit composition contract for every side effect used by application
/// use cases. The Flutter app is the only production composition root.
final class ApplicationDependencies {
  const ApplicationDependencies({
    required this.repositories,
    required this.clock,
    required this.identifiers,
    required this.synchronization,
    required this.notifications,
    required this.secureStorage,
    required this.files,
  });

  final RepositoryRegistry repositories;
  final Clock clock;
  final IdentifierGenerator identifiers;
  final SynchronizationService synchronization;
  final NotificationService notifications;
  final SecureStorage secureStorage;
  final FileService files;
}
