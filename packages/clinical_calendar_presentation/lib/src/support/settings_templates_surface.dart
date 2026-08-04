import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../responsive_shell.dart';
import '../variant_f_theme.dart';

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
    super.key,
  });

  final StudentSettings settings;
  final List<ScheduleTemplate> scheduleTemplates;
  final String Function() newTemplateId;
  final Future<void> Function(StudentSettings settings) onSaveSettings;
  final Future<void> Function(ScheduleTemplate template) onSaveTemplate;
  final Future<void> Function(String templateId) onRemoveTemplate;
  final List<ClinicalTemplateDefaultOption> clinicalDefaults;

  @override
  State<SettingsTemplatesSurface> createState() =>
      _SettingsTemplatesSurfaceState();
}

final class _SettingsTemplatesSurfaceState
    extends State<SettingsTemplatesSurface> {
  late int _weekStart;
  late TimeDisplayPreference _timeDisplay;
  late String _themeId;
  late SynchronizationPreference _synchronization;
  late NotificationPreferences _notifications;
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
    _synchronization = settings.synchronization;
    _notifications = settings.notifications;
    _templates = widget.scheduleTemplates
        .map(_TemplateDraft.fromTemplate)
        .toList(growable: true);
  }

  bool get _templatesValid => _templates.every((draft) => draft.isValid);

  Future<void> _save() async {
    if (_saving || !_templatesValid) return;
    setState(() => _saving = true);
    try {
      await widget.onSaveSettings(
        StudentSettings(
          weekStart: _weekStart,
          timeDisplay: _timeDisplay,
          themeId: _themeId,
          synchronization: _synchronization,
          notifications: _notifications,
        ),
      );
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
                _field(
                  DropdownButtonFormField<String>(
                    key: const Key('theme-setting'),
                    isExpanded: true,
                    initialValue: _themeId,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    items: const [
                      DropdownMenuItem(
                        value: StudentSettings.variantFThemeId,
                        child: Text('Borg Tactical Console'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _themeId = value!),
                  ),
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
            Text(
              'NOTIFICATION PREFERENCES',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('upcoming-notifications-setting'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Upcoming commitment reminders'),
                value: _notifications.upcomingCommitmentsEnabled,
                onChanged: (value) => setState(
                  () => _notifications = NotificationPreferences(
                    upcomingCommitmentsEnabled: value,
                    weeklySummaryEnabled: _notifications.weeklySummaryEnabled,
                    backupRemindersEnabled:
                        _notifications.backupRemindersEnabled,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('weekly-summary-setting'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Weekly summary'),
                value: _notifications.weeklySummaryEnabled,
                onChanged: (value) => setState(
                  () => _notifications = NotificationPreferences(
                    upcomingCommitmentsEnabled:
                        _notifications.upcomingCommitmentsEnabled,
                    weeklySummaryEnabled: value,
                    backupRemindersEnabled:
                        _notifications.backupRemindersEnabled,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                key: const Key('backup-reminders-setting'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Portable backup reminders'),
                value: _notifications.backupRemindersEnabled,
                onChanged: (value) => setState(
                  () => _notifications = NotificationPreferences(
                    upcomingCommitmentsEnabled:
                        _notifications.upcomingCommitmentsEnabled,
                    weeklySummaryEnabled: _notifications.weeklySummaryEnabled,
                    backupRemindersEnabled: value,
                  ),
                ),
              ),
            ),
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
        label: Text(_saving ? 'Savingâ€¦' : 'Save settings and templates'),
      ),
    ],
  );

  Widget _field(Widget child) => SizedBox(width: 230, child: child);
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
                TextFormField(
                  key: Key('template-start-$index'),
                  initialValue: draft.start,
                  inputFormatters: const [],
                  decoration: const InputDecoration(labelText: 'Start (HH:MM)'),
                  onChanged: (value) {
                    draft.start = value;
                    onChanged();
                  },
                ),
              ),
              _sized(
                TextFormField(
                  key: Key('template-end-$index'),
                  initialValue: draft.end,
                  decoration: const InputDecoration(labelText: 'End (HH:MM)'),
                  onChanged: (value) {
                    draft.end = value;
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
        ? '${startValue.military}â€“${endValue.military}'
        : '${startValue.twelveHour}â€“${endValue.twelveHour}';
    final hours = minutes / 60;
    return '$range Â· ${hours == hours.roundToDouble() ? hours.toInt() : hours.toStringAsFixed(2)} hours automatically';
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
