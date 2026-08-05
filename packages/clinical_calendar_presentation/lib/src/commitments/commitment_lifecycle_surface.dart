import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';
import '../variant_f_theme.dart';
import 'commitment_lifecycle_controller.dart';

final class CommitmentLifecycleSurface extends StatelessWidget {
  CommitmentLifecycleSurface({
    required this.controller,
    required this.studentId,
    this.twelveHourTime = false,
    this.onClose,
    super.key,
  }) : assert(
         controller.studentId == studentId,
         'Lifecycle controller and surface must use the same Student.',
       );

  final CommitmentLifecycleController controller;
  final String studentId;
  final bool twelveHourTime;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final snapshot = controller.snapshot;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.clinicalColors.structure,
          border: Border.all(color: context.clinicalColors.insetBorder),
          borderRadius: BorderRadius.circular(
            context.clinicalMetrics.cornerRadius,
          ),
        ),
        child: Column(
          key: const Key('commitment-lifecycle-surface'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SurfaceHeader(snapshot: snapshot, onClose: onClose),
            if (controller.error != null)
              _LifecycleMessage(
                key: const Key('lifecycle-error'),
                message: controller.error.toString(),
                urgent: true,
              ),
            if (controller.isBusy && snapshot == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (snapshot == null)
              const Expanded(
                child: Center(child: Text('Select a calendar entry.')),
              )
            else
              Expanded(
                child: _LifecycleEditor(
                  key: ValueKey('${snapshot.id}|${snapshot.revision}'),
                  controller: controller,
                  snapshot: snapshot,
                  twelveHourTime: twelveHourTime,
                  onDeleted: onClose,
                ),
              ),
          ],
        ),
      );
    },
  );
}

final class _SurfaceHeader extends StatelessWidget {
  const _SurfaceHeader({required this.snapshot, required this.onClose});

  final CommitmentLifecycleSnapshot? snapshot;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(switch (snapshot) {
            WorkShiftLifecycleSnapshot() => 'WORK SHIFT DETAILS',
            ClinicalSessionLifecycleSnapshot() => 'CLINICAL SESSION DETAILS',
            ProtectedDayLifecycleSnapshot() => 'PROTECTED DAY DETAILS',
            null => 'CALENDAR ENTRY DETAILS',
          }, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (onClose != null)
          IconButton(
            key: const Key('close-lifecycle-surface'),
            onPressed: onClose,
            tooltip: 'Close details',
            icon: const Icon(Icons.close),
          ),
      ],
    ),
  );
}

final class _LifecycleEditor extends StatefulWidget {
  const _LifecycleEditor({
    required this.controller,
    required this.snapshot,
    required this.twelveHourTime,
    required this.onDeleted,
    super.key,
  });

  final CommitmentLifecycleController controller;
  final CommitmentLifecycleSnapshot snapshot;
  final bool twelveHourTime;
  final VoidCallback? onDeleted;

  @override
  State<_LifecycleEditor> createState() => _LifecycleEditorState();
}

final class _LifecycleEditorState extends State<_LifecycleEditor> {
  late final TextEditingController _date;
  late final TextEditingController _start;
  late final TextEditingController _end;
  String? _preceptorId;
  String? _validation;

  @override
  void initState() {
    super.initState();
    final snapshot = widget.snapshot;
    switch (snapshot) {
      case WorkShiftLifecycleSnapshot(:final record):
        _initializeTimed(record.value.plannedInterval);
      case ClinicalSessionLifecycleSnapshot(:final record):
        final session = record.value;
        final editable = session.state == ClinicalSessionState.completed
            ? session.actualInterval!
            : session.plannedInterval;
        _initializeTimed(editable);
        _preceptorId = session.preceptorId;
      case ProtectedDayLifecycleSnapshot(:final record):
        _date = TextEditingController(text: formatUsDate(record.value.date));
        _start = TextEditingController();
        _end = TextEditingController();
    }
  }

  void _initializeTimed(ZonedInterval interval) {
    _date = TextEditingController(text: formatUsDate(interval.startDate));
    _start = TextEditingController(
      text: widget.twelveHourTime
          ? interval.startTime.twelveHour
          : interval.startTime.military,
    );
    _end = TextEditingController(
      text: widget.twelveHourTime
          ? interval.endTime.twelveHour
          : interval.endTime.military,
    );
  }

