import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';
import '../time_input.dart';
import '../variant_f_theme.dart';
import 'batch_scheduling_controller.dart';

final class StagedBatchSchedulingTray extends StatelessWidget {
  const StagedBatchSchedulingTray({required this.controller, super.key});

  final BatchSchedulingController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final colors = context.clinicalColors;
      final metrics = context.clinicalMetrics;
      return Container(
        key: const Key('batch-scheduling-tray'),
        decoration: BoxDecoration(
          color: colors.structure,
          border: Border.all(
            color: colors.insetBorder,
            width: metrics.borderWidth,
          ),
          borderRadius: BorderRadius.circular(metrics.cornerRadius),
        ),
        padding: EdgeInsets.all(metrics.standardSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _StageHeader(stage: controller.stage),
            SizedBox(height: metrics.standardSpacing),
            switch (controller.stage) {
              BatchSchedulingStage.typeAndTime => _TypeAndTimeStage(
                controller: controller,
              ),
              BatchSchedulingStage.assignment => _AssignmentStage(
                controller: controller,
              ),
              BatchSchedulingStage.review => _ReviewStage(
                controller: controller,
              ),
            },
            if (controller.inputError != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.inputError!,
                key: const Key('batch-input-error'),
                style: TextStyle(color: colors.urgent),
              ),
            ],
            if (controller.status != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(controller.status!, key: const Key('batch-status')),
              ),
            ],
            const SizedBox(height: 16),
            _TrayActions(controller: controller),
            if (controller.busy) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(key: Key('batch-progress')),
            ],
          ],
        ),
      );
    },
  );
}

final class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.stage});

  final BatchSchedulingStage stage;

  @override
  Widget build(BuildContext context) {
    final step = stage.index + 1;
    final label = switch (stage) {
      BatchSchedulingStage.typeAndTime => 'TYPE & TIME',
      BatchSchedulingStage.assignment => 'PLACEMENT & PRECEPTOR',
      BatchSchedulingStage.review => 'REVIEW BATCH',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.clinicalColors.clinical),
          ),
          child: Text('$step'),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

final class _TypeAndTimeStage extends StatelessWidget {
  const _TypeAndTimeStage({required this.controller});

  final BatchSchedulingController controller;

  @override
  Widget build(BuildContext context) {
    final touch = context.clinicalMetrics.minimumTouchTarget;
    final templates = controller.templates
        .where(
          (template) => switch (controller.type) {
            BatchCommitmentType.workShift =>
              template.type == ScheduleTemplateType.workShift,
            BatchCommitmentType.clinicalSession =>
              template.type == ScheduleTemplateType.clinicalSession,
            BatchCommitmentType.protectedDay => false,
          },
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${controller.selectedDates.length} selected '
          '${controller.selectedDates.length == 1 ? 'date' : 'dates'}',
          key: const Key('selected-date-count'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in BatchCommitmentType.values)
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: touch),
                child: ChoiceChip(
                  key: Key('batch-type-${value.name}'),
                  label: Text(_typeLabel(value)),
                  selected: controller.type == value,
                  onSelected: (_) => controller.setType(value),
                ),
              ),
          ],
        ),
        if (controller.type != BatchCommitmentType.protectedDay) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            key: const Key('batch-template'),
            isExpanded: true,
            initialValue: controller.selectedTemplateId,
            decoration: const InputDecoration(labelText: 'Schedule Template'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Enter times manually'),
              ),
              for (final template in templates)
                DropdownMenuItem(
                  value: template.id,
                  child: Text(template.name),
                ),
            ],
            onChanged: controller.chooseTemplate,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 430;
              final fields = [
                _TimeInput(
                  key: ValueKey(
                    'start-${controller.selectedTemplateId}-'
                    '${controller.useTwelveHourTime}',
                  ),
                  label: 'Start',
                  value: controller.startTime ?? LocalTime(8, 0),
                  twelveHour: controller.useTwelveHourTime,
                  onChanged: controller.chooseStartTime,
                ),
                _TimeInput(
                  key: ValueKey(
                    'end-${controller.selectedTemplateId}-'
                    '${controller.useTwelveHourTime}',
                  ),
                  label: 'End',
                  value: controller.endTime ?? LocalTime(16, 0),
                  twelveHour: controller.useTwelveHourTime,
                  onChanged: controller.chooseEndTime,
                ),
              ];
              return compact
                  ? Column(
                      children: [
                        fields.first,
                        const SizedBox(height: 12),
                        fields.last,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: fields.first),
                        const SizedBox(width: 12),
                        Expanded(child: fields.last),
                      ],
                    );
            },
          ),
          const SizedBox(height: 12),
          InputDecorator(
            key: const Key('batch-duration'),
            decoration: const InputDecoration(labelText: 'Calculated duration'),
            child: Text(
              controller.durationVaries
                  ? 'Varies by date; review exact durations'
                  : _duration(controller.durationMinutes),
            ),
          ),
        ],
      ],
    );
  }
}

final class _TimeInput extends StatelessWidget {
  const _TimeInput({
    required this.label,
    required this.value,
    required this.twelveHour,
    required this.onChanged,
    super.key,
  });

