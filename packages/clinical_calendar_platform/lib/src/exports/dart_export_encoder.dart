import 'dart:convert';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class PlacementCsvSchema {
  static const version = 1;

  /// Stable union columns. Empty fields are not applicable to that row type.
  static const columns = <String>[
    'schema_version',
    'record_type',
    'record_id',
    'clinical_placement_id',
    'clinical_placement_name',
    'preceptor_id',
    'preceptor_name',
    'primary_preceptor',
    'start_date',
    'end_date',
    'start_time',
    'end_time',
    'time_zone',
    'start_offset_minutes',
    'end_offset_minutes',
    'duration_minutes',
    'status',
    'target_minutes',
    'completed_minutes',
    'scheduled_minutes',
    'awaiting_confirmation_minutes',
    'remaining_minutes',
    'unscheduled_minutes',
    'over_target_minutes',
    'effective_date',
    'evaluation_kind',
    'evaluation_threshold_minutes',
    'evaluation_currently_required',
    'evaluation_documented_date',
    'evaluation_documentation_location',
    'note',
  ];
}

final class DartExportEncoder implements ExportEncoder {
  const DartExportEncoder();

  @override
  Future<ExportArtifact> encodePlacementPdf(
    PlacementExportSnapshot snapshot,
  ) async {
    final regularFontData = await rootBundle.load(
      'packages/clinical_calendar_platform/assets/fonts/'
      'LiberationSansNarrow-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'packages/clinical_calendar_platform/assets/fonts/'
      'LiberationSansNarrow-Bold.ttf',
    );
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(regularFontData),
      bold: pw.Font.ttf(boldFontData),
    );
    final document = pw.Document(
      title: '${snapshot.placement.placement.name} Clinical Placement report',
      author: 'Clinical Calendar',
      creator: 'Clinical Calendar',
    );
    final colors = _PdfColors();
    document.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: colors.border)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CLINICAL CALENDAR',
                style: pw.TextStyle(
                  color: colors.green,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text('CLINICAL PLACEMENT REPORT'),
            ],
          ),
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated ${snapshot.generatedAtUtc.toIso8601String()}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
        build: (context) => _pdfSections(snapshot, colors),
      ),
    );
    return ExportArtifact(
      format: ExportFormat.placementPdf,
      suggestedFileName:
          'clinical-placement-report-${snapshot.placement.placement.id}.pdf',
      mimeType: 'application/pdf',
      bytes: await document.save(),
    );
  }

  @override
  Future<ExportArtifact> encodePlacementCsv(
    PlacementExportSnapshot snapshot,
  ) async {
    final output = StringBuffer()
      ..writeln(PlacementCsvSchema.columns.map(_csv).join(','));
    for (final row in _csvRows(snapshot)) {
      output.writeln(
        PlacementCsvSchema.columns.map((column) => _csv(row[column])).join(','),
      );
    }
    return ExportArtifact(
      format: ExportFormat.placementCsv,
      suggestedFileName:
          'clinical-placement-${snapshot.placement.placement.id}.csv',
      mimeType: 'text/csv',
      bytes: utf8.encode(output.toString()),
    );
  }

  @override
  Future<ExportArtifact> encodeCompleteJson(
    PortableExportSnapshot snapshot,
  ) async => ExportArtifact(
    format: ExportFormat.completeJson,
    suggestedFileName:
        'clinical-calendar-export-v${snapshot.schemaVersion}.json',
    mimeType: 'application/json',
    bytes: utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(snapshot.document)}\n',
    ),
  );
}

