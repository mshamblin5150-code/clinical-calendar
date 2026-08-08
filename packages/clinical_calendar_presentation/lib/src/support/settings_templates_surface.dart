import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../responsive_shell.dart';
import '../theme_contract.dart';
import '../theme_gallery.dart';
import '../time_input.dart';
import '../variant_f_theme.dart';

final class DeviceNotificationPreferences {
  const DeviceNotificationPreferences({
    required this.deliveryEnabled,
    this.detailedPreview = false,
    this.quietStartsAtHour = 21,
    this.quietStartsAtMinute = 0,
    this.quietEndsAtHour = 7,
    this.quietEndsAtMinute = 0,
  }) : assert(quietStartsAtHour >= 0 && quietStartsAtHour <= 23),
       assert(quietStartsAtMinute >= 0 && quietStartsAtMinute <= 59),
       assert(quietEndsAtHour >= 0 && quietEndsAtHour <= 23),
       assert(quietEndsAtMinute >= 0 && quietEndsAtMinute <= 59);

  final bool deliveryEnabled;
  final bool detailedPreview;
  final int quietStartsAtHour;
  final int quietStartsAtMinute;
  final int quietEndsAtHour;
  final int quietEndsAtMinute;

  DeviceNotificationPreferences copyWith({
    bool? deliveryEnabled,
    bool? detailedPreview,
    int? quietStartsAtHour,
    int? quietStartsAtMinute,
    int? quietEndsAtHour,
    int? quietEndsAtMinute,
  }) => DeviceNotificationPreferences(
    deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
    detailedPreview: detailedPreview ?? this.detailedPreview,
    quietStartsAtHour: quietStartsAtHour ?? this.quietStartsAtHour,
    quietStartsAtMinute: quietStartsAtMinute ?? this.quietStartsAtMinute,
    quietEndsAtHour: quietEndsAtHour ?? this.quietEndsAtHour,
    quietEndsAtMinute: quietEndsAtMinute ?? this.quietEndsAtMinute,
  );
}

typedef SaveDeviceNotificationPreferences =
    Future<void> Function(DeviceNotificationPreferences preferences);

final class ClinicalTemplateDefaultOption {
  const ClinicalTemplateDefaultOption({
    required this.clinicalPlacementId,
    required this.preceptorId,
    required this.label,
  });

  final String clinicalPlacementId;
  final String preceptorId;
  final String label;

  String get key => '$clinicalPlacementId|$preceptorId';
}

final class SettingsTemplatesSurface extends StatefulWidget {
  const SettingsTemplatesSurface({
    required this.settings,
    required this.scheduleTemplates,
    required this.newTemplateId,
    required this.onSaveSettings,
    required this.onSaveTemplate,
    required this.onRemoveTemplate,
    this.clinicalDefaults = const [],
    this.deviceNotifications,
    this.onSaveDeviceNotifications,
    this.authoritativeThemeId,
    this.onPreviewTheme,
    super.key,
  }) : assert(
         (deviceNotifications == null) == (onSaveDeviceNotifications == null),
         'Device notification preferences and save callback must be provided '
         'together.',
       );

  final StudentSettings settings;
  final List<ScheduleTemplate> scheduleTemplates;
  final String Function() newTemplateId;
  final Future<void> Function(StudentSettings settings) onSaveSettings;
  final Future<void> Function(ScheduleTemplate template) onSaveTemplate;
  final Future<void> Function(String templateId) onRemoveTemplate;
  final List<ClinicalTemplateDefaultOption> clinicalDefaults;
  final DeviceNotificationPreferences? deviceNotifications;
  final SaveDeviceNotificationPreferences? onSaveDeviceNotifications;
  final String? authoritativeThemeId;
  final PreviewTheme? onPreviewTheme;

  @override
  State<SettingsTemplatesSurface> createState() =>
      _SettingsTemplatesSurfaceState();
}

