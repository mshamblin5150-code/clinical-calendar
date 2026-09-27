import 'package:clinical_calendar_application/clinical_calendar_identity.dart';

DeviceDescriptor webDeviceDescriptor(String userAgent) => DeviceDescriptor(
  name: '${_browserName(userAgent)} on ${_operatingSystemName(userAgent)}',
  platform: DevicePlatform.web,
);

String _browserName(String userAgent) {
  if (userAgent.contains('EdgiOS/') ||
      userAgent.contains('EdgA/') ||
      userAgent.contains('Edg/')) {
    return 'Edge';
  }
  if (userAgent.contains('OPR/') || userAgent.contains('Opera/')) {
    return 'Opera';
  }
  if (userAgent.contains('FxiOS/') || userAgent.contains('Firefox/')) {
    return 'Firefox';
  }
  if (userAgent.contains('CriOS/') || userAgent.contains('Chrome/')) {
    return 'Chrome';
  }
  if (userAgent.contains('Safari/') && userAgent.contains('Version/')) {
    return 'Safari';
  }
  return 'Browser';
}

String _operatingSystemName(String userAgent) {
  if (userAgent.contains('iPhone')) return 'iPhone';
  if (userAgent.contains('iPad')) return 'iPad';
  if (userAgent.contains('Android')) return 'Android';
  if (userAgent.contains('Windows')) return 'Windows';
  if (userAgent.contains('CrOS')) return 'ChromeOS';
  if (userAgent.contains('Macintosh') || userAgent.contains('Mac OS X')) {
    return 'macOS';
  }
  if (userAgent.contains('Linux')) return 'Linux';
  return 'Unknown OS';
}