List<pw.Widget> _pdfSections(
  PlacementExportSnapshot export,
  _PdfColors colors,
) {
  final snapshot = export.placement;
  final placement = snapshot.placement;
  final progress = snapshot.progress;
  final preceptors = {
    for (final item in snapshot.attachedPreceptors)
      item.preceptor.id: item.preceptor,
  };
  final evaluationStates = {
    for (final item in snapshot.evaluation.requirements)
      item.requirement.identity.stableValue: item.state,
  };
  return [
    pw.SizedBox(height: 18),
    pw.Text(
      placement.name,
      style: pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: colors.ink,
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Text(
      '${_displayDate(placement.startDate)} to '
      '${_displayDate(placement.completionDeadline)}  |  '
      '${_minutes(placement.targetHours.minutes)} Target Hours',
      style: pw.TextStyle(color: colors.muted),
    ),
    pw.SizedBox(height: 16),
    pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metric('Completed', progress.completedMinutes, colors.green),
        _metric('Scheduled', progress.scheduledMinutes, colors.ochre),
        _metric('Remaining', progress.remainingMinutes, colors.silver),
        _metric('Over-Target', progress.overTargetMinutes, colors.red),
      ],
    ),
    _heading('SESSION LEDGER', colors),
    if (export.sessions.isEmpty)
      _empty('No Clinical Sessions recorded.')
    else
      _table(
        headers: const [
          'Date',
          'Time',
          'Preceptor',
          'Status',
          'Exact duration',
        ],
        rows: [
          for (final record in export.sessions)
            _sessionPdfRow(record.value, preceptors),
        ],
        widths: const {
          0: pw.FlexColumnWidth(1.15),
          1: pw.FlexColumnWidth(1.45),
          2: pw.FlexColumnWidth(1.4),
          3: pw.FlexColumnWidth(1.35),
          4: pw.FlexColumnWidth(1.05),
        },
      ),
    _heading('HISTORICAL HOURS', colors),
    if (export.historicalHours.isEmpty)
      _empty('No Historical Hours Entries recorded.')
    else
      _table(
        headers: const [
          'Effective date',
          'Preceptor',
          'Exact duration',
          'Note',
        ],
        rows: [
          for (final record in export.historicalHours)
            [
              _displayDate(record.value.effectiveDate),
              record.value.preceptorId == null
                  ? 'Unattributed'
                  : preceptors[record.value.preceptorId]?.name ?? 'Preceptor',
              _minutes(record.value.completedMinutes),
              record.value.note ?? '',
            ],
        ],
      ),
    _heading('PRECEPTOR BREAKDOWN', colors),
    _table(
      headers: const [
        'Preceptor',
        'Role',
        'Completed',
        'Scheduled',
        'Awaiting',
      ],
      rows: [
        for (final item in snapshot.attachedPreceptors)
          [
            item.preceptor.name,
            item.isPrimary ? 'Primary Preceptor' : 'Attached',
            _minutes(
              progress.preceptorProgress[item.preceptor.id]!.completedMinutes,
            ),
            _minutes(
              progress.preceptorProgress[item.preceptor.id]!.scheduledMinutes,
            ),
            _minutes(
              progress
                  .preceptorProgress[item.preceptor.id]!
                  .awaitingConfirmationMinutes,
            ),
          ],
        if (progress.unattributedProgress.completedMinutes > 0)
          [
            'Unattributed',
            'Historical Hours',
            _minutes(progress.unattributedProgress.completedMinutes),
            '0 min',
            '0 min',
          ],
      ],
    ),
    _heading('EVALUATION PLAN STATUS', colors),
    if (export.evaluationPlan.value.requirements.isEmpty)
      _empty('No Evaluation requirements configured.')
    else
      _table(
        headers: const ['Requirement', 'Threshold', 'Status', 'Documentation'],
        rows: [
          for (final requirement in export.evaluationPlan.value.requirements)
            [
              _evaluationKind(requirement.identity.kind),
              requirement.thresholdMinutes == null
                  ? 'Boundary'
                  : _minutes(requirement.thresholdMinutes!),
              _titleCase(
                evaluationStates[requirement.identity.stableValue]?.name ??
                    (requirement.isDocumented ? 'documented' : 'notDue'),
              ),
              requirement.documentation == null
                  ? 'Not documented'
                  : '${_displayDate(requirement.documentation!.dateDocumented)} - '
                        '${requirement.documentation!.location}',
            ],
        ],
      ),
  ];
}

pw.Widget _heading(String text, _PdfColors colors) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 20, bottom: 7),
  padding: const pw.EdgeInsets.only(bottom: 4),
  decoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: colors.green, width: 1.5)),
  ),
  child: pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: .8,
      color: colors.ink,
    ),
  ),
);

