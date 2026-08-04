import 'dart:convert';

// ignore: implementation_imports
import 'package:clinical_calendar_application/src/reminders/notification_reconciler.dart';
import 'package:clinical_calendar_application/clinical_calendar_application.dart'
    show SecureStorage;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-device delivery truth. This is deliberately local: reminder resolution
/// and snooze live in the synchronized reminder record, while permission,
/// preview choice, delivery and dismissal are device-specific.
final class SecureNotificationDeliveryStore
    implements NotificationDeliveryStore {
  SecureNotificationDeliveryStore({
    FlutterSecureStorage? storage,
    String? deviceId,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _applicationStorage = null,
       _key = 'notification-delivery-v1:${deviceId ?? 'local'}';

  SecureNotificationDeliveryStore.applicationStorage({
    required SecureStorage storage,
    String? deviceId,
  }) : _storage = null,
       _applicationStorage = storage,
       _key = 'notification-delivery-v1:${deviceId ?? 'local'}';

  final FlutterSecureStorage? _storage;
  final SecureStorage? _applicationStorage;
  final String _key;

  @override
  Future<Map<String, NotificationDeliveryRecord>> readAll() async {
    final encoded = await _read();
    if (encoded == null) return {};
    final values = jsonDecode(encoded) as Map<String, dynamic>;
    return values.map((key, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(
        key,
        NotificationDeliveryRecord(
          occurrenceKey: key,
          notificationId: map['notificationId'] as int,
          scheduledForUtc: DateTime.parse(
            map['scheduledForUtc'] as String,
          ).toUtc(),
          contentFingerprint: map['contentFingerprint'] as String?,
          delivered: map['delivered'] as bool? ?? false,
          dismissed: map['dismissed'] as bool? ?? false,
        ),
      );
    });
  }

  @override
  Future<void> replaceAll(Map<String, NotificationDeliveryRecord> records) =>
      _write(
        jsonEncode({
          for (final entry in records.entries)
            entry.key: {
              'notificationId': entry.value.notificationId,
              'scheduledForUtc': entry.value.scheduledForUtc
                  .toUtc()
                  .toIso8601String(),
              'contentFingerprint': entry.value.contentFingerprint,
              'delivered': entry.value.delivered,
              'dismissed': entry.value.dismissed,
            },
        }),
      );

  Future<String?> _read() =>
      _applicationStorage?.read(_key) ?? _storage!.read(key: _key);

  Future<void> _write(String value) =>
      _applicationStorage?.write(_key, value) ??
      _storage!.write(key: _key, value: value);
}

final class SecureNotificationDevicePolicyStore
    implements NotificationDevicePolicyStore {
  SecureNotificationDevicePolicyStore({
    FlutterSecureStorage? storage,
    String? deviceId,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _applicationStorage = null,
       _key = 'notification-device-policy-v1:${deviceId ?? 'local'}';

  SecureNotificationDevicePolicyStore.applicationStorage({
    required SecureStorage storage,
    String? deviceId,
  }) : _storage = null,
       _applicationStorage = storage,
       _key = 'notification-device-policy-v1:${deviceId ?? 'local'}';

  final FlutterSecureStorage? _storage;
  final SecureStorage? _applicationStorage;
  final String _key;

  @override
  Future<NotificationDevicePolicy?> read(
    NotificationDeviceClass deviceClass,
  ) async {
    final encoded = await _read();
    if (encoded == null) return null;
    final value = jsonDecode(encoded) as Map<String, dynamic>;
    return NotificationDevicePolicy(
      deviceClass: deviceClass,
      enabled: value['enabled'] as bool?,
      detailedPreview: value['detailedPreview'] as bool? ?? false,
      quietStartsAtHour: value['quietStartsAtHour'] as int? ?? 21,
      quietEndsAtHour: value['quietEndsAtHour'] as int? ?? 7,
    );
  }

  @override
  Future<void> write(NotificationDevicePolicy policy) => _write(
    jsonEncode({
      'enabled': policy.enabled,
      'detailedPreview': policy.detailedPreview,
      'quietStartsAtHour': policy.quietStartsAtHour,
      'quietEndsAtHour': policy.quietEndsAtHour,
    }),
  );

  Future<String?> _read() =>
      _applicationStorage?.read(_key) ?? _storage!.read(key: _key);

  Future<void> _write(String value) =>
      _applicationStorage?.write(_key, value) ??
      _storage!.write(key: _key, value: value);
}
