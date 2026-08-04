import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../variant_f_theme.dart';
import 'placement_progress_controller.dart';

final class PlacementManagementSurface extends StatelessWidget {
  const PlacementManagementSurface({
    required this.controller,
    required this.studentId,
    super.key,
  });

  final PlacementProgressController controller;
  final String studentId;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final navigation = _PlacementManagementNavigation(
          controller: controller,
          onAdd: controller.isBusy ? null : () => _showAddPlacement(context),
          horizontal: !wide,
        );
        final editor = _PlacementEditor(
          key: ValueKey(
            '${controller.activePlacementId}|'
            '${controller.activePlacement?.placementRevision}',
          ),
          controller: controller,
        );
        return Container(
          key: const Key('placement-management-surface'),
          color: context.clinicalColors.canvas,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'CLINICAL PLACEMENT MANAGEMENT',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (controller.isBusy)
                    const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const Divider(height: 20),
              if (controller.error != null)
                _ErrorBanner(message: controller.error.toString()),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 220, child: navigation),
                          const VerticalDivider(width: 20),
                          Expanded(child: editor),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          navigation,
                          const Divider(height: 18),
                          Expanded(child: editor),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _showAddPlacement(BuildContext context) async {
    var name = '';
    var target = '90';
    var start = '';
    var deadline = '';
    var preceptor = '';
    String? validation;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Clinical Placement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('new-placement-name'),
                  onChanged: (value) => name = value,
                  decoration: const InputDecoration(
                    labelText: 'Placement name',
                  ),
                ),
                TextFormField(
                  key: const Key('new-placement-target'),
                  initialValue: target,
                  onChanged: (value) => target = value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target Hours'),
                ),
                TextField(
                  onChanged: (value) => start = value,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                TextField(
                  onChanged: (value) => deadline = value,
                  decoration: const InputDecoration(
                    labelText: 'Completion Deadline',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                TextField(
                  onChanged: (value) => preceptor = value,
                  decoration: const InputDecoration(
                    labelText: 'Primary Preceptor',
                  ),
                ),
                if (validation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      validation!,
                      style: TextStyle(color: context.clinicalColors.urgent),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('create-placement-action'),
              onPressed: () {
                try {
                  _targetHours(target);
                  _localDate(start);
                  _localDate(deadline);
                  if (name.trim().isEmpty || preceptor.trim().isEmpty) {
                    throw const FormatException('Required fields are missing.');
                  }
                  Navigator.pop(context, true);
                } on Object catch (error) {
                  setDialogState(() => validation = error.toString());
                }
              },
              child: const Text('Create Placement'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await controller.createPlacementWithPrimary(
        placementName: name,
        targetHours: _targetHours(target),
        startDate: _localDate(start),
        completionDeadline: _localDate(deadline),
        primaryPreceptorName: preceptor,
      );
    }
  }
}

final class _PlacementManagementNavigation extends StatelessWidget {
  const _PlacementManagementNavigation({
    required this.controller,
    required this.onAdd,
    required this.horizontal,
  });

  final PlacementProgressController controller;
  final VoidCallback? onAdd;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final snapshot in controller.placements)
        _PlacementChoice(
          snapshot: snapshot,
          selected: snapshot.placement.id == controller.activePlacementId,
          onPressed: controller.isBusy
              ? null
              : () => controller.selectPlacement(snapshot.placement.id),
        ),
      OutlinedButton.icon(
        key: const Key('add-placement-action'),
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add placement'),
      ),
    ];
    return horizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in items) ...[item, const SizedBox(width: 6)],
              ],
            ),
          )
        : ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, index) => items[index],
          );
  }
}

final class _PlacementChoice extends StatelessWidget {
  const _PlacementChoice({
    required this.snapshot,
    required this.selected,
    required this.onPressed,
  });