pw.Widget _metric(String label, int minutes, PdfColor accent) => pw.Container(
  width: 118,
  padding: const pw.EdgeInsets.all(9),
  decoration: pw.BoxDecoration(
    color: const PdfColor.fromInt(0xfff2f4f2),
    border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      pw.SizedBox(height: 3),
      pw.Text(
        _minutes(minutes),
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    ],
  ),
);

pw.Widget _empty(String message) => pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.all(10),
  color: const PdfColor.fromInt(0xfff5f5f5),
  child: pw.Text(message, style: const pw.TextStyle(color: PdfColors.grey700)),
);

pw.Widget _table({
  required List<String> headers,
  required List<List<String>> rows,
  Map<int, pw.TableColumnWidth>? widths,
}) => pw.TableHelper.fromTextArray(
  headers: headers,
  data: rows,
  columnWidths: widths,
  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xff23352b)),
  headerStyle: pw.TextStyle(
    color: PdfColors.white,
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
  ),
  cellStyle: const pw.TextStyle(fontSize: 7.5),
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
  border: pw.TableBorder.all(color: const PdfColor.fromInt(0xffc9ceca)),
  oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xfff5f7f5)),
);

List<String> _sessionPdfRow(
  ClinicalSession session,
  Map<String, Preceptor> preceptors,
) {
  final interval = session.state == ClinicalSessionState.completed
      ? session.actualInterval!
      : session.plannedInterval;
  return [
    _displayDate(interval.startDate),
    '${interval.startTime.military}-${interval.endTime.military}'
        '${interval.isOvernight ? ' next day' : ''}',
    preceptors[session.preceptorId]?.name ?? 'Preceptor',
    _titleCase(session.state.name),
    _minutes(
      session.state == ClinicalSessionState.completed
          ? session.completedMinutes
          : session.plannedMinutes,
    ),
  ];
}

List<Map<String, Object?>> _csvRows(PlacementExportSnapshot export) {
  final placement = export.placement.placement;
  final progress = export.placement.progress;
  final preceptors = {
    for (final item in export.placement.attachedPreceptors)
      item.preceptor.id: item,
  };
  final evaluationStates = {
    for (final item in export.placement.evaluation.requirements)
      item.requirement.identity.stableValue: item.state.name,
  };
  Map<String, Object?> base(String type, String id) => {
    'schema_version': PlacementCsvSchema.version,
    'record_type': type,
    'record_id': id,
    'clinical_placement_id': placement.id,
    'clinical_placement_name': placement.name,
  };
  return [
    {
      ...base('placement_summary', placement.id),
      'start_date': placement.startDate,
      'end_date': placement.completionDeadline,
      'status': export.placement.derivedState.name,
      'target_minutes': placement.targetHours.minutes,
      'completed_minutes': progress.completedMinutes,
      'scheduled_minutes': progress.scheduledMinutes,
      'awaiting_confirmation_minutes': progress.awaitingConfirmationMinutes,
      'remaining_minutes': progress.remainingMinutes,
      'unscheduled_minutes': progress.unscheduledMinutes,
      'over_target_minutes': progress.overTargetMinutes,
    },
    for (final record in export.sessions)
      _sessionCsvRow(record.value, base, preceptors),
    for (final record in export.historicalHours)
      {
        ...base('historical_hours', record.value.id),
        'preceptor_id': record.value.preceptorId,
        'preceptor_name': record.value.preceptorId == null
            ? 'Unattributed'
            : preceptors[record.value.preceptorId]?.preceptor.name,
        'duration_minutes': record.value.completedMinutes,
        'status': 'completed',
        'effective_date': record.value.effectiveDate,
        'note': record.value.note,
      },
    for (final item in export.placement.attachedPreceptors)
      {
        ...base('preceptor_summary', item.preceptor.id),
        'preceptor_id': item.preceptor.id,
        'preceptor_name': item.preceptor.name,
        'primary_preceptor': item.isPrimary,
        'completed_minutes':
            progress.preceptorProgress[item.preceptor.id]!.completedMinutes,
        'scheduled_minutes':
            progress.preceptorProgress[item.preceptor.id]!.scheduledMinutes,
        'awaiting_confirmation_minutes': progress
            .preceptorProgress[item.preceptor.id]!
            .awaitingConfirmationMinutes,
      },
    if (progress.unattributedProgress.completedMinutes > 0)
      {
        ...base('preceptor_summary', '${placement.id}:unattributed'),
        'preceptor_name': 'Unattributed',
        'completed_minutes': progress.unattributedProgress.completedMinutes,
      },
    for (final requirement in export.evaluationPlan.value.requirements)
      {
        ...base('evaluation_requirement', requirement.identity.stableValue),
        'preceptor_id': requirement.primaryPreceptorId,
        'preceptor_name': requirement.primaryPreceptorId == null
            ? null
            : preceptors[requirement.primaryPreceptorId]?.preceptor.name,
        'status': evaluationStates[requirement.identity.stableValue],
        'evaluation_kind': requirement.identity.kind.name,
        'evaluation_threshold_minutes': requirement.thresholdMinutes,
        'evaluation_currently_required': requirement.isCurrentlyRequired,
        'evaluation_documented_date': requirement.documentation?.dateDocumented,
        'evaluation_documentation_location':
            requirement.documentation?.location,
        'note': requirement.documentation?.referenceOrNote,
      },
  ];
}

