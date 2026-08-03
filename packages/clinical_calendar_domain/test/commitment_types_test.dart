import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test('constructs Work Shift and Protected Day with validated identity', () {
    final interval = _interval(LocalDate(2026, 8, 3), '0800', '1600');
    final shift = WorkShift(id: 'work-1', plannedInterval: interval);
    final protectedDay = ProtectedDay(
      id: 'protected-1',
      date: LocalDate(2026, 8, 4),
    );

    expect(shift.plannedMinutes, 480);
    expect(protectedDay.date, LocalDate(2026, 8, 4));
    expect(
      () => WorkShift(id: ' ', plannedInterval: interval),
      throwsA(isA<DomainValidationException>()),
    );
  });

  group('ScheduleTemplate', () {
    test('supports date-free overnight Clinical Session defaults', () {
      final template = ScheduleTemplate(
        id: 'template-1',
        name: ' Night clinical ',
        type: ScheduleTemplateType.clinicalSession,
        startTime: LocalTime.parseMilitary('1900'),
        endTime: LocalTime.parseMilitary('0700'),
        clinicalPlacementId: 'placement-1',
        preceptorId: 'preceptor-1',
      );

      expect(template.name, 'Night clinical');
      expect(template.isOvernight, isTrue);
    });

    test('rejects partial or Work Shift placement assignment', () {
      expect(
        () => ScheduleTemplate(
          id: 'template-1',
          name: 'Invalid',
          type: ScheduleTemplateType.clinicalSession,
          startTime: LocalTime.parseMilitary('0800'),
          endTime: LocalTime.parseMilitary('1600'),
          clinicalPlacementId: 'placement-1',
        ),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => ScheduleTemplate(
          id: 'template-2',
          name: 'Invalid work',
          type: ScheduleTemplateType.workShift,
          startTime: LocalTime.parseMilitary('0800'),
          endTime: LocalTime.parseMilitary('1600'),
          clinicalPlacementId: 'placement-1',
          preceptorId: 'preceptor-1',
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });
}

ZonedInterval _interval(LocalDate date, String start, String end) =>
    ZonedInterval(
      startDate: date,
      startTime: LocalTime.parseMilitary(start),
      endTime: LocalTime.parseMilitary(end),
      timeZone: TimeZoneId('America/New_York'),
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-240),
    );