  final PlacementSnapshot snapshot;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    key: Key('manage-placement-${snapshot.placement.id}'),
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      backgroundColor: selected ? context.clinicalColors.structureRaised : null,
      side: BorderSide(
        color: selected
            ? context.clinicalColors.clinical
            : context.clinicalColors.insetBorder,
      ),
    ),
    child: Text(
      snapshot.placement.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

final class _PlacementEditor extends StatefulWidget {
  const _PlacementEditor({required this.controller, super.key});
  final PlacementProgressController controller;

  @override
  State<_PlacementEditor> createState() => _PlacementEditorState();
}

final class _PlacementEditorState extends State<_PlacementEditor> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _start;
  late final TextEditingController _deadline;
  String? _validation;

  PlacementSnapshot? get snapshot => widget.controller.activePlacement;

  @override
  void initState() {
    super.initState();
    final value = snapshot;
    _name = TextEditingController(text: value?.placement.name ?? '');
    _target = TextEditingController(
      text: value == null ? '' : _hoursInput(value.progress.targetMinutes),
    );
    _start = TextEditingController(text: value?.placement.startDate.toString());
    _deadline = TextEditingController(
      text: value?.placement.completionDeadline.toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _start.dispose();
    _deadline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = snapshot;
    if (value == null) {
      return const Center(child: Text('Add a Clinical Placement to begin.'));
    }
    final completed = value.placement.state == ClinicalPlacementState.completed;
    return ListView(
      key: const Key('placement-management-editor'),
      children: [
        if (completed)
          _LifecycleBanner(
            label: 'COMPLETED PLACEMENT · ORDINARY EDITING LOCKED',
            color: context.clinicalColors.scheduled,
          )
        else if (value.isReadyToComplete)
          _LifecycleBanner(
            label: 'READY TO COMPLETE',
            color: context.clinicalColors.clinical,
          ),
        TextField(
          key: const Key('placement-name-field'),
          controller: _name,
          enabled: !completed,
          decoration: const InputDecoration(labelText: 'Placement name'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('placement-target-field'),
          controller: _target,
          enabled: !completed,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Target Hours'),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('placement-start-date-field'),
                controller: _start,
                enabled: !completed,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('placement-deadline-field'),
                controller: _deadline,
                enabled: !completed,
                decoration: const InputDecoration(
                  labelText: 'Completion Deadline',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('PRECEPTORS', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final attached in value.attachedPreceptors)
          _PreceptorEditorRow(
            key: ValueKey('${attached.preceptor.id}|${attached.revision}'),
            attached: attached,
            locked: completed || widget.controller.isBusy,
            onSave: (name) => widget.controller.editPreceptor(attached, name),
            onMakePrimary: attached.isPrimary
                ? null
                : () => widget.controller.makePrimary(attached.preceptor.id),
            onDetach: attached.isPrimary
                ? null
                : () =>
                      widget.controller.detachPreceptor(attached.preceptor.id),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('add-preceptor-action'),
            onPressed: completed || widget.controller.isBusy
                ? null
                : () => _showAddPreceptor(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Preceptor'),
          ),
        ),
        Text(
          'Changing the Primary Preceptor preserves Completed Hours, '
          'Over-Target Hours, and documented review history.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_validation != null) _ErrorBanner(message: _validation!),
        const SizedBox(height: 14),
        if (!completed)
          FilledButton.icon(
            key: const Key('preview-placement-edit-action'),
            onPressed: widget.controller.isBusy ? null : _preview,
            icon: const Icon(Icons.manage_search),
            label: const Text('Preview impact'),
          ),
        if (widget.controller.editPreview case final preview?) ...[
          const SizedBox(height: 12),
          _ImpactPreviewPanel(preview: preview),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('confirm-placement-edit-action'),
            onPressed: preview.canConfirm && !widget.controller.isBusy
                ? widget.controller.confirmEdit
                : null,
            child: const Text('Confirm and save changes'),
          ),
        ],
        const SizedBox(height: 16),
        if (completed)
          OutlinedButton.icon(
            key: const Key('reopen-placement-action'),
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.reopenPlacement,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Reopen Placement'),
          )
        else if (value.isReadyToComplete)
          OutlinedButton.icon(
            key: const Key('complete-placement-action'),
            onPressed: widget.controller.isBusy
                ? null
                : widget.controller.completePlacement,
            icon: const Icon(Icons.task_alt),
            label: const Text('Complete Placement'),
          ),
      ],
    );
  }

  Future<void> _preview() async {
    final value = snapshot;
    if (value == null) return;
    try {
      final request = EditPlacementRequest(
        name: _name.text,
        targetHours: _targetHours(_target.text),
        startDate: _localDate(_start.text),
        completionDeadline: _localDate(_deadline.text),
        evaluationPlanConfiguration: value.evaluationPlanConfiguration,
      );
      setState(() => _validation = null);
      await widget.controller.previewEdit(request);
    } on Object catch (error) {
      setState(() => _validation = error.toString());
    }
  }

  Future<void> _showAddPreceptor(BuildContext context) async {
    var name = '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Preceptor'),
        content: TextField(
          key: const Key('new-preceptor-name'),
          onChanged: (value) => name = value,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Preceptor name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-add-preceptor-action'),
            onPressed: () => Navigator.pop(context, name.trim().isNotEmpty),
            child: const Text('Add Preceptor'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await widget.controller.createAndAttachPreceptor(name);
    }
  }
}

final class _PreceptorEditorRow extends StatefulWidget {
  const _PreceptorEditorRow({
    required this.attached,
    required this.locked,
    required this.onSave,
    required this.onMakePrimary,
    required this.onDetach,
    super.key,
  });

  final PlacementPreceptorSnapshot attached;
  final bool locked;
  final ValueChanged<String> onSave;
  final VoidCallback? onMakePrimary;
  final VoidCallback? onDetach;

  @override
  State<_PreceptorEditorRow> createState() => _PreceptorEditorRowState();
}

final class _PreceptorEditorRowState extends State<_PreceptorEditorRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.attached.preceptor.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final actions = <Widget>[
          OutlinedButton(
            onPressed: widget.locked ? null : () => widget.onSave(_name.text),
            child: const Text('Save name'),
          ),
          OutlinedButton(
            onPressed: widget.locked ? null : widget.onMakePrimary,
            child: Text(
              widget.attached.isPrimary ? 'Primary Preceptor' : 'Set Primary',
            ),
          ),
          if (!widget.attached.isPrimary)
            IconButton(
              tooltip: 'Detach ${widget.attached.preceptor.name}',
              onPressed: widget.locked ? null : widget.onDetach,
              icon: const Icon(Icons.delete_outline),
            ),
        ];
        final field = TextField(
          controller: _name,
          enabled: !widget.locked,
          decoration: const InputDecoration(labelText: 'Preceptor name'),
        );
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.clinicalColors.structure,
            border: Border.all(color: context.clinicalColors.insetBorder),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: actions),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 8),
                    ...actions,
                  ],
                ),
        );
      },
    ),
  );
}