Map<String, Object?> _sessionCsvRow(
  ClinicalSession session,
  Map<String, Object?> Function(String type, String id) base,
  Map<String, PlacementPreceptorSnapshot> preceptors,
) {
  final planned = session.plannedInterval;
  final actual = session.actualInterval;
  final effective = actual ?? planned;
  return {
    ...base('clinical_session', session.id),
    'preceptor_id': session.preceptorId,
    'preceptor_name': preceptors[session.preceptorId]?.preceptor.name,
    'primary_preceptor': preceptors[session.preceptorId]?.isPrimary,
    'start_date': effective.startDate,
    'end_date': effective.endDate,
    'start_time': effective.startTime.military,
    'end_time': effective.endTime.military,
    'time_zone': effective.timeZone.value,
    'start_offset_minutes': effective.startOffset.minutes,
    'end_offset_minutes': effective.endOffset.minutes,
    'duration_minutes': effective.elapsedMinutes,
    'status': session.state.name,
    'note': actual == null
        ? 'planned interval'
        : 'confirmed actual interval; planned '
              '${planned.startDate} ${planned.startTime.military}-'
              '${planned.endTime.military}, ${planned.elapsedMinutes} minutes',
  };
}

String _csv(Object? value) {
  if (value == null) return '';
  final raw = value.toString();
  final text = value is String && _spreadsheetFormulaPrefix.hasMatch(raw)
      ? "'$raw"
      : raw;
  if (!text.contains(RegExp('[,"\\r\\n]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}

final _spreadsheetFormulaPrefix = RegExp(r'^[\t\r\n ]*[=+\-@]');

String _displayDate(LocalDate value) =>
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}-'
    '${value.year.toString().padLeft(4, '0')}';

String _minutes(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '$remainder min';
  if (remainder == 0) return '$hours hr';
  return '$hours hr $remainder min';
}

String _evaluationKind(EvaluationRequirementKind kind) => switch (kind) {
  EvaluationRequirementKind.initialSelfAssessment => 'Initial Self-Assessment',
  EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor =>
    'Student reviews Primary Preceptor',
  EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
    'Primary Preceptor reviews Student',
  EvaluationRequirementKind.finalSelfAssessment => 'Final Self-Assessment',
  EvaluationRequirementKind.finalPlacementReview => 'Final Placement Review',
};

String _titleCase(String value) => value
    .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
    .trim()
    .split(' ')
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

final class _PdfColors {
  final ink = const PdfColor.fromInt(0xff18221c);
  final muted = const PdfColor.fromInt(0xff5f6962);
  final border = const PdfColor.fromInt(0xff8c9890);
  final green = const PdfColor.fromInt(0xff4f7c43);
  final ochre = const PdfColor.fromInt(0xffa47e26);
  final silver = const PdfColor.fromInt(0xff7d8982);
  final red = const PdfColor.fromInt(0xffa84840);
}
