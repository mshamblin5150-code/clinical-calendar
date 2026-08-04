import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../responsive_shell.dart';
import '../variant_f_theme.dart';
import 'evaluation_attention_controller.dart';

final class EvaluationPlanSurface extends StatelessWidget {
  const EvaluationPlanSurface({required this.controller, super.key});

  final EvaluationAttentionController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final snapshot = controller.snapshot;
      if (snapshot == null && controller.isBusy) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot == null) {
        return _LoadFailure(controller: controller);
      }
      final placement = controller.selectedPlacement;
      return ListView(
        key: const Key('evaluation-plan-surface'),
        padding: const EdgeInsets.all(12),
        children: [
          if (controller.error != null) ...[
            _ErrorBanner(
              message: 'The Evaluation Plan action could not be completed.',
            ),
            const SizedBox(height: 10),
          ],
          _PlacementSelector(controller: controller),
          const SizedBox(height: 12),
          if (placement == null)
            const ShellPanel(
              label: 'Evaluation Plan',
              child: Text('Add a Clinical Placement to configure evaluations.'),
            )
          else ...[
            _ConfigurationEditor(
              key: ValueKey(
                '${placement.placement.id}|${placement.evaluationPlanRevision}',
              ),
              controller: controller,
              placement: placement,
            ),
            const SizedBox(height: 12),
            _EvaluationChecklist(controller: controller, placement: placement),
          ],
        ],
      );
    },
  );
}

final class _PlacementSelector extends StatelessWidget {
  const _PlacementSelector({required this.controller});

  final EvaluationAttentionController controller;

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Clinical Placement',
    accent: context.clinicalColors.clinical,
    child: DropdownButtonFormField<String>(
      key: const Key('evaluation-placement-selector'),
      isExpanded: true,
      initialValue: controller.selectedPlacementId,
      decoration: const InputDecoration(labelText: 'Clinical Placement'),
      items: [
        for (final placement in controller.snapshot!.placements)
          DropdownMenuItem(
            value: placement.placement.id,
            child: Text(placement.placement.name),
          ),
      ],
      onChanged: controller.isBusy
          ? null
          : (value) {
              if (value != null) controller.selectPlacement(value);
            },
    ),
  );
}

final class _ConfigurationEditor extends StatefulWidget {
  const _ConfigurationEditor({
    required this.controller,
    required this.placement,
    super.key,
  });

  final EvaluationAttentionController controller;
  final PlacementSnapshot placement;

  @override
  State<_ConfigurationEditor> createState() => _ConfigurationEditorState();
}

final class _ConfigurationEditorState extends State<_ConfigurationEditor> {
  late bool _initial;
  late bool _finalSelf;
  late bool _finalPlacement;
  late final TextEditingController _cadence;

  @override
  void initState() {
    super.initState();
    final configuration = widget.placement.evaluationPlanConfiguration;
    _initial = configuration.initialSelfAssessmentRequired;
    _finalSelf = configuration.finalSelfAssessmentRequired;
    _finalPlacement = configuration.finalPlacementReviewRequired;
    _cadence = TextEditingController(
      text: '${configuration.interimReviewCadenceMinutes ~/ 60}',
    );
  }

  @override
  void dispose() {
    _cadence.dispose();
    super.dispose();
  }

  EvaluationPlanConfiguration? get _configuration {
    final hours = int.tryParse(_cadence.text.trim());
    if (hours == null || hours <= 0) return null;
    return EvaluationPlanConfiguration(
      initialSelfAssessmentRequired: _initial,
      interimReviewCadenceMinutes: hours * 60,
      finalSelfAssessmentRequired: _finalSelf,
      finalPlacementReviewRequired: _finalPlacement,
    );
  }

