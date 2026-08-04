import 'dart:convert';

import 'reminder_policy.dart';

enum NotificationPermission { unknown, denied, granted }

enum NotificationDeviceClass { phone, tablet, desktop }

final class NotificationDevicePolicy {
  const NotificationDevicePolicy({
    required this.deviceClass,
    this.enabled,
    this.detailedPreview = false,
    this.quietStartsAtHour = 21,
    this.quietEndsAtHour = 7,
  }) : assert(quietStartsAtHour >= 0 && quietStartsAtHour <= 23),
       assert(quietEndsAtHour >= 0 && quietEndsAtHour <= 23);
  final NotificationDeviceClass deviceClass;
  final bool? enabled;
  final bool detailedPreview;
  final int quietStartsAtHour;
  final int quietEndsAtHour;
  bool get effectiveEnabled =>
      enabled ?? deviceClass == NotificationDeviceClass.phone;
}

final class NotificationDeliveryRecord {
  const NotificationDeliveryRecord({
    required this.occurrenceKey,
    required this.notificationId,
    required this.scheduledForUtc,
    this.contentFingerprint,
    this.delivered = false,
    this.dismissed = false,
  });
  final String occurrenceKey;
  final int notificationId;
  final DateTime scheduledForUtc;
  final String? contentFingerprint;
  final bool delivered;
  final bool dismissed;
}

final class NotificationAction {
  const NotificationAction({required this.id, required this.label});
  final String id;
  final String label;
}

final class NotificationInteraction {
  const NotificationInteraction({
    required this.occurrenceKey,
    required this.synchronizationKey,
    required this.route,
    this.actionId,
  });
  final String occurrenceKey;
  final String synchronizationKey;
  final String route;
  final String? actionId;

  ReminderSnooze? get snooze {
    final value = actionId;
    if (value == null || !value.startsWith('snooze.')) return null;
    final name = value.substring('snooze.'.length);
    for (final choice in ReminderSnooze.values) {
      if (choice.name == name) return choice;
    }
    return null;
  }

  String encode() => jsonEncode({
    'occurrenceKey': occurrenceKey,
    'synchronizationKey': synchronizationKey,
    'route': route,
  });

  static NotificationInteraction decode(String payload, {String? actionId}) {
    final value = jsonDecode(payload);
    if (value is! Map<String, dynamic> ||
        value['occurrenceKey'] is! String ||
        value['synchronizationKey'] is! String ||
        value['route'] is! String) {
      throw const FormatException('Invalid notification interaction payload.');
    }
    return NotificationInteraction(
      occurrenceKey: value['occurrenceKey'] as String,
      synchronizationKey: value['synchronizationKey'] as String,
      route: value['route'] as String,
      actionId: actionId,
    );
  }
}

abstract interface class NotificationPlatform {
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

abstract interface class NotificationDeliveryStore {
  Future<Map<String, NotificationDeliveryRecord>> readAll();
  Future<void> replaceAll(Map<String, NotificationDeliveryRecord> records);
}

abstract interface class NotificationDevicePolicyStore {
  Future<NotificationDevicePolicy?> read(NotificationDeviceClass deviceClass);
  Future<void> write(NotificationDevicePolicy policy);
}

final class NotificationReconciler {
  const NotificationReconciler(this.platform, this.store);
  final NotificationPlatform platform;
  final NotificationDeliveryStore store;

  Future<void> markDelivered(String occurrenceKey) =>
      _mark(occurrenceKey, delivered: true);

  Future<void> markDismissed(String occurrenceKey) =>
      _mark(occurrenceKey, dismissed: true);

  Future<void> _mark(
    String occurrenceKey, {
    bool delivered = false,
    bool dismissed = false,
  }) async {
    final existing = await store.readAll();
    final record = existing[occurrenceKey];
    if (record == null) return;
    existing[occurrenceKey] = NotificationDeliveryRecord(
      occurrenceKey: record.occurrenceKey,
      notificationId: record.notificationId,
      scheduledForUtc: record.scheduledForUtc,
      contentFingerprint: record.contentFingerprint,
      delivered: record.delivered || delivered,
      dismissed: record.dismissed || dismissed,
    );
    await store.replaceAll(existing);
  }

  Future<void> reconcile({
    required Iterable<ReminderOccurrence> desired,
    required NotificationDevicePolicy device,
    bool requestPermission = false,
  }) async {
    final existing = await store.readAll();
    var permission = await platform.permission();
    if (device.effectiveEnabled &&
        requestPermission &&
        permission != NotificationPermission.granted) {
      permission = await platform.requestPermission();
    }
    if (!device.effectiveEnabled ||
        permission != NotificationPermission.granted) {
      for (final record in existing.values) {
        await platform.cancel(record.notificationId);
      }
      await store.replaceAll({});
      return;
    }
    final wanted = {for (final item in desired) item.occurrenceKey: item};
    for (final entry in existing.entries) {
      if (!wanted.containsKey(entry.key)) {
        await platform.cancel(entry.value.notificationId);
      }
    }
    final next = <String, NotificationDeliveryRecord>{};
    for (final entry in wanted.entries) {
      final old = existing[entry.key];
      final item = entry.value;
      final body = device.detailedPreview
          ? item.detailedBody ?? item.genericBody
          : item.genericBody;
      final interaction = NotificationInteraction(
        occurrenceKey: item.occurrenceKey,
        synchronizationKey: item.synchronizationKey,
        route: item.route,
      );
      final payload = interaction.encode();
      final actions = _actions(item.snoozeOptions);
      final fingerprint = _fingerprint(item.title, body, payload, actions);
      if (old != null) {
        // Delivered or dismissed occurrences remain historical truth and are not
        // re-created merely because the process restarted.
        if (old.delivered ||
            old.dismissed ||
            (old.scheduledForUtc == entry.value.scheduledForUtc &&
                old.contentFingerprint == fingerprint)) {
          next[entry.key] = old;
          continue;
        }
        // A travel/time-zone or quiet-hours preference change can move a still
        // pending occurrence without changing its logical identity.
        await platform.cancel(old.notificationId);
      }
      final id = _stableId(item.occurrenceKey);
      await platform.schedule(
        id: id,
        atUtc: item.scheduledForUtc,
        title: item.title,
        body: body,
        payload: payload,
        actions: actions,
      );
      next[entry.key] = NotificationDeliveryRecord(
        occurrenceKey: entry.key,
        notificationId: id,
        scheduledForUtc: item.scheduledForUtc,
        contentFingerprint: fingerprint,
      );
    }
    await store.replaceAll(next);
  }

  List<NotificationAction> _actions(List<ReminderSnooze> choices) => [
    for (final choice in choices)
      NotificationAction(id: 'snooze.${choice.name}', label: _label(choice)),
  ];

  String _label(ReminderSnooze choice) => switch (choice) {
    ReminderSnooze.fifteenMinutes => '15 minutes',
    ReminderSnooze.oneHour => '1 hour',
    ReminderSnooze.laterToday => 'Later today',
    ReminderSnooze.tomorrowMorning => 'Tomorrow',
    ReminderSnooze.threeDays => '3 days',
    ReminderSnooze.oneWeek => '1 week',
  };

  String _fingerprint(
    String title,
    String body,
    String payload,
    List<NotificationAction> actions,
  ) {
    final source =
        '$title\u0000$body\u0000$payload\u0000'
        '${actions.map((value) => '${value.id}:${value.label}').join('|')}';
    return _stableId(source).toRadixString(16);
  }

  int _stableId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
