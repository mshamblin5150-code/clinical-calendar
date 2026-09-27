import 'package:clinical_calendar_application/clinical_calendar_identity.dart';

String currentBrowserUserAgent() =>
    throw UnsupportedError('Browser identity is available only on web.');

SecureStorage createWebIdentityStorage() => throw UnsupportedError(
  'Browser identity storage is available only on web.',
);
