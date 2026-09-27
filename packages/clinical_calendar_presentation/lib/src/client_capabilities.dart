enum ClientCapabilityHost { thisClient, installedApps }

final class ClinicalCalendarClientCapabilities {
  const ClinicalCalendarClientCapabilities({
    this.backups = ClientCapabilityHost.thisClient,
    this.reminders = ClientCapabilityHost.thisClient,
  });

  static const web = ClinicalCalendarClientCapabilities(
    backups: ClientCapabilityHost.installedApps,
    reminders: ClientCapabilityHost.installedApps,
  );

  static const installedAppBackupNote =
      'Backups are made from your installed apps.';
  static const installedAppReminderNote =
      'Reminders are delivered by your installed apps';

  final ClientCapabilityHost backups;
  final ClientCapabilityHost reminders;
}