  final String label;
  final LocalTime value;
  final bool twelveHour;
  final ValueChanged<LocalTime> onChanged;

  @override
  Widget build(BuildContext context) => ClinicalTimePickerField(
    label: label,
    value: value,
    twelveHour: twelveHour,
    onChanged: onChanged,
  );
}

final class _AssignmentStage extends StatelessWidget {
  const _AssignmentStage({required this.controller});

  final BatchSchedulingController controller;

  @override
  Widget build(BuildContext context) {
    final placement = controller.selectedPlacement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('batch-placement'),
          isExpanded: true,
          initialValue: controller.clinicalPlacementId,
          decoration: const InputDecoration(labelText: 'Clinical Placement'),
          items: [
            for (final item in controller.placements)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: controller.choosePlacement,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('batch-preceptor-${placement?.id}'),
          isExpanded: true,
          initialValue: controller.preceptorId,
          decoration: const InputDecoration(labelText: 'Preceptor'),
          items: [
            for (final item in placement?.preceptors ?? const [])
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: controller.choosePreceptor,
        ),
      ],
    );
  }
}

final class _ReviewStage extends StatelessWidget {
  const _ReviewStage({required this.controller});

  final BatchSchedulingController controller;

  @override
  Widget build(BuildContext context) {
    final review = controller.review;
    if (review == null) {
      if (controller.selectedDates.isEmpty) {
        return const Text(
          'No dates remain in this batch. Go Back to select another date.',
        );
      }
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Preparing review...')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in review.items)
          Container(
            key: Key('batch-review-${item.date}'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.clinicalColors.structureRaised,
              border: Border.all(
                color: item.valid
                    ? context.clinicalColors.insetBorder
                    : context.clinicalColors.urgent,
              ),
              borderRadius: BorderRadius.circular(
                context.clinicalMetrics.cornerRadius,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatUsDate(item.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_reviewSummary(controller, item)),
                      for (final conflict in item.conflicts)
                        Text(
                          _conflictLabel(conflict),
                          style: TextStyle(
                            color: context.clinicalColors.urgent,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('remove-batch-date-${item.date}'),
                  constraints: BoxConstraints.tightFor(
                    width: context.clinicalMetrics.minimumTouchTarget,
                    height: context.clinicalMetrics.minimumTouchTarget,
                  ),
                  tooltip: 'Remove ${formatUsDate(item.date)}',
                  onPressed: () => controller.removeDate(item.date),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _TrayActions extends StatelessWidget {
  const _TrayActions({required this.controller});

  final BatchSchedulingController controller;

  @override
  Widget build(BuildContext context) {
    final touch = context.clinicalMetrics.minimumTouchTarget;
    return Row(
      children: [
        if (controller.stage != BatchSchedulingStage.typeAndTime)
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: touch),
            child: OutlinedButton.icon(
              key: const Key('batch-back'),
              onPressed: controller.busy ? null : controller.back,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ),
        const Spacer(),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: touch),
          child: FilledButton.icon(
            key: Key(
              controller.stage == BatchSchedulingStage.review
                  ? 'batch-apply'
                  : 'batch-next',
            ),
            onPressed: controller.busy
                ? null
                : controller.stage == BatchSchedulingStage.review
                ? (controller.review?.canApply == true && !controller.applied
                      ? controller.apply
                      : null)
                : controller.next,
            icon: Icon(
              controller.stage == BatchSchedulingStage.review
                  ? Icons.check
                  : Icons.arrow_forward,
            ),
            label: Text(
              controller.stage == BatchSchedulingStage.review
                  ? 'Apply batch'
                  : 'Next',
            ),
          ),
        ),
      ],
    );
  }
}

String _typeLabel(BatchCommitmentType type) => switch (type) {
  BatchCommitmentType.workShift => 'Work Shift',
  BatchCommitmentType.clinicalSession => 'Clinical Session',
  BatchCommitmentType.protectedDay => 'Protected Day',
};

String _duration(int? minutes) {
  if (minutes == null) return 'Enter a valid start and end time';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '$hours hr';
  return '$hours hr $remainder min';
}

String _reviewSummary(
  BatchSchedulingController controller,
  BatchSchedulingReviewItem item,
) {
  final duration = item.durationMinutes == null
      ? 'All day'
      : _duration(item.durationMinutes);
  if (controller.type != BatchCommitmentType.clinicalSession) return duration;
  final placement = controller.selectedPlacement;
  final preceptor = placement?.preceptors
      .where((value) => value.id == controller.preceptorId)
      .firstOrNull;
  return '$duration · ${placement?.name ?? 'No Clinical Placement'} · '
      '${preceptor?.name ?? 'No Preceptor'}';
}

String _conflictLabel(SchedulingError error) => switch (error.violation) {
  ScheduleInvariantViolation.commitmentOverlap =>
    'Schedule Conflict: overlaps an existing commitment on '
        '${formatUsDate(error.conflictDate)}.',
  ScheduleInvariantViolation.commitmentTouchesProtectedDay =>
    'Schedule Conflict: touches the Protected Day on '
        '${formatUsDate(error.conflictDate)}.',
  ScheduleInvariantViolation.multipleProtectedDaysInWeek =>
    'Schedule Conflict: that week already has a Protected Day.',
};
