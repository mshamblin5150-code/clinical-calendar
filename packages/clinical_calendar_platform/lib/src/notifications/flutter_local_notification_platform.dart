// ignore: implementation_imports
import 'package:clinical_calendar_application/src/reminders/notification_reconciler.dart';
// ignore: implementation_imports
import 'package:clinical_calendar_application/src/reminders/reminder_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final class TimeZonePackageReminderResolver
    implements ReminderTimeZoneResolver {
  TimeZonePackageReminderResolver() {
    tz_data.initializeTimeZones();
  }

  @override
  DateTime toLocal(DateTime utc, String timeZoneId) =>
      tz.TZDateTime.from(utc.toUtc(), _location(timeZoneId));

  @override
  DateTime fromLocal(DateTime localWallClock, String timeZoneId) {
    final location = _location(timeZoneId);
    return tz.TZDateTime(
      location,
      localWallClock.year,
      localWallClock.month,
      localWallClock.day,
      localWallClock.hour,
      localWallClock.minute,
      localWallClock.second,
      localWallClock.millisecond,
      localWallClock.microsecond,
    );
  }

  Duration offsetAtLocal(DateTime localWallClock, String timeZoneId) {
    final location = _location(timeZoneId);
    return tz.TZDateTime(
      location,
      localWallClock.year,
      localWallClock.month,
      localWallClock.day,
      localWallClock.hour,
      localWallClock.minute,
    ).timeZoneOffset;
  }

  tz.Location _location(String timeZoneId) =>
      timeZoneId == 'UTC' ? tz.UTC : tz.getLocation(timeZoneId);
}

final class FlutterDeviceTimeZoneProvider {
  const FlutterDeviceTimeZoneProvider();

  Future<String> currentTimeZoneId() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
}

final class FlutterLocalNotificationPlatform implements NotificationPlatform {
  FlutterLocalNotificationPlatform({LocalNotificationDriver? driver})
    : _driver =
          driver ??
          PluginLocalNotificationDriver(FlutterLocalNotificationsPlugin()) {
    tz_data.initializeTimeZones();
  }

  final LocalNotificationDriver _driver;

  Future<bool?> initialize({
    void Function(NotificationInteraction interaction)? onInteraction,
  }) => _driver.initialize(onInteraction: onInteraction);

  @override
  Future<NotificationPermission> permission() => _driver.permission();

  @override
  Future<NotificationPermission> requestPermission() =>
      _driver.requestPermission();

  @override
  Future<void> schedule({
    required int id,
    required DateTime atUtc,
    required String title,
    required String body,
    required String payload,
    required List<NotificationAction> actions,
  }) => _driver.schedule(
    id: id,
    atUtc: atUtc,
    title: title,
    body: body,
    payload: payload,
    actions: actions,
  );

  @override
  Future<void> cancel(int id) => _driver.cancel(id);
}

abstract interface class LocalNotificationDriver {
  Future<bool?> initialize({
    void Function(NotificationInteraction interaction)? onInteraction,
  });
  Future<NotificationPermission> permission();
  Future<NotificationPermission> requestPermission();
  Future<void> schedule({
    required int id,
    required DateTime atUtc,
    required String title,
    required String body,
    required String payload,
    required List<NotificationAction> actions,
  });
  Future<void> cancel(int id);
}

final class PluginLocalNotificationDriver implements LocalNotificationDriver {
  PluginLocalNotificationDriver(
    FlutterLocalNotificationsPlugin plugin, {
    TargetPlatform Function()? targetPlatform,
  }) : _gateway = FlutterLocalNotificationsPluginGateway(plugin),
       _targetPlatform = targetPlatform ?? _defaultTargetPlatform;

  PluginLocalNotificationDriver.forTesting(this._gateway, this._targetPlatform);

  final LocalNotificationsPluginGateway _gateway;
  final TargetPlatform Function() _targetPlatform;

