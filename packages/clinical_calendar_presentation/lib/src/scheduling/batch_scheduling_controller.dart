import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/foundation.dart';

enum BatchSchedulingStage { typeAndTime, assignment, review }

final class BatchSchedulingController extends ChangeNotifier {
  BatchSchedulingController({
    required this.operations,
    required this.studentId,
    required Iterable<BatchClinicalPlacementOption> placements,
    required Iterable<ScheduleTemplate> templates,
    required Iterable<ZonedScheduleDate> selectedDates,
    required this.useTwelveHourTime,
    String? activeClinicalPlacementId,
    BatchSchedulingReset reset = BatchSchedulingReset.addSchedule,
  }) : placements = List.unmodifiable(placements),
       templates = List.unmodifiable(templates),
       _dates = List.of(selectedDates) {
    _reset(reset, activeClinicalPlacementId: activeClinicalPlacementId);
  }

  final BatchSchedulingOperations operations;
  final String studentId;
  final List<BatchClinicalPlacementOption> placements;
  final List<ScheduleTemplate> templates;
  final bool useTwelveHourTime;

  final List<ZonedScheduleDate> _dates;
  BatchSchedulingStage stage = BatchSchedulingStage.typeAndTime;
  BatchCommitmentType type = BatchCommitmentType.clinicalSession;
  LocalTime? startTime;
  LocalTime? endTime;
  String startInput = '08:00';
  String endInput = '16:00';
  String startPeriod = 'AM';
  String endPeriod = 'PM';
  String? clinicalPlacementId;
  String? preceptorId;
  String? selectedTemplateId;
  String? inputError;
  String? status;
  BatchSchedulingReview? review;
  bool busy = false;
  bool applied = false;

  List<ZonedScheduleDate> get selectedDates => List.unmodifiable(_dates);

  BatchClinicalPlacementOption? get selectedPlacement {
    for (final placement in placements) {
      if (placement.id == clinicalPlacementId) return placement;
    }
    return null;
  }