  Future<void> _preview() async {
    final configuration = _configuration;
    if (configuration == null) return;
    await widget.controller.previewConfiguration(configuration);
    if (!mounted) return;
    final preview = widget.controller.configurationPreview;
    if (preview == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Evaluation Plan changes'),
        content: Text(
          preview.evaluationPlanImpact?.description ??
              'Review the generated Evaluation requirements before saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-evaluation-plan-action'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Evaluation Plan'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.confirmConfiguration();
  }

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Evaluation Plan configuration',
    accent: context.clinicalColors.scheduled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Configure each boundary evaluation independently. Interim Review '
          'thresholds use combined Completed Hours across all Preceptors.',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('interim-cadence-hours'),
          controller: _cadence,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Interim Review cadence (Completed Hours)',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        _requiredSwitch(
          key: const Key('initial-self-assessment-required'),
          title: 'Initial Self-Assessment',
          value: _initial,
          onChanged: (value) => setState(() => _initial = value),
        ),
        _requiredSwitch(
          key: const Key('final-self-assessment-required'),
          title: 'Final Self-Assessment',
          value: _finalSelf,
          onChanged: (value) => setState(() => _finalSelf = value),
        ),
        _requiredSwitch(
          key: const Key('final-placement-review-required'),
          title: 'Final Placement Review',
          value: _finalPlacement,
          onChanged: (value) => setState(() => _finalPlacement = value),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('preview-evaluation-plan-action'),
          onPressed: widget.controller.isBusy || _configuration == null
              ? null
              : _preview,
          icon: const Icon(Icons.preview_outlined),
          label: const Text('Preview Evaluation Plan changes'),
        ),
      ],
    ),
  );

  Widget _requiredSwitch({
    required Key key,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Material(
    color: Colors.transparent,
    child: SwitchListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value ? 'Required' : 'Not required'),
      value: value,
      onChanged: onChanged,
    ),
  );
}

final class _EvaluationChecklist extends StatelessWidget {
  const _EvaluationChecklist({
    required this.controller,
    required this.placement,
  });

  final EvaluationAttentionController controller;
  final PlacementSnapshot placement;

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Evaluation checklist',
    accent: context.clinicalColors.clinical,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final evaluated in placement.evaluation.requirements) ...[
          _RequirementRow(
            evaluated: evaluated,
            onDocument: controller.isBusy
                ? null
                : () => _showDocumentationDialog(
                    context,
                    controller,
                    evaluated.requirement,
                  ),
          ),
          const SizedBox(height: 8),
        ],
        const Text(
          'Documentation records where the evaluation was completed. No '
          'evaluation document, credentials, or patient information is uploaded.',
        ),
      ],
    ),
  );
}