final class _ImpactPreviewPanel extends StatelessWidget {
  const _ImpactPreviewPanel({required this.preview});
  final PlacementEditImpactPreview preview;

  @override
  Widget build(BuildContext context) {
    final evaluation = preview.evaluationPlanImpact;
    final proposed = preview.proposedProgress;
    return Container(
      key: const Key('placement-impact-preview'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.clinicalColors.structureRaised,
        border: Border.all(
          color: preview.canConfirm
              ? context.clinicalColors.clinical
              : context.clinicalColors.urgent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            preview.canConfirm ? 'IMPACT PREVIEW' : 'SAVE BLOCKED',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (preview.outOfWindowClinicalSessionIds.isNotEmpty)
            Text(
              '${preview.outOfWindowClinicalSessionIds.length} Clinical '
              'Session(s) fall outside the proposed placement window.',
            ),
          if (proposed != null)
            Text(
              'Target ${_hoursInput(proposed.targetMinutes)} h · '
              '${_hoursInput(proposed.remainingMinutes)} h remaining · '
              '${_hoursInput(proposed.unscheduledMinutes)} h unscheduled',
            ),
          if (evaluation != null)
            Text(
              '${evaluation.addedRequirementIdentities.length} requirement(s) '
              'added · '
              '${evaluation.removedUndocumentedRequirementIdentities.length} '
              'undocumented requirement(s) removed · '
              '${evaluation.preservedDocumentedRequirementIdentities.length} '
              'documented requirement(s) preserved',
            ),
        ],
      ),
    );
  }
}

final class _LifecycleBanner extends StatelessWidget {
  const _LifecycleBanner({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(border: Border.all(color: color)),
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );
}

final class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('placement-error-banner'),
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: context.clinicalColors.urgent),
    ),
    child: Text(message),
  );
}

TargetHours _targetHours(String value) {
  final hours = double.parse(value.trim());
  final minutes = (hours * 60).round();
  return TargetHours.fromMinutes(minutes);
}

LocalDate _localDate(String value) {
  final parts = value.trim().split('-');
  if (parts.length != 3) throw const FormatException('Use YYYY-MM-DD.');
  return LocalDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String _hoursInput(int minutes) {
  final value = minutes / 60;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