  @override
  Future<bool?> initialize({
    void Function(NotificationInteraction interaction)? onInteraction,
  }) => _gateway.initialize(
    settings: InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: _darwinCategories,
      ),
      windows: const WindowsInitializationSettings(
        appName: 'Clinical Calendar',
        appUserModelId: 'ClinicalCalendar.App',
        guid: '5d7cb6c9-2eb0-4e08-a889-15042571df47',
      ),
    ),
    onDidReceiveNotificationResponse: onInteraction == null
        ? null
        : (response) {
            final payload = response.payload;
            if (payload == null) return;
            onInteraction(
              NotificationInteraction.decode(
                payload,
                actionId: response.actionId,
              ),
            );
          },
  );

  @override
  Future<NotificationPermission> permission() async {
    if (_targetPlatform() == TargetPlatform.android) {
      final value = await _gateway.androidNotificationsEnabled();
      return value == null
          ? NotificationPermission.unknown
          : value
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (_targetPlatform() == TargetPlatform.iOS) {
      final value = await _gateway.iosNotificationsEnabled();
      return value == null
          ? NotificationPermission.unknown
          : value
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    if (_targetPlatform() == TargetPlatform.windows) {
      return NotificationPermission.granted;
    }
    return NotificationPermission.unknown;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    bool? granted;
    if (_targetPlatform() == TargetPlatform.android) {
      granted = await _gateway.requestAndroidPermission();
    } else if (_targetPlatform() == TargetPlatform.iOS) {
      granted = await _gateway.requestIosPermission();
    } else if (_targetPlatform() == TargetPlatform.windows) {
      granted = true;
    }
    return granted == null
        ? NotificationPermission.unknown
        : granted
        ? NotificationPermission.granted
        : NotificationPermission.denied;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime atUtc,
    required String title,
    required String body,
    required String payload,
    required List<NotificationAction> actions,
  }) => _gateway.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(atUtc.toUtc(), tz.UTC),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        channelDescription: 'Clinical Calendar reminders',
        actions: [
          for (final action in actions)
            AndroidNotificationAction(
              action.id,
              action.label,
              showsUserInterface: true,
            ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _categoryIdentifier(actions),
      ),
      windows: WindowsNotificationDetails(
        actions: [
          for (final action in actions)
            WindowsAction(content: action.label, arguments: action.id),
        ],
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  @override
  Future<void> cancel(int id) => _gateway.cancel(id);
}

TargetPlatform _defaultTargetPlatform() => defaultTargetPlatform;

abstract interface class LocalNotificationsPluginGateway {
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  });
  Future<bool?> androidNotificationsEnabled();
  Future<bool?> iosNotificationsEnabled();
  Future<bool?> requestAndroidPermission();
  Future<bool?> requestIosPermission();
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required String payload,
  });
  Future<void> cancel(int id);
}

final class FlutterLocalNotificationsPluginGateway
    implements LocalNotificationsPluginGateway {
  const FlutterLocalNotificationsPluginGateway(this.plugin);
  final FlutterLocalNotificationsPlugin plugin;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) => plugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  @override
  Future<bool?> androidNotificationsEnabled() =>
      plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled() ??
      Future<bool?>.value();

  @override
  Future<bool?> iosNotificationsEnabled() async =>
      (await plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.checkPermissions())
          ?.isEnabled;

  @override
  Future<bool?> requestAndroidPermission() =>
      plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      Future<bool?>.value();

  @override
  Future<bool?> requestIosPermission() =>
      plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true) ??
      Future<bool?>.value();

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    required String payload,
  }) => plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    notificationDetails: notificationDetails,
    androidScheduleMode: androidScheduleMode,
    payload: payload,
  );

  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);
}

final _darwinCategories = <DarwinNotificationCategory>[
  DarwinNotificationCategory(
    'clinical.snooze.fifteenMinutes.oneHour',
    actions: [
      DarwinNotificationAction.plain('snooze.fifteenMinutes', '15 minutes'),
      DarwinNotificationAction.plain('snooze.oneHour', '1 hour'),
    ],
  ),
  DarwinNotificationCategory(
    'clinical.snooze.oneHour.tomorrowMorning',
    actions: [
      DarwinNotificationAction.plain('snooze.oneHour', '1 hour'),
      DarwinNotificationAction.plain('snooze.tomorrowMorning', 'Tomorrow'),
    ],
  ),
  DarwinNotificationCategory(
    'clinical.snooze.laterToday.tomorrowMorning.threeDays',
    actions: [
      DarwinNotificationAction.plain('snooze.laterToday', 'Later today'),
      DarwinNotificationAction.plain('snooze.tomorrowMorning', 'Tomorrow'),
      DarwinNotificationAction.plain('snooze.threeDays', '3 days'),
    ],
  ),
  DarwinNotificationCategory(
    'clinical.snooze.oneWeek',
    actions: [DarwinNotificationAction.plain('snooze.oneWeek', '1 week')],
  ),
];

String? _categoryIdentifier(List<NotificationAction> actions) => actions.isEmpty
    ? null
    : 'clinical.${actions.map((value) => value.id).join('.')}';
