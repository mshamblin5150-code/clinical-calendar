final class AppEnvironment {
  const AppEnvironment({required this.name, required this.syncBaseUrl});

  factory AppEnvironment.fromCompileTime() => const AppEnvironment(
    name: String.fromEnvironment(
      'CLINICAL_CALENDAR_ENVIRONMENT',
      defaultValue: 'local',
    ),
    syncBaseUrl: String.fromEnvironment('CLINICAL_CALENDAR_SYNC_BASE_URL'),
  );

  final String name;

  /// Public service location only. Privileged keys are never application
  /// configuration; backend tickets must keep them server-side.
  final String syncBaseUrl;
}
