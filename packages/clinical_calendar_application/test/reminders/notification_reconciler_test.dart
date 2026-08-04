import 'package:clinical_calendar_application/src/reminders/notification_reconciler.dart';
import 'package:clinical_calendar_application/src/reminders/reminder_policy.dart';
import 'package:test/test.dart';

void main() {
  late _Platform platform;
  late _Store store;
  late NotificationReconciler reconciler;
  setUp(() {
    platform = _Platform();
    store = _Store();
    reconciler = NotificationReconciler(platform, store);
  });

  test(
    'phone requests permission and defaults to generic lock preview',
    () async {
      await reconciler.reconcile(
        desired: [_occurrence()],
        device: const NotificationDevicePolicy(
          deviceClass: NotificationDeviceClass.phone,
        ),
        requestPermission: true,
      );
      expect(platform.requested, isTrue);
      expect(
        platform.scheduled.single.body,
        'Open Clinical Calendar to review this reminder.',
      );
      expect(platform.scheduled.single.actions.map((value) => value.id), [
        'snooze.oneHour',
        'snooze.tomorrowMorning',
      ]);
      expect(
        NotificationInteraction.decode(platform.scheduled.single.payload).route,
        '/s',
      );
    },
  );

  test(
    'tablet is opt-in and cancellation follows resolved source truth',
    () async {
      platform.current = NotificationPermission.granted;
      await reconciler.reconcile(
        desired: [_occurrence()],
        device: const NotificationDevicePolicy(
          deviceClass: NotificationDeviceClass.tablet,
          enabled: true,
        ),
      );
      final id = store.records.values.single.notificationId;
      await reconciler.reconcile(
        desired: const [],
        device: const NotificationDevicePolicy(
          deviceClass: NotificationDeviceClass.tablet,
          enabled: true,
        ),
      );
      expect(platform.cancelled, contains(id));
    },
  );

  test(
    'restart and dismissal do not duplicate or resolve an occurrence',
    () async {
      platform.current = NotificationPermission.granted;
      const device = NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.phone,
      );
      await reconciler.reconcile(desired: [_occurrence()], device: device);
      await reconciler.markDismissed('key');
      await reconciler.reconcile(desired: [_occurrence()], device: device);
      expect(platform.scheduled, hasLength(1));
      expect(store.records.values.single.dismissed, isTrue);
    },
  );

  test('unknown or denied permission never schedules delivery', () async {
    const device = NotificationDevicePolicy(
      deviceClass: NotificationDeviceClass.phone,
    );
    await reconciler.reconcile(desired: [_occurrence()], device: device);
    expect(platform.scheduled, isEmpty);
    platform.current = NotificationPermission.denied;
    await reconciler.reconcile(
      desired: [_occurrence()],
      device: device,
      requestPermission: true,
    );
    expect(platform.requested, isTrue);
    expect(platform.scheduled, hasLength(1));
  });

  test('tablet and desktop delivery default off while phone defaults on', () {
    expect(
      const NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.phone,
      ).effectiveEnabled,
      isTrue,
    );
    expect(
      const NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.tablet,
      ).effectiveEnabled,
      isFalse,
    );
    expect(
      const NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.desktop,
      ).effectiveEnabled,
      isFalse,
    );
  });

  test('detailed preview is an explicit per-device choice', () async {
    platform.current = NotificationPermission.granted;
    await reconciler.reconcile(
      desired: [_occurrence()],
      device: const NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.phone,
        detailedPreview: true,
      ),
    );
    expect(platform.scheduled.single.body, 'Detailed but user-enabled');
    await reconciler.reconcile(
      desired: [_occurrence()],
      device: const NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.phone,
        detailedPreview: false,
      ),
    );
    expect(platform.cancelled, hasLength(1));
    expect(
      platform.scheduled.last.body,
      'Open Clinical Calendar to review this reminder.',
    );
  });

  test(
    'pending occurrence moves when device-zone quiet-hours result changes',
    () async {
      platform.current = NotificationPermission.granted;
      const device = NotificationDevicePolicy(
        deviceClass: NotificationDeviceClass.phone,
      );
      await reconciler.reconcile(desired: [_occurrence()], device: device);
      final moved = _occurrence(atUtc: DateTime.utc(2026, 1, 1, 1));
      await reconciler.reconcile(desired: [moved], device: device);
      expect(platform.scheduled, hasLength(2));
      expect(platform.cancelled, hasLength(1));
    },
  );
}

ReminderOccurrence _occurrence({DateTime? atUtc}) => ReminderOccurrence(
  occurrenceKey: 'key',
  synchronizationKey: 'base-key',
  kind: ReminderKind.clinicalConfirmation,
  subjectId: 's',
  scheduledForUtc: atUtc ?? DateTime.utc(2026, 1, 1),
  title: 'Confirm',
  genericBody: 'Open Clinical Calendar to review this reminder.',
  detailedBody: 'Detailed but user-enabled',
  route: '/s',
  snoozeOptions: const [ReminderSnooze.oneHour, ReminderSnooze.tomorrowMorning],
);

final class _Scheduled {
  _Scheduled(this.body, this.payload, this.actions);
  final String body;
  final String payload;
  final List<NotificationAction> actions;
}

final class _Platform implements NotificationPlatform {
  NotificationPermission current = NotificationPermission.unknown;
  bool requested = false;
  final scheduled = <_Scheduled>[];
  final cancelled = <int>[];
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<NotificationPermission> permission() async => current;
  @override
  Future<NotificationPermission> requestPermission() async {
    requested = true;
    return current = NotificationPermission.granted;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime atUtc,
    required String title,
    required String body,
    required String payload,
    required List<NotificationAction> actions,
  }) async {
    scheduled.add(_Scheduled(body, payload, actions));
  }
}

final class _Store implements NotificationDeliveryStore {
  Map<String, NotificationDeliveryRecord> records = {};
  @override
  Future<Map<String, NotificationDeliveryRecord>> readAll() async =>
      Map.of(records);
  @override
  Future<void> replaceAll(
    Map<String, NotificationDeliveryRecord> records,
  ) async {
    this.records = Map.of(records);
  }
}
