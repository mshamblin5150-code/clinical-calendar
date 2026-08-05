import 'package:clinical_calendar_application/src/reminders/notification_reconciler.dart';
import 'package:clinical_calendar_platform/src/notifications/secure_notification_delivery_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device delivery state survives store reconstruction', () async {
    final storage = _SecureStorage();
    final first = SecureNotificationDeliveryStore(
      storage: storage,
      deviceId: 'device-a',
    );
    final at = DateTime.utc(2026, 8, 4, 12);
    await first.replaceAll({
      'occurrence': NotificationDeliveryRecord(
        occurrenceKey: 'occurrence',
        notificationId: 42,
        scheduledForUtc: at,
        delivered: true,
        dismissed: true,
      ),
    });
    final restarted = SecureNotificationDeliveryStore(
      storage: storage,
      deviceId: 'device-a',
    );
    final restored = (await restarted.readAll()).values.single;
    expect(restored.notificationId, 42);
    expect(restored.scheduledForUtc, at);
    expect(restored.delivered, isTrue);
    expect(restored.dismissed, isTrue);
  });

  test('delivery state is isolated per device', () async {
    final storage = _SecureStorage();
    await SecureNotificationDeliveryStore(
      storage: storage,
      deviceId: 'device-a',
    ).replaceAll({
      'a': NotificationDeliveryRecord(
        occurrenceKey: 'a',
        notificationId: 1,
        scheduledForUtc: DateTime.utc(2026),
      ),
    });
    expect(
      await SecureNotificationDeliveryStore(
        storage: storage,
        deviceId: 'device-b',
      ).readAll(),
      isEmpty,
    );
  });

  test(
    'per-device delivery, preview, and quiet-hour settings persist',
    () async {
      final storage = _SecureStorage();
      final store = SecureNotificationDevicePolicyStore(
        storage: storage,
        deviceId: 'device-a',
      );
      await store.write(
        const NotificationDevicePolicy(
          deviceClass: NotificationDeviceClass.tablet,
          enabled: true,
          detailedPreview: true,
          quietStartsAtHour: 22,
          quietStartsAtMinute: 15,
          quietEndsAtHour: 8,
          quietEndsAtMinute: 45,
        ),
      );
      final restored = await store.read(NotificationDeviceClass.tablet);
      expect(restored?.effectiveEnabled, isTrue);
      expect(restored?.detailedPreview, isTrue);
      expect(restored?.quietStartsAtHour, 22);
      expect(restored?.quietStartsAtMinute, 15);
      expect(restored?.quietEndsAtHour, 8);
      expect(restored?.quietEndsAtMinute, 45);
    },
  );
}

final class _SecureStorage implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String;
    if (invocation.memberName == #read) return Future.value(values[key]);
    if (invocation.memberName == #write) {
      final value = invocation.namedArguments[#value] as String?;
      if (value == null) {
        values.remove(key);
      } else {
        values[key] = value;
      }
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}
