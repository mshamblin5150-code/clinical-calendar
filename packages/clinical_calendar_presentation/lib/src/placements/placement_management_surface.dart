import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';
import '../variant_f_theme.dart';
import 'placement_progress_controller.dart';
import 'placement_specialty_icon.dart';

final class PlacementManagementSurface extends StatelessWidget {
  const PlacementManagementSurface({
    required this.controller,
    required this.studentId,
    this.onOpenEvaluations,
    this.unsavedSchedulingDraftCount = 0,
    this.onDiscardUnsavedSchedulingDrafts,
    super.key,
  });

  final PlacementProgressController controller;
  final String studentId;
  final VoidCallback? onOpenEvaluations;
  final int unsavedSchedulingDraftCount;
  final VoidCallback? onDiscardUnsavedSchedulingDrafts;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final editorKey = GlobalObjectKey<_PlacementEditorState>(
          'placement-editor|${controller.activePlacementId}|'
          '${controller.activePlacement?.placementRevision}',
        );
        final navigation = _PlacementManagementNavigation(
          controller: controller,
          onAdd: controller.isBusy ? null : () => _showAddPlacement(context),
          horizontal: !wide,
        );
        final editor = _PlacementEditor(
          key: editorKey,
          controller: controller,
          onOpenEvaluations: onOpenEvaluations,
          unsavedSchedulingDraftCount: unsavedSchedulingDraftCount,
          onDiscardUnsavedSchedulingDrafts: onDiscardUnsavedSchedulingDrafts,
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
                  if (controller.activePlacement != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      key: const Key('move-placement-to-trash-action'),
                      onPressed: controller.isBusy
                          ? null
                          : () =>
                                editorKey.currentState?._showDeletionPreview(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.clinicalColors.urgent,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Move to Trash'),
                    ),
                  ],
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
    LocalDate? start;
    LocalDate? deadline;
    var preceptor = '';
    String? validation;
    final startController = TextEditingController();
    final deadlineController = TextEditingController();
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
                  key: const Key('new-placement-start-date'),
                  controller: startController,
                  readOnly: true,
                  onTap: () async {
                    final selected = await pickUsDate(
                      context,
                      initialDate: start,
                    );
                    if (selected == null) return;
                    setDialogState(() {
                      start = selected;
                      startController.text = formatUsDate(selected);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'MM-DD-YYYY',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                TextField(
                  key: const Key('new-placement-deadline'),
                  controller: deadlineController,
                  readOnly: true,
                  onTap: () async {
                    final selected = await pickUsDate(
                      context,
                      initialDate: deadline ?? start,
                    );
                    if (selected == null) return;
                    setDialogState(() {
                      deadline = selected;
                      deadlineController.text = formatUsDate(selected);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Completion Deadline',
                    hintText: 'MM-DD-YYYY',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
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
                  if (start == null ||
                      deadline == null ||
                      name.trim().isEmpty ||
                      preceptor.trim().isEmpty) {
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
    startController.dispose();
    deadlineController.dispose();
    if (accepted == true) {
      await controller.createPlacementWithPrimary(
        placementName: name,
        targetHours: _targetHours(target),
        startDate: start!,
        completionDeadline: deadline!,
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
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlacementSpecialtyGlyph(
          placementName: snapshot.placement.name,
          size: 20,
          color: selected
              ? context.clinicalColors.clinical
              : context.clinicalColors.secondaryText,
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(snapshot.placement.name)),
      ],
    ),
  );
}

final class _PlacementEditor extends StatefulWidget {
  const _PlacementEditor({
    required this.controller,
    required this.onOpenEvaluations,
    required this.unsavedSchedulingDraftCount,
    required this.onDiscardUnsavedSchedulingDrafts,
    super.key,
  });
  final PlacementProgressController controller;
  final VoidCallback? onOpenEvaluations;
  final int unsavedSchedulingDraftCount;
  final VoidCallback? onDiscardUnsavedSchedulingDrafts;

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
    _start = TextEditingController(
      text: value == null ? '' : formatUsDate(value.placement.startDate),
    );
    _deadline = TextEditingController(
      text: value == null
          ? ''
          : formatUsDate(value.placement.completionDeadline),
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
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final dateFields = [
      TextField(
        key: const Key('placement-start-date-field'),
        controller: _start,
        enabled: !completed,
        readOnly: true,
        onTap: completed ? null : () => _pickInto(_start),
        decoration: const InputDecoration(
          labelText: 'Start Date',
          hintText: 'MM-DD-YYYY',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
      ),
      TextField(
        key: const Key('placement-deadline-field'),
        controller: _deadline,
        enabled: !completed,
        readOnly: true,
        onTap: completed ? null : () => _pickInto(_deadline),
        decoration: const InputDecoration(
          labelText: 'Completion Deadline',
          hintText: 'MM-DD-YYYY',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Target Hours'),
              ),
              const SizedBox(height: 8),
              if (enlargedText)
                ...dateFields.expand(
                  (field) => [field, const SizedBox(height: 8)],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dateFields[0]),
                    const SizedBox(width: 8),
                    Expanded(child: dateFields[1]),
                  ],
                ),
              const SizedBox(height: 16),
              Text(
                'PRECEPTORS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final attached in value.attachedPreceptors)
                _PreceptorEditorRow(
                  key: ValueKey(
                    '${attached.preceptor.id}|${attached.revision}',
                  ),
                  attached: attached,
                  locked: completed || widget.controller.isBusy,
                  onSave: (name) =>
                      widget.controller.editPreceptor(attached, name),
                  onMakePrimary: attached.isPrimary
                      ? null
                      : () => widget.controller.makePrimary(
                          attached.preceptor.id,
                        ),
                  onDetach: attached.isPrimary
                      ? null
                      : () => widget.controller.detachPreceptor(
                          attached.preceptor.id,
                        ),
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
              _ReviewsAndEvaluationsPanel(
                evaluation: value.evaluation,
                onOpen: widget.onOpenEvaluations,
              ),
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
          ),
        ),
      ],
    );
  }

  Future<void> _showDeletionPreview() async {
    await widget.controller.previewDeletion(
      unsavedSchedulingDraftCount: widget.unsavedSchedulingDraftCount,
    );
    if (!mounted) return;
    final preview = widget.controller.deletionPreview;
    if (preview == null) return;
    var typedName = '';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canConfirm =
              !preview.requiresTypedName ||
              typedName == preview.clinicalPlacementName;
          return AlertDialog(
            title: Text('Move ${preview.clinicalPlacementName} to Trash?'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'The complete Clinical Placement aggregate will remain '
                      'recoverable for 30 days.',
                    ),
                    const SizedBox(height: 12),
                    _DeletionImpactLine(
                      label: 'Scheduled Clinical Sessions',
                      value: preview.scheduledClinicalSessionCount,
                    ),
                    _DeletionImpactLine(
                      label: 'Awaiting-confirmation Clinical Sessions',
                      value: preview.awaitingConfirmationClinicalSessionCount,
                    ),
                    _DeletionImpactLine(
                      label: 'Completed Clinical Sessions',
                      value: preview.completedClinicalSessionCount,
                      detail:
                          '${_hoursInput(preview.clinicalSessionCompletedMinutes)} Completed Hours',
                    ),
                    _DeletionImpactLine(
                      label: 'Cancelled Clinical Sessions',
                      value: preview.cancelledClinicalSessionCount,
                    ),
                    _DeletionImpactLine(
                      label: 'Missed Clinical Sessions',
                      value: preview.missedClinicalSessionCount,
                    ),
                    _DeletionImpactLine(
                      label: 'Historical Hours Entries',
                      value: preview.historicalHoursEntryCount,
                      detail:
                          '${_hoursInput(preview.historicalCompletedMinutes)} Completed Hours',
                    ),
                    _DeletionImpactLine(
                      label: 'Evaluation Plan requirements',
                      value: preview.evaluationRequirementCount,
                      detail:
                          '${preview.documentedEvaluationRequirementCount} documented',
                    ),
                    _DeletionImpactLine(
                      label: 'Clinical Session schedule templates',
                      value: preview.scheduleTemplateCount,
                    ),
                    _DeletionImpactLine(
                      label: 'Placement-derived reminders',
                      value: preview.reminderStateCount,
                    ),
                    _DeletionImpactLine(
                      label: 'Attached Preceptor relationships',
                      value: preview.attachedPreceptorRelationshipCount,
                      detail:
                          'preserved for recovery; Preceptors are not deleted',
                    ),
                    _DeletionImpactLine(
                      label: 'Unsaved scheduling drafts',
                      value: preview.unsavedSchedulingDraftCount,
                      detail: 'discarded and not recoverable',
                    ),
                    _DeletionImpactLine(
                      label: 'Active Clinical Placement selection',
                      value: preview.clearsActivePlacementSelection ? 1 : 0,
                      detail: preview.clearsActivePlacementSelection
                          ? 'will be cleared'
                          : 'unchanged',
                    ),
                    if (preview.requiresTypedName) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('completed-placement-name-confirmation'),
                        autofocus: true,
                        onChanged: (value) =>
                            setDialogState(() => typedName = value),
                        decoration: InputDecoration(
                          labelText:
                              'Type ${preview.clinicalPlacementName} to confirm',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const Key('confirm-move-placement-to-trash'),
                onPressed: canConfirm
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Move to Trash'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true) {
      widget.controller.clearDeletionPreview();
      return;
    }
    final deleted = await widget.controller.confirmDeletion(
      completedPlacementName: typedName,
    );
    if (deleted) {
      widget.onDiscardUnsavedSchedulingDrafts?.call();
    }
  }

  Future<void> _preview() async {
    final value = snapshot;
    if (value == null) return;
    try {
      final request = EditPlacementRequest(
        name: _name.text,
        targetHours: _targetHours(_target.text),
        startDate: parseUsDate(_start.text),
        completionDeadline: parseUsDate(_deadline.text),
        evaluationPlanConfiguration: value.evaluationPlanConfiguration,
      );
      setState(() => _validation = null);
      await widget.controller.previewEdit(request);
    } on Object catch (error) {
      setState(() => _validation = error.toString());
    }
  }

  Future<void> _pickInto(TextEditingController controller) async {
    final selected = await pickUsDate(
      context,
      initialDate: parseUsDate(controller.text),
    );
    if (selected == null || !mounted) return;
    setState(() {
      controller.text = formatUsDate(selected);
      _validation = null;
    });
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

final class _DeletionImpactLine extends StatelessWidget {
  const _DeletionImpactLine({
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final int value;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Text('$value'),
        if (detail != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              detail!,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    ),
  );
}

final class _ReviewsAndEvaluationsPanel extends StatelessWidget {
  const _ReviewsAndEvaluationsPanel({
    required this.evaluation,
    required this.onOpen,
  });

  final EvaluationPlanEvaluation evaluation;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('placement-reviews-evaluations'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.clinicalColors.structureRaised,
      border: Border.all(color: context.clinicalColors.insetBorder),
      borderRadius: BorderRadius.circular(context.clinicalMetrics.cornerRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'REVIEWS & EVALUATIONS',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (evaluation.requirements.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No reviews are configured for this placement.'),
          ),
        for (final item in evaluation.requirements)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _evaluationIcon(item.state),
                  size: 18,
                  color: _evaluationColor(context, item.state),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _evaluationLabel(item.requirement.identity),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        _evaluationStatus(item),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _evaluationColor(context, item.state),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (onOpen != null)
          OutlinedButton.icon(
            key: const Key('open-placement-evaluations'),
            onPressed: onOpen,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Open Reviews & Evaluations'),
          ),
      ],
    ),
  );
}

String _evaluationLabel(EvaluationRequirementIdentity identity) {
  final threshold = identity.thresholdMinutes;
  final atHours = threshold == null
      ? ''
      : ' at ${_evaluationHours(threshold)} hours';
  return switch (identity.kind) {
    EvaluationRequirementKind.initialSelfAssessment =>
      'Initial Self-Assessment',
    EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor =>
      'Student Reviews Primary Preceptor$atHours',
    EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
      'Primary Preceptor Reviews Student$atHours',
    EvaluationRequirementKind.finalSelfAssessment => 'Final Self-Assessment',
    EvaluationRequirementKind.finalPlacementReview => 'Final Placement Review',
  };
}

String _evaluationHours(int minutes) =>
    minutes % 60 == 0 ? '${minutes ~/ 60}' : (minutes / 60).toStringAsFixed(1);

String _evaluationStatus(EvaluatedEvaluationRequirement item) {
  final documented = item.requirement.documentation;
  if (documented != null) {
    return 'Documented ${formatUsDate(documented.dateDocumented)}';
  }
  return switch (item.state) {
    EvaluationRequirementState.notDue => 'Not Due',
    EvaluationRequirementState.approaching => 'Approaching',
    EvaluationRequirementState.due => 'Due',
    EvaluationRequirementState.documented => 'Documented',
  };
}

IconData _evaluationIcon(EvaluationRequirementState state) => switch (state) {
  EvaluationRequirementState.notDue => Icons.schedule_outlined,
  EvaluationRequirementState.approaching => Icons.timelapse_outlined,
  EvaluationRequirementState.due => Icons.error_outline,
  EvaluationRequirementState.documented => Icons.task_alt,
};

Color _evaluationColor(
  BuildContext context,
  EvaluationRequirementState state,
) => switch (state) {
  EvaluationRequirementState.notDue => context.clinicalColors.secondaryText,
  EvaluationRequirementState.approaching => context.clinicalColors.scheduled,
  EvaluationRequirementState.due => context.clinicalColors.urgent,
  EvaluationRequirementState.documented => context.clinicalColors.clinical,
};

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
        final compact =
            constraints.maxWidth < 520 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
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

String _hoursInput(int minutes) {
  final value = minutes / 60;
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