final class _SettingsTemplatesSurfaceState
    extends State<SettingsTemplatesSurface> {
  late int _weekStart;
  late TimeDisplayPreference _timeDisplay;
  late String _themeId;
  late String _inspectedThemeId;
  late bool _enhancedAccessibility;
  late SynchronizationPreference _synchronization;
  late NotificationPreferences _notifications;
  DeviceNotificationPreferences? _deviceNotifications;
  late List<_TemplateDraft> _templates;
  final Set<String> _removedTemplateIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _weekStart = settings.weekStart;
    _timeDisplay = settings.timeDisplay;
    _themeId = settings.themeId;
    _inspectedThemeId = _availableThemeId(
      widget.authoritativeThemeId ?? settings.themeId,
    );
    _enhancedAccessibility = settings.enhancedAccessibility;
    _synchronization = settings.synchronization;
    _notifications = settings.notifications;
    _deviceNotifications = widget.deviceNotifications;
    _templates = widget.scheduleTemplates
        .map(_TemplateDraft.fromTemplate)
        .toList(growable: true);
  }

  @override
  void didUpdateWidget(SettingsTemplatesSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.themeId != widget.settings.themeId) {
      _themeId = widget.settings.themeId;
    }
    if (oldWidget.settings.enhancedAccessibility !=
        widget.settings.enhancedAccessibility) {
      _enhancedAccessibility = widget.settings.enhancedAccessibility;
    }
    final oldAuthority =
        oldWidget.authoritativeThemeId ?? oldWidget.settings.themeId;
    final newAuthority = widget.authoritativeThemeId ?? widget.settings.themeId;
    if (oldAuthority != newAuthority &&
        _inspectedThemeId == _availableThemeId(oldAuthority)) {
      _inspectedThemeId = _availableThemeId(newAuthority);
    }
  }

  bool get _templatesValid => _templates.every((draft) => draft.isValid);

  bool get _themeGalleryEnabled =>
      ClinicalCalendarThemeBundleRegistry.standard.isSelectableCatalogComplete;

  String _availableThemeId(String themeId) =>
      ClinicalCalendarThemeBundleRegistry.standard.galleryBundles.any(
        (bundle) => bundle.id == themeId,
      )
      ? themeId
      : graphiteThemeId;

  Future<void> _save() async {
    if (_saving || !_templatesValid) return;
    setState(() => _saving = true);
    try {
      await widget.onSaveSettings(
        StudentSettings(
          weekStart: _weekStart,
          timeDisplay: _timeDisplay,
          themeId: _themeId,
          enhancedAccessibility: _enhancedAccessibility,
          synchronization: _synchronization,
          notifications: _notifications,
        ),
      );
      final deviceNotifications = _deviceNotifications;
      if (deviceNotifications != null) {
        await widget.onSaveDeviceNotifications!(deviceNotifications);
      }
      for (final templateId in _removedTemplateIds) {
        await widget.onRemoveTemplate(templateId);
      }
      for (final draft in _templates) {
        await widget.onSaveTemplate(draft.toTemplate(widget.clinicalDefaults));
      }
      _removedTemplateIds.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addTemplate() => setState(
    () => _templates.add(
      _TemplateDraft(
        id: widget.newTemplateId(),
        name: 'New Template',
        type: ScheduleTemplateType.workShift,
        start: '07:00',
        end: '15:00',
      ),
    ),
  );

  void _removeTemplate(_TemplateDraft draft) => setState(() {
    _templates.remove(draft);
    if (widget.scheduleTemplates.any((template) => template.id == draft.id)) {
      _removedTemplateIds.add(draft.id);
    }
  });

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('settings-templates-surface'),
    padding: const EdgeInsets.all(16),
    children: [
      ShellPanel(
        label: 'Settings',
        accent: context.clinicalColors.clinical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(
                  DropdownButtonFormField<int>(
                    key: const Key('week-start-setting'),
                    isExpanded: true,
                    initialValue: _weekStart,
                    decoration: const InputDecoration(labelText: 'Week starts'),
                    items: const [
                      DropdownMenuItem(
                        value: DateTime.sunday,
                        child: Text('Sunday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.monday,
                        child: Text('Monday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.saturday,
                        child: Text('Saturday'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _weekStart = value!),
                  ),
                ),
                _field(
                  DropdownButtonFormField<TimeDisplayPreference>(
                    key: const Key('time-display-setting'),
                    isExpanded: true,
                    initialValue: _timeDisplay,
                    decoration: const InputDecoration(
                      labelText: 'Time display',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TimeDisplayPreference.military,
                        child: Text('Military time'),
                      ),
                      DropdownMenuItem(
                        value: TimeDisplayPreference.twelveHour,
                        child: Text('12-hour time'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _timeDisplay = value!),
                  ),
                ),
                if (!_themeGalleryEnabled)
                  _field(
                    DropdownButtonFormField<String>(
                      key: const Key('theme-setting'),
                      isExpanded: true,
                      initialValue: _themeId == StudentSettings.variantFThemeId
                          ? _themeId
                          : null,
                      decoration: const InputDecoration(labelText: 'Theme'),
                      items: const [
                        DropdownMenuItem(
                          value: StudentSettings.variantFThemeId,
                          child: Text('Containment Drone 47-Alpha'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _themeId = value!),
                    ),
                    width: 280,
                  ),
                if (!_themeGalleryEnabled &&
                    _themeId != StudentSettings.variantFThemeId)
                  _field(
                    Semantics(
                      key: const Key('theme-fallback-in-use'),
                      label: 'Graphite, Fallback in use',
                      child: const Text(
                        'Saved theme unavailable in this app version.\n'
                        'Graphite — Fallback in use',
                      ),
                    ),
                    width: 280,
                  ),
                _field(
                  DropdownButtonFormField<SynchronizationPreference>(
                    key: const Key('synchronization-setting'),
                    isExpanded: true,
                    initialValue: _synchronization,
                    decoration: const InputDecoration(
                      labelText: 'Synchronization',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SynchronizationPreference.enabled,
                        child: Text('Enabled'),
                      ),
                      DropdownMenuItem(
                        value: SynchronizationPreference.paused,
                        child: Text('Paused'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _synchronization = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_themeGalleryEnabled) ...[
              Text(
                'THEME GALLERY',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ThemeGallery(
                appliedThemeId: widget.authoritativeThemeId ?? _themeId,
                selectedThemeId: _inspectedThemeId,
                onSelected: (themeId) =>
                    setState(() => _inspectedThemeId = themeId),
                onPreview: widget.onPreviewTheme,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'NOTIFICATION PREFERENCES',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('work-shift-notifications-setting'),
                contentPadding: EdgeInsets.zero,
                title: _switchTitle(
                  'Work Shift reminders',
                  _notifications.upcomingWorkShiftsEnabled,
                ),
                subtitle: Text(
                  _notifications.upcomingWorkShiftsEnabled
                      ? 'Scheduled using the lead times below.'
                      : 'Muted — no Work Shift notifications.',
                ),
                value: _notifications.upcomingWorkShiftsEnabled,
                onChanged: (value) => setState(
                  () => _notifications = _notifications.copyWith(
                    upcomingWorkShiftsEnabled: value,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('clinical-session-notifications-setting'),
                contentPadding: EdgeInsets.zero,
                title: _switchTitle(
                  'Clinical Session reminders',
                  _notifications.upcomingClinicalSessionsEnabled,
                ),
                subtitle: Text(
                  _notifications.upcomingClinicalSessionsEnabled
                      ? 'Scheduled using the lead times below.'
                      : 'Muted — no Clinical Session notifications.',
                ),
                value: _notifications.upcomingClinicalSessionsEnabled,
                onChanged: (value) => setState(
                  () => _notifications = _notifications.copyWith(
                    upcomingClinicalSessionsEnabled: value,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _leadTimeField(
                  key: const Key('work-shift-first-lead-setting'),
                  label: 'First Work Shift reminder',
                  valueMinutes: _notifications.workShiftFirstLeadMinutes,
                  enabled: _notifications.upcomingWorkShiftsEnabled,
                  onChanged: (value) => _notifications = _notifications
                      .copyWith(workShiftFirstLeadMinutes: value),
                ),
                _leadTimeField(
                  key: const Key('work-shift-second-lead-setting'),
                  label: 'Second Work Shift reminder',
                  valueMinutes: _notifications.workShiftSecondLeadMinutes,
                  enabled: _notifications.upcomingWorkShiftsEnabled,
                  onChanged: (value) => _notifications = _notifications
                      .copyWith(workShiftSecondLeadMinutes: value),
                ),
                _leadTimeField(
                  key: const Key('clinical-session-first-lead-setting'),
                  label: 'First Clinical Session reminder',
                  valueMinutes: _notifications.clinicalSessionFirstLeadMinutes,
                  enabled: _notifications.upcomingClinicalSessionsEnabled,
                  onChanged: (value) => _notifications = _notifications
                      .copyWith(clinicalSessionFirstLeadMinutes: value),
                ),
                _leadTimeField(
                  key: const Key('clinical-session-second-lead-setting'),
                  label: 'Second Clinical Session reminder',
                  valueMinutes: _notifications.clinicalSessionSecondLeadMinutes,
                  enabled: _notifications.upcomingClinicalSessionsEnabled,
                  onChanged: (value) => _notifications = _notifications
                      .copyWith(clinicalSessionSecondLeadMinutes: value),
                ),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('weekly-summary-setting'),
                contentPadding: EdgeInsets.zero,
                title: _switchTitle(
                  'Weekly summary',
                  _notifications.weeklySummaryEnabled,
                ),
                subtitle: Text(
                  _notifications.weeklySummaryEnabled
                      ? 'Scheduled at the day and time below.'
                      : 'Muted — no weekly summary notification.',
                ),
                value: _notifications.weeklySummaryEnabled,
                onChanged: (value) => setState(
                  () => _notifications = _notifications.copyWith(
                    weeklySummaryEnabled: value,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(
                  DropdownButtonFormField<int>(
                    key: const Key('weekly-summary-weekday-setting'),
                    isExpanded: true,
                    initialValue: _notifications.weeklySummaryWeekday,
                    decoration: const InputDecoration(labelText: 'Summary day'),
                    items: const [
                      DropdownMenuItem(
                        value: DateTime.monday,
                        child: Text('Monday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.tuesday,
                        child: Text('Tuesday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.wednesday,
                        child: Text('Wednesday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.thursday,
                        child: Text('Thursday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.friday,
                        child: Text('Friday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.saturday,
                        child: Text('Saturday'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.sunday,
                        child: Text('Sunday'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _notifications = _notifications.copyWith(
                        weeklySummaryWeekday: value!,
                      ),
                    ),
                  ),
                ),
                _timeField(
                  key: const Key('weekly-summary-hour-setting'),
                  label: 'Summary time',
                  value: LocalTime(
                    _notifications.weeklySummaryHour,
                    _notifications.weeklySummaryMinute,
                  ),
                  enabled: _notifications.weeklySummaryEnabled,
                  onChanged: (value) =>
                      _notifications = _notifications.copyWith(
                        weeklySummaryHour: value.hour,
                        weeklySummaryMinute: value.minute,
                      ),
                ),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('backup-reminders-setting'),
                contentPadding: EdgeInsets.zero,
                title: _switchTitle(
                  'Portable backup reminders',
                  _notifications.backupRemindersEnabled,
                ),
                subtitle: Text(
                  _notifications.backupRemindersEnabled
                      ? 'Scheduled using the day intervals below.'
                      : 'Muted — no portable backup notifications.',
                ),
                value: _notifications.backupRemindersEnabled,
                onChanged: (value) => setState(
                  () => _notifications = _notifications.copyWith(
                    backupRemindersEnabled: value,
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _minutesField(
                  key: const Key('no-backup-reminder-days-setting'),
                  label: 'First backup reminder (days)',
                  value: _notifications.noBackupReminderDays,
                  onChanged: (value) => _notifications = _notifications
                      .copyWith(noBackupReminderDays: value),
                ),
                _minutesField(
                  key: const Key('stale-backup-reminder-days-setting'),
                  label: 'Stale backup reminder (days)',
                  value: _notifications.staleBackupReminderDays,
                  onChanged: (value) => _notifications = _notifications
                      .copyWith(staleBackupReminderDays: value),
                ),
              ],
            ),
            if (_deviceNotifications case final device?) ...[
              const SizedBox(height: 12),
              Text(
                'THIS DEVICE',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  key: const Key('device-notification-delivery-setting'),
                  contentPadding: EdgeInsets.zero,
                  title: _switchTitle(
                    'System notification delivery',
                    device.deliveryEnabled,
                  ),
                  subtitle: Text(
                    device.deliveryEnabled
                        ? 'On — this device may deliver enabled reminders.'
                        : 'Muted — this device will deliver no notifications.',
                  ),
                  value: device.deliveryEnabled,
                  onChanged: (value) => setState(
                    () => _deviceNotifications = device.copyWith(
                      deliveryEnabled: value,
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  key: const Key('device-detailed-preview-setting'),
                  contentPadding: EdgeInsets.zero,
                  title: _switchTitle(
                    'Detailed lock-screen previews',
                    device.detailedPreview,
                    disabledLabel: 'Off',
                  ),
                  subtitle: Text(
                    device.detailedPreview
                        ? 'On — may include Clinical Placement details.'
                        : 'Off — lock-screen notifications stay generic.',
                  ),
                  value: device.detailedPreview,
                  onChanged: (value) => setState(
                    () => _deviceNotifications = device.copyWith(
                      detailedPreview: value,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _timeField(
                    key: const Key('device-quiet-start-setting'),
                    label: 'Quiet hours start',
                    value: LocalTime(
                      device.quietStartsAtHour,
                      device.quietStartsAtMinute,
                    ),
                    enabled: true,
                    onChanged: (value) =>
                        _deviceNotifications = device.copyWith(
                          quietStartsAtHour: value.hour,
                          quietStartsAtMinute: value.minute,
                        ),
                  ),
                  _timeField(
                    key: const Key('device-quiet-end-setting'),
                    label: 'Quiet hours end',
                    value: LocalTime(
                      device.quietEndsAtHour,
                      device.quietEndsAtMinute,
                    ),
                    enabled: true,
                    onChanged: (value) =>
                        _deviceNotifications = device.copyWith(
                          quietEndsAtHour: value.hour,
                          quietEndsAtMinute: value.minute,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      ShellPanel(
        label: 'Schedule Templates',
        accent: context.clinicalColors.scheduled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Templates copy date-free defaults into a scheduling batch. '
              'Later edits do not change existing commitments.',
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _templates.length; index++) ...[
              _TemplateEditor(
                key: ValueKey(_templates[index].id),
                index: index,
                draft: _templates[index],
                timeDisplay: _timeDisplay,
                clinicalDefaults: widget.clinicalDefaults,
                onChanged: () => setState(() {}),
                onRemove: () => _removeTemplate(_templates[index]),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              key: const Key('add-template-action'),
              onPressed: _addTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Add template'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('save-settings-templates-action'),
        onPressed: _saving || !_templatesValid ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Saving…' : 'Save settings and templates'),
      ),
    ],
  );

  Widget _field(Widget child, {double width = 230}) =>
      SizedBox(width: width, child: child);

  Widget _switchTitle(
    String label,
    bool enabled, {
    String disabledLabel = 'Muted',
  }) => Text(
    '$label — ${enabled ? 'On' : disabledLabel}',
    style: const TextStyle(fontWeight: FontWeight.w600),
  );

  Widget _minutesField({
    required Key key,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) => _field(
    TextFormField(
      key: key,
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null && parsed > 0) setState(() => onChanged(parsed));
      },
    ),
  );

  Widget _leadTimeField({
    required Key key,
    required String label,
    required int valueMinutes,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    final options = <int>{0, 60, 120, 240, 480, 720, 1440, 2880, 4320};
    options.add(valueMinutes);
    final ordered = options.toList()..sort();
    return _field(
      DropdownButtonFormField<int>(
        key: key,
        isExpanded: true,
        initialValue: valueMinutes,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final minutes in ordered)
            DropdownMenuItem(
              value: minutes,
              child: Text(_leadTimeLabel(minutes)),
            ),
        ],
        onChanged: enabled ? (next) => setState(() => onChanged(next!)) : null,
      ),
    );
  }

  Widget _timeField({
    required Key key,
    required String label,
    required LocalTime value,
    required bool enabled,
    required ValueChanged<LocalTime> onChanged,
  }) => _field(
    IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: ClinicalTimePickerField(
          key: key,
          label: label,
          value: value,
          twelveHour: _timeDisplay == TimeDisplayPreference.twelveHour,
          onChanged: (next) => setState(() => onChanged(next)),
        ),
      ),
    ),
  );
}

String _leadTimeLabel(int minutes) {
  if (minutes == 0) return 'Never';
  final hours = minutes / 60;
  final value = hours == hours.roundToDouble()
      ? hours.toInt().toString()
      : hours.toStringAsFixed(1);
  return '$value ${hours == 1 ? 'hour' : 'hours'} before';
}

final class _TemplateEditor extends StatelessWidget {
  const _TemplateEditor({
    required this.index,
    required this.draft,
    required this.timeDisplay,
    required this.clinicalDefaults,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final _TemplateDraft draft;
  final TimeDisplayPreference timeDisplay;
  final List<ClinicalTemplateDefaultOption> clinicalDefaults;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.clinicalColors.structureRaised,
      border: Border.all(color: context.clinicalColors.insetBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TEMPLATE ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: Key('remove-template-$index'),
                tooltip: 'Remove ${draft.name}',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _sized(
                TextFormField(
                  key: Key('template-name-$index'),
                  initialValue: draft.name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (value) {
                    draft.name = value;
                    onChanged();
                  },
                ),
              ),
              _sized(
                DropdownButtonFormField<ScheduleTemplateType>(
                  key: Key('template-type-$index'),
                  isExpanded: true,
                  initialValue: draft.type,
                  decoration: const InputDecoration(labelText: 'Commitment'),
                  items: const [
                    DropdownMenuItem(
                      value: ScheduleTemplateType.workShift,
                      child: Text('Work Shift'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleTemplateType.clinicalSession,
                      child: Text('Clinical Session'),
                    ),
                  ],
                  onChanged: (value) {
                    draft.type = value!;
                    if (value == ScheduleTemplateType.workShift) {
                      draft.clinicalDefaultKey = null;
                    }
                    onChanged();
                  },
                ),
              ),
              _sized(
                ClinicalTimePickerField(
                  key: Key('template-start-$index'),
                  label: 'Start',
                  value: draft.startTime ?? LocalTime(7, 0),
                  twelveHour: timeDisplay == TimeDisplayPreference.twelveHour,
                  onChanged: (value) {
                    draft.start = value.military;
                    onChanged();
                  },
                ),
              ),
              _sized(
                ClinicalTimePickerField(
                  key: Key('template-end-$index'),
                  label: 'End',
                  value: draft.endTime ?? LocalTime(15, 0),
                  twelveHour: timeDisplay == TimeDisplayPreference.twelveHour,
                  onChanged: (value) {
                    draft.end = value.military;
                    onChanged();
                  },
                ),
              ),
              if (draft.type == ScheduleTemplateType.clinicalSession)
                _sized(
                  DropdownButtonFormField<String?>(
                    key: Key('template-clinical-default-$index'),
                    isExpanded: true,
                    initialValue: draft.clinicalDefaultKey,
                    decoration: const InputDecoration(
                      labelText: 'Clinical defaults',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      for (final option in clinicalDefaults)
                        DropdownMenuItem<String?>(
                          value: option.key,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) {
                      draft.clinicalDefaultKey = value;
                      onChanged();
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            draft.durationLabel(timeDisplay),
            key: Key('template-duration-$index'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: draft.isValid
                  ? context.clinicalColors.scheduled
                  : context.clinicalColors.urgent,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sized(Widget child) => SizedBox(width: 220, child: child);
}

final class _TemplateDraft {
  _TemplateDraft({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.end,
    this.clinicalDefaultKey,
  });

  factory _TemplateDraft.fromTemplate(ScheduleTemplate value) => _TemplateDraft(
    id: value.id,
    name: value.name,
    type: value.type,
    start: value.startTime.military,
    end: value.endTime.military,
    clinicalDefaultKey: value.clinicalPlacementId == null
        ? null
        : '${value.clinicalPlacementId}|${value.preceptorId}',
  );

  final String id;
  String name;
  ScheduleTemplateType type;
  String start;
  String end;
  String? clinicalDefaultKey;

  LocalTime? get startTime => _parseTime(start);
  LocalTime? get endTime => _parseTime(end);

  bool get isValid =>
      name.trim().isNotEmpty &&
      startTime != null &&
      endTime != null &&
      startTime != endTime;

  String durationLabel(TimeDisplayPreference preference) {
    final startValue = startTime;
    final endValue = endTime;
    if (startValue == null || endValue == null || startValue == endValue) {
      return 'Enter a valid non-zero time range.';
    }
    var minutes =
        endValue.minutesSinceMidnight - startValue.minutesSinceMidnight;
    if (minutes < 0) minutes += 24 * 60;
    final range = preference == TimeDisplayPreference.military
        ? '${startValue.military}–${endValue.military}'
        : '${startValue.twelveHour}–${endValue.twelveHour}';
    final hours = minutes / 60;
    return '$range · ${hours == hours.roundToDouble() ? hours.toInt() : hours.toStringAsFixed(2)} hours automatically';
  }

  ScheduleTemplate toTemplate(
    List<ClinicalTemplateDefaultOption> clinicalDefaults,
  ) {
    final selected = clinicalDefaultKey == null
        ? null
        : clinicalDefaults
              .where((option) => option.key == clinicalDefaultKey)
              .single;
    return ScheduleTemplate(
      id: id,
      name: name,
      type: type,
      startTime: startTime!,
      endTime: endTime!,
      clinicalPlacementId: selected?.clinicalPlacementId,
      preceptorId: selected?.preceptorId,
    );
  }
}

LocalTime? _parseTime(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  try {
    return LocalTime(int.parse(match.group(1)!), int.parse(match.group(2)!));
  } on DomainValidationException {
    return null;
  }
}
