import 'package:flutter/foundation.dart';

final class AppEnvironment {
  const AppEnvironment({
    required this.name,
    this.supabaseUrl = '',
    this.supabasePublishableKey = '',
  });

  factory AppEnvironment.fromCompileTime() => const AppEnvironment(
    name: String.fromEnvironment(
      'CLINICAL_CALENDAR_ENVIRONMENT',
      defaultValue: 'local',
    ),
    supabaseUrl: String.fromEnvironment('CLINICAL_CALENDAR_SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment(
      'CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY',
    ),
  );

  final String name;

  /// Public Supabase project location. Service-role credentials are forbidden.
  final String supabaseUrl;

  /// Public client key only. It is not an authorization secret.
  final String supabasePublishableKey;

  Uri? get synchronizationProjectUri {
    final uri = Uri.tryParse(supabaseUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme == 'https') return uri;
    if (uri.scheme != 'http' || kReleaseMode || !_allowsLocalHttp(uri)) {
      return null;
    }
    return uri;
  }

  bool _allowsLocalHttp(Uri uri) {
    final environment = name.trim().toLowerCase();
    return (environment == 'local' || environment == 'test') &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '::1');
  }

  bool get hasSynchronizationConfiguration =>
      synchronizationProjectUri != null &&
      supabasePublishableKey.trim().isNotEmpty;
}