  int? get durationMinutes {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null || start == end) return null;
    final exact = _exactDurations(start, end);
    if (exact.length == 1) return exact.single;
    if (exact.length > 1) return null;
    var duration = end.minutesSinceMidnight - start.minutesSinceMidnight;
    if (duration < 0) duration += 24 * 60;
    return duration;
  }

  bool get durationVaries {
    final start = startTime;
    final end = endTime;
    return start != null &&
        end != null &&
        start != end &&
        _exactDurations(start, end).length > 1;
  }

  Set<int> _exactDurations(LocalTime start, LocalTime end) => {
    for (final date in _dates)
      date.interval(startTime: start, endTime: end).elapsedMinutes,
  };

  void reset(BatchSchedulingReset intent, {String? activeClinicalPlacementId}) {
    _reset(intent, activeClinicalPlacementId: activeClinicalPlacementId);
    notifyListeners();
  }

  void _reset(
    BatchSchedulingReset intent, {
    String? activeClinicalPlacementId,
  }) {
    stage = BatchSchedulingStage.typeAndTime;
    type = intent == BatchSchedulingReset.planningIncomplete
        ? BatchCommitmentType.protectedDay
        : BatchCommitmentType.clinicalSession;
    startTime = LocalTime(8, 0);
    endTime = LocalTime(16, 0);
    startInput = useTwelveHourTime ? '8:00' : '08:00';
    endInput = useTwelveHourTime ? '4:00' : '16:00';
    startPeriod = 'AM';
    endPeriod = 'PM';
    selectedTemplateId = null;
    inputError = null;
    status = null;
    review = null;
    busy = false;
    applied = false;
    _defaultClinicalAssignment(activeClinicalPlacementId);
    if (type != BatchCommitmentType.clinicalSession) {
      clinicalPlacementId = null;
      preceptorId = null;
    }
  }

  void setType(BatchCommitmentType value) {
    type = value;
    selectedTemplateId = null;
    inputError = null;
    review = null;
    status = null;
    applied = false;
    if (value == BatchCommitmentType.clinicalSession) {
      if (clinicalPlacementId == null) _defaultClinicalAssignment(null);
    } else {
      clinicalPlacementId = null;
      preceptorId = null;
    }
    notifyListeners();
  }

  void setStartInput(String value) {
    startInput = value;
    _parseTimeInputs(notify: true);
  }

  void setEndInput(String value) {
    endInput = value;
    _parseTimeInputs(notify: true);
  }

  void setStartPeriod(String value) {
    startPeriod = value;
    _parseTimeInputs(notify: true);
  }

  void setEndPeriod(String value) {
    endPeriod = value;
    _parseTimeInputs(notify: true);
  }

  void chooseTemplate(String? templateId) {
    selectedTemplateId = templateId;
    if (templateId == null) {
      applied = false;
      notifyListeners();
      return;
    }
    final template = templates.firstWhere((value) => value.id == templateId);
    type = switch (template.type) {
      ScheduleTemplateType.workShift => BatchCommitmentType.workShift,
      ScheduleTemplateType.clinicalSession =>
        BatchCommitmentType.clinicalSession,
    };
    startTime = template.startTime;
    endTime = template.endTime;
    _syncTimeInputs();
    if (type == BatchCommitmentType.clinicalSession) {
      if (template.clinicalPlacementId != null &&
          placements.any(
            (placement) => placement.id == template.clinicalPlacementId,
          )) {
        clinicalPlacementId = template.clinicalPlacementId;
        preceptorId = template.preceptorId;
      } else if (clinicalPlacementId == null) {
        _defaultClinicalAssignment(null);
      }
    } else {
      clinicalPlacementId = null;
      preceptorId = null;
    }
    inputError = null;
    review = null;
    applied = false;
    notifyListeners();
  }

  void choosePlacement(String? placementId) {
    clinicalPlacementId = placementId;
    final placement = selectedPlacement;
    preceptorId = placement?.primaryPreceptorId;
    review = null;
    applied = false;
    notifyListeners();
  }

  void choosePreceptor(String? value) {
    preceptorId = value;
    review = null;
    applied = false;
    notifyListeners();
  }

  void toggleDate(ZonedScheduleDate date) {
    final index = _dates.indexWhere((value) => value.date == date.date);
    if (index >= 0) {
      _dates.removeAt(index);
    } else {
      _dates.add(date);
      _dates.sort((left, right) => left.date.compareTo(right.date));
    }
    review = null;
    status = null;
    applied = false;
    notifyListeners();
  }

  Future<void> removeDate(LocalDate date) async {
    _dates.removeWhere((value) => value.date == date);
    status = null;
    applied = false;
    if (stage == BatchSchedulingStage.review && _dates.isNotEmpty) {
      await _loadReview();
    } else {
      review = null;
      notifyListeners();
    }
  }

  Future<void> next() async {
    inputError = null;
    status = null;
    if (stage == BatchSchedulingStage.typeAndTime) {
      if (_dates.isEmpty) {
        inputError = 'Select at least one calendar date.';
      } else if (type != BatchCommitmentType.protectedDay &&
          !_parseTimeInputs()) {
        // Parsing supplies the message.
      } else if (type == BatchCommitmentType.clinicalSession) {
        stage = BatchSchedulingStage.assignment;
      } else {
        stage = BatchSchedulingStage.review;
        await _loadReview();
        return;
      }
      notifyListeners();
      return;
    }
    if (stage == BatchSchedulingStage.assignment) {
      if (clinicalPlacementId == null || preceptorId == null) {
        inputError = 'Choose a Clinical Placement and attached Preceptor.';
        notifyListeners();
        return;
      }
      stage = BatchSchedulingStage.review;
      await _loadReview();
    }
  }

  void back() {
    inputError = null;
    status = null;
    stage = switch (stage) {
      BatchSchedulingStage.typeAndTime => BatchSchedulingStage.typeAndTime,
      BatchSchedulingStage.assignment => BatchSchedulingStage.typeAndTime,
      BatchSchedulingStage.review =>
        type == BatchCommitmentType.clinicalSession
            ? BatchSchedulingStage.assignment
            : BatchSchedulingStage.typeAndTime,
    };
    notifyListeners();
  }

  Future<void> apply() async {
    if (busy || applied || review?.canApply != true) return;
    busy = true;
    inputError = null;
    status = null;
    notifyListeners();
    try {
      final result = await operations.apply(_draft());
      if (result.applied) {
        applied = true;
        status =
            '${result.persistedCount} schedule '
            '${result.persistedCount == 1 ? 'item' : 'items'} saved.';
      } else {
        status = 'The batch was not saved. Correct or remove every conflict.';
        review = _reviewWithConflicts(result.conflicts);
      }
    } on Object {
      status = 'The batch was not saved. Your staged entries are unchanged.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _loadReview() async {
    busy = true;
    notifyListeners();
    try {
      review = await operations.review(_draft());
    } on Object {
      inputError = 'The batch could not be reviewed. Check its assignments.';
      review = null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  BatchSchedulingDraft _draft() => BatchSchedulingDraft(
    studentId: studentId,
    type: type,
    dates: _dates,
    startTime: startTime,
    endTime: endTime,
    clinicalPlacementId: clinicalPlacementId,
    preceptorId: preceptorId,
  );

  BatchSchedulingReview _reviewWithConflicts(List<SchedulingError> conflicts) =>
      BatchSchedulingReview(
        items: [
          for (var index = 0; index < _dates.length; index++)
            BatchSchedulingReviewItem(
              date: _dates[index].date,
              durationMinutes: type == BatchCommitmentType.protectedDay
                  ? null
                  : _draft().intervals[index].elapsedMinutes,
              conflicts: conflicts.where(
                (error) => error.proposedDate == _dates[index].date,
              ),
            ),
        ],
      );

  bool _parseTimeInputs({bool notify = false}) {
    try {
      startTime = useTwelveHourTime
          ? _parseTwelveHour(startInput, startPeriod)
          : LocalTime.parseMilitary(startInput);
      endTime = useTwelveHourTime
          ? _parseTwelveHour(endInput, endPeriod)
          : LocalTime.parseMilitary(endInput);
      if (startTime == endTime) {
        throw const DomainValidationException(
          'Start and end time must be different.',
        );
      }
      inputError = null;
      review = null;
      applied = false;
      if (notify) notifyListeners();
      return true;
    } on DomainValidationException catch (error) {
      inputError = error.message;
      startTime = null;
      endTime = null;
      if (notify) notifyListeners();
      return false;
    }
  }

  void _syncTimeInputs() {
    final start = startTime!;
    final end = endTime!;
    if (useTwelveHourTime) {
      startInput = _twelveHourInput(start);
      endInput = _twelveHourInput(end);
      startPeriod = start.hour < 12 ? 'AM' : 'PM';
      endPeriod = end.hour < 12 ? 'AM' : 'PM';
    } else {
      startInput = start.military;
      endInput = end.military;
    }
  }

  void _defaultClinicalAssignment(String? activeId) {
    BatchClinicalPlacementOption? selected;
    for (final placement in placements) {
      if (placement.id == activeId) selected = placement;
    }
    selected ??= placements.isEmpty ? null : placements.first;
    clinicalPlacementId = selected?.id;
    preceptorId = selected?.primaryPreceptorId;
  }
}

LocalTime _parseTwelveHour(String input, String period) {
  final normalized = input.trim();
  final match = RegExp(r'^(\d{1,2})(?::?(\d{2}))$').firstMatch(normalized);
  if (match == null) {
    throw const DomainValidationException(
      'Time must use H:MM or HHMM with AM or PM.',
    );
  }
  final displayHour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (displayHour < 1 || displayHour > 12 || minute > 59) {
    throw const DomainValidationException('Enter a valid 12-hour time.');
  }
  final hour = (displayHour % 12) + (period == 'PM' ? 12 : 0);
  return LocalTime(hour, minute);
}

String _twelveHourInput(LocalTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  return '$hour:${value.minute.toString().padLeft(2, '0')}';
}