  @override
  void dispose() {
    _date.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
    child: switch (widget.snapshot) {
      WorkShiftLifecycleSnapshot(:final record) => _timedEditor(
        context,
        summary: _workSummary(record.value),
        primaryLabel: 'Move or save corrected times',
        onPrimary: _saveTimed,
        onDelete: () => _confirmDelete(context),
      ),
      ClinicalSessionLifecycleSnapshot() => _clinicalEditor(context),
      ProtectedDayLifecycleSnapshot(:final record) => _protectedDayEditor(
        context,
        record.value,
      ),
    },
  );

  Widget _clinicalEditor(BuildContext context) {
    final snapshot = widget.snapshot as ClinicalSessionLifecycleSnapshot;
    final session = snapshot.record.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClinicalSummary(snapshot: snapshot),
        const SizedBox(height: 14),
        _dateField(),
        const SizedBox(height: 10),
        _timeFields(),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: const Key('lifecycle-preceptor-field'),
          initialValue: _preceptorId,
          decoration: const InputDecoration(labelText: 'Preceptor'),
          items: [
            for (final preceptor in snapshot.attachedPreceptors)
              DropdownMenuItem(
                value: preceptor.id,
                child: Text(preceptor.name),
              ),
          ],
          onChanged: widget.controller.isBusy
              ? null
              : (value) => setState(() => _preceptorId = value),
        ),
        const SizedBox(height: 10),
        _durationPreview(),
        if (_validation != null)
          _LifecycleMessage(message: _validation!, urgent: true),
        const SizedBox(height: 16),
        if (session.state == ClinicalSessionState.awaitingConfirmation)
          FilledButton.icon(
            key: const Key('confirm-session-action'),
            onPressed: widget.controller.isBusy || _clinicalDateChanged
                ? null
                : _confirmSession,
            icon: const Icon(Icons.task_alt),
            label: Text(
              _clinicalDateChanged
                  ? 'Move date before confirming'
                  : 'Confirm ${_durationLabel()} Completed Hours',
            ),
          ),
        if (session.state == ClinicalSessionState.awaitingConfirmation &&
            _clinicalDateChanged)
          const _LifecycleMessage(
            message: 'Save the moved date first, then confirm the Session.',
            urgent: false,
          ),
        if (session.state != ClinicalSessionState.cancelled &&
            session.state != ClinicalSessionState.missed) ...[
          OutlinedButton.icon(
            key: const Key('save-lifecycle-times-action'),
            onPressed: widget.controller.isBusy ? null : _saveTimed,
            icon: const Icon(Icons.drive_file_move_outline),
            label: Text(
              session.state == ClinicalSessionState.completed
                  ? 'Reopen and save correction'
                  : 'Move or save planned times',
            ),
          ),
        ],
        if (session.state == ClinicalSessionState.scheduled ||
            session.state == ClinicalSessionState.awaitingConfirmation)
          OutlinedButton(
            key: const Key('cancel-session-action'),
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.cancelClinicalSession,
            child: const Text('Cancel Session'),
          ),
        if (session.state == ClinicalSessionState.awaitingConfirmation)
          OutlinedButton(
            key: const Key('missed-session-action'),
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.markClinicalSessionMissed,
            child: const Text('Mark Missed'),
          ),
        _DeleteAction(onPressed: () => _confirmDelete(context)),
      ],
    );
  }

  Widget _timedEditor(
    BuildContext context, {
    required Widget summary,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required VoidCallback onDelete,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      summary,
      const SizedBox(height: 14),
      _dateField(),
      const SizedBox(height: 10),
      _timeFields(),
      const SizedBox(height: 10),
      _durationPreview(),
      if (_validation != null)
        _LifecycleMessage(message: _validation!, urgent: true),
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('save-lifecycle-times-action'),
        onPressed: widget.controller.isBusy ? null : onPrimary,
        icon: const Icon(Icons.drive_file_move_outline),
        label: Text(primaryLabel),
      ),
      _DeleteAction(onPressed: onDelete),
    ],
  );

  Widget _protectedDayEditor(BuildContext context, ProtectedDay day) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SummaryPanel(
        icon: Icons.shield_moon_outlined,
        title: formatUsDate(day.date),
        lines: const [
          'Protected Day',
          'Blocked for rest and preparation for this calendar week.',
        ],
        tone: context.clinicalColors.protectedDayAccent,
      ),
      const SizedBox(height: 14),
      _dateField(label: 'Move to date'),
      const SizedBox(height: 10),
      const Text(
        'The destination must be empty and remain in this Protected Dayâ€™s '
        'calendar week.',
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        key: const Key('move-protected-day-action'),
        onPressed: widget.controller.isBusy ? null : _moveProtectedDay,
        icon: const Icon(Icons.move_to_inbox_outlined),
        label: const Text('Move Protected Day'),
      ),
      OutlinedButton.icon(
        key: const Key('remove-protected-day-action'),
        onPressed: widget.controller.isBusy
            ? null
            : () => _confirmRemoveProtectedDay(context),
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Remove Protected Day'),
      ),
      if (widget.controller.missingProtectedDayWeeks != null)
        _LifecycleMessage(
          key: const Key('planning-status'),
          message: widget.controller.planningIncomplete
              ? 'Planning Incomplete: '
                    '${widget.controller.missingProtectedDayWeeks} displayed '
                    'week(s) still need a Protected Day.'
              : 'Planning complete for the displayed month.',
          urgent: widget.controller.planningIncomplete,
        ),
    ],
  );

  Widget _dateField({String label = 'Commitment date'}) => TextField(
    key: const Key('lifecycle-date-field'),
    controller: _date,
    enabled: !widget.controller.isBusy,
    readOnly: true,
    onTap: widget.controller.isBusy ? null : _pickDate,
    decoration: InputDecoration(
      labelText: label,
      hintText: 'MM-DD-YYYY',
      helperText: 'Changing the date moves the entry without replacing it.',
      suffixIcon: const Icon(Icons.calendar_today_outlined),
    ),
  );

  Future<void> _pickDate() async {
    LocalDate? initialDate;
    try {
      initialDate = parseUsDate(_date.text);
    } on Object {
      initialDate = null;
    }
    final selected = await pickUsDate(context, initialDate: initialDate);
    if (!mounted || selected == null) return;
    setState(() => _date.text = formatUsDate(selected));
  }

  Widget _timeFields() => LayoutBuilder(
    builder: (context, constraints) {
      final fields = [
        TextField(
          key: const Key('lifecycle-start-field'),
          controller: _start,
          enabled: !widget.controller.isBusy,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Start time',
            hintText: widget.twelveHourTime ? '8:00 AM' : '0800 or 08:00',
          ),
        ),
        TextField(
          key: const Key('lifecycle-end-field'),
          controller: _end,
          enabled: !widget.controller.isBusy,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'End time',
            hintText: widget.twelveHourTime ? '4:00 PM' : '1600 or 16:00',
          ),
        ),
      ];
      if (constraints.maxWidth < 480) {
        return Column(
          children: [fields.first, const SizedBox(height: 10), fields.last],
        );
      }
      return Row(
        children: [
          Expanded(child: fields.first),
          const SizedBox(width: 12),
          Expanded(child: fields.last),
        ],
      );
    },
  );

  Widget _durationPreview() => _LifecycleMessage(
    key: const Key('calculated-duration'),
    message: 'Automatically calculated Â· ${_durationLabel()}',
    urgent: false,
  );

  String _durationLabel() {
    try {
      final minutes = widget.controller.draftDurationMinutes(
        date: parseCommitmentDate(_date.text),
        startTime: parseFlexibleCommitmentTime(_start.text),
        endTime: parseFlexibleCommitmentTime(_end.text),
      );
      final hours = minutes ~/ 60;
      final remainder = minutes % 60;
      return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
    } on Object {
      return 'Enter valid times';
    }
  }

  Future<void> _saveTimed() async {
    try {
      setState(() => _validation = null);
      await widget.controller.moveOrCorrect(
        date: parseCommitmentDate(_date.text),
        startTime: parseFlexibleCommitmentTime(_start.text),
        endTime: parseFlexibleCommitmentTime(_end.text),
      );
    } on Object catch (error) {
      setState(() => _validation = error.toString());
    }
  }

  Future<void> _confirmSession() async {
    try {
      setState(() => _validation = null);
      await widget.controller.confirmClinicalSession(
        actualStartTime: parseFlexibleCommitmentTime(_start.text),
        actualEndTime: parseFlexibleCommitmentTime(_end.text),
        preceptorId: _preceptorId!,
      );
    } on Object catch (error) {
      setState(() => _validation = error.toString());
    }
  }

  bool get _clinicalDateChanged {
    final snapshot = widget.snapshot;
    if (snapshot is! ClinicalSessionLifecycleSnapshot) return false;
    try {
      return parseCommitmentDate(_date.text) !=
          snapshot.record.value.plannedInterval.startDate;
    } on Object {
      return true;
    }
  }

  Future<void> _moveProtectedDay() async {
    try {
      setState(() => _validation = null);
      await widget.controller.moveProtectedDay(parseCommitmentDate(_date.text));
    } on Object catch (error) {
      setState(() => _validation = error.toString());
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    var reason = ErroneousDeletionReason.erroneous;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Permanently delete erroneous entry?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Use permanent delete only for an erroneous or duplicate '
                'entry. It does not replace Cancel Session or Mark Missed, '
                'which preserve Clinical Session history.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ErroneousDeletionReason>(
                key: const Key('deletion-reason-field'),
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(
                    value: ErroneousDeletionReason.erroneous,
                    child: Text('Erroneous entry'),
                  ),
                  DropdownMenuItem(
                    value: ErroneousDeletionReason.duplicate,
                    child: Text('Duplicate entry'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => reason = value ?? reason),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep entry'),
            ),
            FilledButton(
              key: const Key('confirm-permanent-delete-action'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Permanently delete'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await widget.controller.deleteErroneousEntry(reason);
    widget.onDeleted?.call();
  }

  Future<void> _confirmRemoveProtectedDay(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Protected Day?'),
        content: const Text(
          'This calendar week will become Planning Incomplete until another '
          'Protected Day is selected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep day'),
          ),
          FilledButton(
            key: const Key('confirm-remove-protected-day-action'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.controller.removeProtectedDay();
    widget.onDeleted?.call();
  }

  Widget _workSummary(WorkShift shift) => _SummaryPanel(
    icon: Icons.work_outline,
    title: formatUsDate(shift.plannedInterval.startDate),
    lines: [
      _range(shift.plannedInterval),
      'Scheduled Â· ${_minutesLabel(shift.plannedMinutes)}',
    ],
    tone: context.clinicalColors.workMachinery,
  );

  String _range(ZonedInterval interval) {
    final start = widget.twelveHourTime
        ? interval.startTime.twelveHour
        : interval.startTime.military;
    final end = widget.twelveHourTime
        ? interval.endTime.twelveHour
        : interval.endTime.military;
    return '$startâ€“$end${interval.isOvernight ? ' next day' : ''}';
  }
}

final class _ClinicalSummary extends StatelessWidget {
  const _ClinicalSummary({required this.snapshot});

  final ClinicalSessionLifecycleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final session = snapshot.record.value;
    return _SummaryPanel(
      icon: Icons.medical_services_outlined,
      title: formatUsDate(session.plannedInterval.startDate),
      lines: [
        '${snapshot.clinicalPlacementName} Â· '
            '${snapshot.selectedPreceptor.name}',
        _clinicalStateLabel(session.state),
        'Planned ${_minutesLabel(session.plannedMinutes)}',
        if (session.actualInterval != null)
          'Actual ${session.actualInterval!.startTime.military}â€“'
              '${session.actualInterval!.endTime.military} Â· '
              '${_minutesLabel(session.completedMinutes)}',
      ],
      tone: session.state == ClinicalSessionState.awaitingConfirmation
          ? context.clinicalColors.urgent
          : context.clinicalColors.clinical,
    );
  }
}

final class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.icon,
    required this.title,
    required this.lines,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final Color tone;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.clinicalColors.structureRaised,
      border: Border(left: BorderSide(color: tone, width: 4)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                for (final line in lines) Text(line),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _LifecycleMessage extends StatelessWidget {
  const _LifecycleMessage({
    required this.message,
    required this.urgent,
    super.key,
  });

  final String message;
  final bool urgent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: context.clinicalColors.structureRaised,
      border: Border.all(
        color: urgent
            ? context.clinicalColors.urgent
            : context.clinicalColors.insetBorder,
      ),
    ),
    child: Text(message),
  );
}

final class _DeleteAction extends StatelessWidget {
  const _DeleteAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const Key('delete-erroneous-entry-action'),
    onPressed: onPressed,
    icon: Icon(
      Icons.delete_forever_outlined,
      color: context.clinicalColors.urgent,
    ),
    label: const Text('Delete erroneous or duplicate entry'),
  );
}

String _clinicalStateLabel(ClinicalSessionState state) => switch (state) {
  ClinicalSessionState.scheduled => 'Scheduled',
  ClinicalSessionState.awaitingConfirmation => 'Awaiting Confirmation',
  ClinicalSessionState.completed => 'Completed',
  ClinicalSessionState.cancelled => 'Cancelled',
  ClinicalSessionState.missed => 'Missed',
};

String _minutesLabel(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
}
