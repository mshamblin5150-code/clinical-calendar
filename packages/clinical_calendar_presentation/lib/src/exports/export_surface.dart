import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

import '../variant_f_theme.dart';

final class ExportSurface extends StatefulWidget {
  const ExportSurface({
    required this.workflow,
    required this.clinicalPlacementId,
    super.key,
  });

  final ExportWorkflowService workflow;
  final String clinicalPlacementId;

  @override
  State<ExportSurface> createState() => _ExportSurfaceState();
}

final class _ExportSurfaceState extends State<ExportSurface> {
  bool _busy = false;
  String? _status;

  Future<void> _run(Future<ExportOutcome> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final outcome = await action();
      if (!mounted) return;
      setState(() {
        _status = switch (outcome) {
          ExportOutcome.saved => 'Export saved.',
          ExportOutcome.cancelled => 'Export cancelled.',
          ExportOutcome.authenticationFailed =>
            'Reauthentication was not completed. Nothing was exported.',
        };
      });
    } on Object {
      if (!mounted) return;
      setState(() => _status = 'Export could not be completed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCompleteJson() async {
    final acknowledged = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('complete-json-privacy-warning'),
        backgroundColor: context.clinicalColors.structureRaised,
        title: const Text('Complete data export'),
        content: const Text(
          'This unencrypted JSON file contains your complete portable '
          'Clinical Calendar data, including schedule details, Clinical '
          'Placements, Preceptors, evaluation documentation, settings, and '
          'profile information. Store it privately. You must reauthenticate '
          'before choosing where to save it.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-json-export'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('acknowledge-json-privacy'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I understand - continue'),
          ),
        ],
      ),
    );
    if (acknowledged == true) {
      await _run(
        () => widget.workflow.exportCompleteJson(
          privacyWarningAcknowledged: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('export-surface'),
    decoration: BoxDecoration(
      color: context.clinicalColors.structure,
      border: Border.all(color: context.clinicalColors.insetBorder),
      borderRadius: BorderRadius.circular(context.clinicalMetrics.cornerRadius),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('EXPORT', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Create a printable Clinical Placement report, an exact analysis '
          'CSV, or a complete portable JSON export.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('export-placement-pdf'),
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => widget.workflow.exportPlacementPdf(
                        widget.clinicalPlacementId,
                      ),
                    ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Placement PDF'),
            ),
            OutlinedButton.icon(
              key: const Key('export-placement-csv'),
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => widget.workflow.exportPlacementCsv(
                        widget.clinicalPlacementId,
                      ),
                    ),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Advanced CSV'),
            ),
            OutlinedButton.icon(
              key: const Key('export-complete-json'),
              onPressed: _busy ? null : _confirmCompleteJson,
              icon: const Icon(Icons.data_object),
              label: const Text('Complete JSON'),
            ),
          ],
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(key: Key('export-progress')),
        ],
        if (_status != null) ...[
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(_status!)),
        ],
      ],
    ),
  );
}