final class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.evaluated, required this.onDocument});

  final EvaluatedEvaluationRequirement evaluated;
  final VoidCallback? onDocument;

  @override
  Widget build(BuildContext context) {
    final requirement = evaluated.requirement;
    final documentation = requirement.documentation;
    final state = evaluated.state;
    return Container(
      key: Key('evaluation-requirement-${requirement.identity.stableValue}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.clinicalColors.structureRaised,
        border: Border.all(color: _stateColor(context, state)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                _requirementLabel(requirement.identity),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Chip(
                key: Key(
                  'evaluation-state-${requirement.identity.stableValue}',
                ),
                label: Text(_stateLabel(state)),
                side: BorderSide(color: _stateColor(context, state)),
              ),
            ],
          ),
          if (requirement.thresholdMinutes != null)
            Text(
              'Threshold · ${_hours(requirement.thresholdMinutes!)} Completed Hours',
            ),
          if (documentation != null)
            Text(
              'Documented ${documentation.dateDocumented} · '
              '${documentation.location}'
              '${documentation.referenceOrNote == null ? '' : ' · ${documentation.referenceOrNote}'}',
            ),
          if (!requirement.isDocumented) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onDocument,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Document evaluation'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showDocumentationDialog(
  BuildContext context,
  EvaluationAttentionController controller,
  EvaluationRequirement requirement,
) async {
  final documentation = await showDialog<EvaluationDocumentation>(
    context: context,
    builder: (context) => _DocumentationDialog(requirement: requirement),
  );
  if (documentation == null) return;
  await controller.documentRequirement(
    identity: requirement.identity,
    documentation: documentation,
  );
}

class _DocumentationDialog extends StatefulWidget {
  const _DocumentationDialog({required this.requirement});

  final EvaluationRequirement requirement;

  @override
  State<_DocumentationDialog> createState() => _DocumentationDialogState();
}

class _DocumentationDialogState extends State<_DocumentationDialog> {
  late final TextEditingController _date;
  late final TextEditingController _location;
  late final TextEditingController _note;
  String? _validation;

  @override
  void initState() {
    super.initState();
    _date = TextEditingController(text: _todayText());
    _location = TextEditingController(
      text: EvaluationDocumentation.defaultLocation,
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _date.dispose();
    _location.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Document ${_requirementLabel(widget.requirement.identity)}'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('evaluation-documented-date'),
            controller: _date,
            decoration: const InputDecoration(
              labelText: 'Date documented',
              hintText: 'YYYY-MM-DD',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('evaluation-documentation-location'),
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('evaluation-external-reference'),
            controller: _note,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'External record reference (no patient information)',
              hintText: 'Letters, numbers, and . / : # - only',
            ),
          ),
          if (_validation != null)
            Text(
              _validation!,
              style: TextStyle(color: context.clinicalColors.urgent),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('save-evaluation-documentation-action'),
        onPressed: _save,
        child: const Text('Save documentation'),
      ),
    ],
  );

  void _save() {
    final reference = _note.text.trim();
    if (reference.isNotEmpty && !_externalReference.hasMatch(reference)) {
      setState(
        () => _validation =
            'Use a short external record reference only. Do not enter patient '
            'information or clinical documentation.',
      );
      return;
    }
    try {
      Navigator.pop(
        context,
        EvaluationDocumentation(
          dateDocumented: _parseDate(_date.text),
          location: _location.text,
          referenceOrNote: reference.isEmpty ? null : reference,
        ),
      );
    } on Object {
      setState(
        () => _validation = 'Enter a valid non-future date and location.',
      );
    }
  }

  static final _externalReference = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._:/#-]{0,79}$',
  );
}

final class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.controller});

  final EvaluationAttentionController controller;

  @override
  Widget build(BuildContext context) => Center(
    child: OutlinedButton(
      onPressed: controller.load,
      child: const Text('Retry Evaluation Plan'),
    ),
  );
}

final class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Material(
    color: context.clinicalColors.urgent.withValues(alpha: .15),
    child: Padding(padding: const EdgeInsets.all(10), child: Text(message)),
  );
}

String _requirementLabel(EvaluationRequirementIdentity identity) {
  final threshold = identity.thresholdMinutes;
  final suffix = threshold == null ? '' : ' at ${_hours(threshold)} hours';
  return switch (identity.kind) {
    EvaluationRequirementKind.initialSelfAssessment =>
      'Initial Self-Assessment',
    EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor =>
      'Interim Review · Student reviews Primary Preceptor$suffix',
    EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
      'Interim Review · Primary Preceptor reviews Student$suffix',
    EvaluationRequirementKind.finalSelfAssessment => 'Final Self-Assessment',
    EvaluationRequirementKind.finalPlacementReview => 'Final Placement Review',
  };
}

String _stateLabel(EvaluationRequirementState state) => switch (state) {
  EvaluationRequirementState.notDue => 'Not Due',
  EvaluationRequirementState.approaching => 'Approaching',
  EvaluationRequirementState.due => 'Due',
  EvaluationRequirementState.documented => 'Documented',
};

Color _stateColor(BuildContext context, EvaluationRequirementState state) =>
    switch (state) {
      EvaluationRequirementState.notDue => context.clinicalColors.secondaryText,
      EvaluationRequirementState.approaching =>
        context.clinicalColors.scheduled,
      EvaluationRequirementState.due => context.clinicalColors.urgent,
      EvaluationRequirementState.documented => context.clinicalColors.clinical,
    };

String _hours(int minutes) =>
    minutes % 60 == 0 ? '${minutes ~/ 60}' : (minutes / 60).toStringAsFixed(2);

String _todayText() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

LocalDate _parseDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) throw const FormatException('Invalid date.');
  return LocalDate(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}
