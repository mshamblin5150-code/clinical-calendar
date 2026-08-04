import '../ports.dart';
import '../repositories.dart';
import 'notification_reconciler.dart';
import 'reminder_policy.dart';
import 'reminder_state_service.dart';

/// A repository-backed snapshot of everything needed to derive native
/// notifications. Composition roots provide the source so this orchestration
/// remains independent of Flutter and storage adapters.
final class ReminderCandidatePlan {
  const ReminderCandidatePlan({
    required this.candidates,
    this.disabledKinds = const {},
  });

  final List<ReminderCandidate> candidates;
  final Set<ReminderKind> disabledKinds;
}

abstract interface class ReminderCandidateSource {
  Future<ReminderCandidatePlan> load(DateTime nowUtc);
}

/// Rebuilds pending native deliveries from current domain truth and persists
/// snoozes as synchronized ReminderState records.
final class ProductionNotificationService implements NotificationService {
  ProductionNotificationService({
    required this.source,
    required this.policy,
    required this.reconciler,
    required this.states,
    required this.devicePolicies,
    required this.clock,
    required this.identifiers,
    required this.studentId,
    required this.deviceClass,
    required this.deviceTimeZoneId,
    this.onBodyTap,
  });

  final ReminderCandidateSource source;
  final ReminderPolicy policy;
  final NotificationReconciler reconciler;
  final ReminderStateApplicationService states;
  final NotificationDevicePolicyStore devicePolicies;
  final Clock clock;
  final IdentifierGenerator identifiers;
  final String studentId;
  final NotificationDeviceClass deviceClass;
  final String deviceTimeZoneId;
  final void Function(NotificationInteraction interaction)? onBodyTap;

  Map<String, ReminderOccurrence> _latest = const {};
  Future<void> _tail = Future.value();

  @override
  Future<void> reconcileScheduledNotifications() => _serialized(_reconcile);

  Future<void> handleInteraction(NotificationInteraction interaction) =>
      _serialized(() async {
        final snooze = interaction.snooze;
        if (snooze == null) {
          onBodyTap?.call(interaction);
          return;
        }
        var occurrence = _latest[interaction.synchronizationKey];
        if (occurrence == null) {
          await _reconcile();
          occurrence = _latest[interaction.synchronizationKey];
        }
        if (occurrence == null) return;
        final now = clock.nowUtc().toUtc();
        final existing = await states.findByOccurrenceKey(
          studentId: studentId,
          occurrenceKey: interaction.synchronizationKey,
        );
        final value = ReminderState(
          id: existing?.value.id ?? identifiers.nextIdentifier(),
          occurrenceKey: interaction.synchronizationKey,
          kind: occurrence.kind,
          subjectEntityId: occurrence.subjectId,
          scheduledForUtc: occurrence.scheduledForUtc,
          snoozedUntilUtc: policy.snoozedUntilUtc(
            choice: snooze,
            chosenAtUtc: now,
            deviceTimeZoneId: deviceTimeZoneId,
          ),
        );
        await states.put(
          studentId: studentId,
          value: value,
          expectedRevision: existing?.revision ?? 0,
          mutation: MutationToken(
            operationId: identifiers.nextIdentifier(),
            idempotencyKey: identifiers.nextIdentifier(),
            occurredAtUtc: now,
          ),
        );
        await _reconcile();
      });

  Future<void> _reconcile() async {
    final now = clock.nowUtc().toUtc();
    final plan = await source.load(now);
    final device =
        await devicePolicies.read(deviceClass) ??
        NotificationDevicePolicy(deviceClass: deviceClass);
    final snoozes = await states.synchronizedSnoozes(studentId: studentId);
    final desired = policy.build(
      candidates: plan.candidates,
      nowUtc: now,
      deviceTimeZoneId: deviceTimeZoneId,
      synchronizedSnoozes: snoozes,
      disabledKinds: plan.disabledKinds,
      quietStartsAtHour: device.quietStartsAtHour,
      quietEndsAtHour: device.quietEndsAtHour,
    );
    _latest = {
      for (final occurrence in desired)
        occurrence.synchronizationKey: occurrence,
    };
    await reconciler.reconcile(
      desired: desired,
      device: device,
      requestPermission: device.effectiveEnabled,
    );
  }

  Future<void> _serialized(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.catchError((Object _) {});
    return result;
  }
}
