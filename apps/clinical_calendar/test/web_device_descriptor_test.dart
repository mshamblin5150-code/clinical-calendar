import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar/web_device_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('names Safari on an iPhone without using a hostname', () {
    final descriptor = webDeviceDescriptor(
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 '
      'Mobile/15E148 Safari/604.1',
    );

    expect(descriptor.name, 'Safari on iPhone');
    expect(descriptor.platform, DevicePlatform.web);
  });

  test('names Chrome on Windows from its user agent', () {
    final descriptor = webDeviceDescriptor(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36',
    );

    expect(descriptor.name, 'Chrome on Windows');
    expect(descriptor.platform, DevicePlatform.web);
  });

  test('keeps a useful fallback when the browser reduces its user agent', () {
    final descriptor = webDeviceDescriptor('Mozilla/5.0');

    expect(descriptor.name, 'Browser on Unknown OS');
    expect(descriptor.platform, DevicePlatform.web);
  });
}
