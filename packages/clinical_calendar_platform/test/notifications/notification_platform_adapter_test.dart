// ignore: implementation_imports
import 'package:clinical_calendar_application/src/reminders/notification_reconciler.dart';
// ignore: implementation_imports
import 'package:clinical_calendar_application/src/reminders/reminder_policy.dart';
import 'package:clinical_calendar_platform/src/notifications/flutter_local_notification_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'adapter preserves permission state and schedule action payload',
    () async {
      final driver = _Driver();
      final platform = FlutterLocalNotificationPlatform(driver: driver);
      NotificationInteraction? interaction;
      await platform.initialize(onInteraction: (value) => interaction = value);
      expect(await platform.permission(), NotificationPermission.unknown);
      expect(
        await platform.requestPermission(),
        NotificationPermission.granted,
      );
      final at = DateTime.utc(2026, 8, 4, 12);
      await platform.schedule(
        id: 42,
        atUtc: at,
        title: 'Confirm session',
        body: 'Privacy-safe body',
        payload: '/session/42',
        actions: const [
          NotificationAction(id: 'snooze.oneHour', label: '1 hour'),
        ],
      );
      expect(driver.scheduled.single, (42, at, '/session/42'));
      driver.onInteraction!(
        const NotificationInteraction(
          occurrenceKey: 'occurrence',
          synchronizationKey: 'base-key',
          route: '/session/42',
          actionId: 'snooze.oneHour',
        ),
      );
      expect(interaction?.snooze, ReminderSnooze.oneHour);
      await platform.cancel(42);
      expect(driver.cancelled, [42]);
    },
  );

  test(
    'adapter exposes denied permission without scheduling implicitly',
    () async {
      final driver = _Driver(permission: NotificationPermission.denied);
      final platform = FlutterLocalNotificationPlatform(driver: driver);
      expect(await platform.permission(), NotificationPermission.denied);
      expect(driver.scheduled, isEmpty);
    },
  );

  test('native permission branches survive iOS restart state', () async {
    final gateway = _Gateway()
      ..androidEnabled = false
      ..iosEnabled = true;
    final android = PluginLocalNotificationDriver.forTesting(
      gateway,
      () => TargetPlatform.android,
    );
    expect(await android.permission(), NotificationPermission.denied);
    gateway.androidRequest = true;
    expect(await android.requestPermission(), NotificationPermission.granted);

    final firstIos = PluginLocalNotificationDriver.forTesting(
      gateway,
      () => TargetPlatform.iOS,
    );
    expect(await firstIos.permission(), NotificationPermission.granted);
    final restartedIos = PluginLocalNotificationDriver.forTesting(
      gateway,
      () => TargetPlatform.iOS,
    );
    expect(await restartedIos.permission(), NotificationPermission.granted);

    final windows = PluginLocalNotificationDriver.forTesting(
      gateway,
      () => TargetPlatform.windows,
    );
    expect(await windows.permission(), NotificationPermission.granted);
  });

  test(
    'native schedule exposes actions and decodes action callbacks',
    () async {
      final gateway = _Gateway();
      final driver = PluginLocalNotificationDriver.forTesting(
        gateway,
        () => TargetPlatform.android,
      );
      NotificationInteraction? interaction;
      await driver.initialize(onInteraction: (value) => interaction = value);
      final payload = const NotificationInteraction(
        occurrenceKey: 'occurrence',
        synchronizationKey: 'base-key',
        route: '/session',
      ).encode();
      await driver.schedule(
        id: 1,
        atUtc: DateTime.utc(2026, 8, 4, 12),
        title: 'Title',
        body: 'Body',
        payload: payload,
        actions: const [
          NotificationAction(id: 'snooze.oneHour', label: '1 hour'),
        ],
      );
      expect(gateway.details!.android!.actions!.single.id, 'snooze.oneHour');
      expect(
        gateway.details!.windows!.actions.single.arguments,
        'snooze.oneHour',
      );
      gateway.callback!(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: 'snooze.oneHour',
          payload: payload,
        ),
      );
      expect(interaction?.route, '/session');
      expect(interaction?.snooze, ReminderSnooze.oneHour);
    },
  );
}

final class _Driver implements LocalNotificationDriver {
  _Driver({NotificationPermission permission = NotificationPermission.unknown})
    : current = permission;

  NotificationPermission current;
  final scheduled = <(int, DateTime, String)>[];
  final cancelled = <int>[];
  void Function(NotificationInteraction interaction)? onInteraction;

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<bool?> initialize({
    void Function(NotificationInteraction interaction)? onInteraction,
  }) async {
    this.onInteraction = onInteraction;
    return true;
  }

  @override
  Future<NotificationPermission> permission() async => current;

  @override
  Future<NotificationPermission> requestPermission() async =>
      current = NotificationPermission.granted;

  @override
  Future<void> schedule({
    required int id,
    required DateTime atUtc,
    required String title,
    required String body,
    required String payload,
    required List<NotificationAction> actions,
  }) async => scheduled.add((id, atUtc, payload));
}

final class _Gateway implements LocalNotificationsPluginGateway {
  bool? androidEnabled;
  bool? iosEnabled;
  bool? androidRequest;
  bool? iosRequest;
  DidReceiveNotificationResponseCallback? callback;
  NotificationDetails? details;

  @override
  Future<bool?> androidNotificationsEnabled() async => androidEnabled;
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    callback = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<bool?> iosNotificationsEnabled() async => iosEnabled;
  @override
  Future<bool?> requestAndroidPermission() async => androidRequest;
  @override
  Future<bool?> requestIosPermission() async => iosRequest;
  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required String payload,
  }) async {
    details = notificationDetails;
  }
}
