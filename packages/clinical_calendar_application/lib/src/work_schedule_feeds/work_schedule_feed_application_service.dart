import 'dart:convert';

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:crypto/crypto.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

import '../ports.dart';
import '../repositories.dart';

final class WorkScheduleFeedConnectionRequest {
  const WorkScheduleFeedConnectionRequest({
    required this.studentId,
    required this.name,
    required this.url,
    required this.ics,
    required this.studentTimeZone,
  });

  final String studentId;
  final String name;
  final Uri url;
  final String ics;
  final TimeZoneId studentTimeZone;
}

final class WorkScheduleFeedConnectionPreview {
  const WorkScheduleFeedConnectionPreview({
    required this.studentId,
    required this.feed,
    required this.upcomingShifts,
    required this.matchingHandEnteredWorkShiftIds,
    required this.notImported,
  });

  final String studentId;
  final WorkScheduleFeed feed;
  final List<WorkShift> upcomingShifts;
  final List<String> matchingHandEnteredWorkShiftIds;
  final List<WorkScheduleFeedNotImportedEvent> notImported;
}

final class WorkScheduleFeedRefreshRequest {
  const WorkScheduleFeedRefreshRequest({
    required this.studentId,
    required this.feedId,
    required this.ics,
    required this.studentTimeZone,
    this.confirmEmpty = false,
  });

  final String studentId;
  final String feedId;
  final String ics;
  final TimeZoneId studentTimeZone;
  final bool confirmEmpty;
}

enum WorkScheduleFeedRefreshDisposition {
  updated,
  requiresEmptyConfirmation,
  heldTeamFeed,
}

final class WorkScheduleFeedRefreshResult {
  const WorkScheduleFeedRefreshResult({
    required this.disposition,
    required this.feed,
    required this.upcomingShifts,
  });

  final WorkScheduleFeedRefreshDisposition disposition;
  final WorkScheduleFeed feed;
  final List<WorkShift> upcomingShifts;
}

final class WorkScheduleFeedFormatException implements Exception {
  const WorkScheduleFeedFormatException(this.message);

  final String message;

  @override
  String toString() => 'WorkScheduleFeedFormatException: $message';
}

final class WorkScheduleFeedTeamFeedException implements Exception {
  const WorkScheduleFeedTeamFeedException();

  static const message =
      'This looks like a team or department schedule, not your personal one. '
      "Look for a 'my schedule' or 'personal calendar' link, or enter your "
      'shifts by hand.';

  @override
  String toString() => message;
}

/// Deep module for parsing and applying one Student's employer schedule feed.
final class WorkScheduleFeedApplicationService {
  WorkScheduleFeedApplicationService(
    this._repositories,
    this._clock,
    this._identifiers,
  );

  final RepositoryRegistry _repositories;
  final Clock _clock;
  final IdentifierGenerator _identifiers;

  Future<WorkScheduleFeedConnectionPreview> previewConnection(
    WorkScheduleFeedConnectionRequest request,
  ) async {
    final now = _clock.nowUtc();
    final feedId = _identifiers.nextIdentifier();
    final parsed = _parse(
      request.ics,
      feedId: feedId,
      feedName: request.name,
      studentTimeZone: request.studentTimeZone,
      skipWords: WorkScheduleFeed.defaultSkipWords,
      nowUtc: now,
    );
    if (_hasOverlaps(parsed.timedIntervals)) {
      throw const WorkScheduleFeedTeamFeedException();
    }
    final feed = WorkScheduleFeed(
      id: feedId,
      name: request.name,
      url: request.url,
      lastCheckedAtUtc: now,
      lastSuccessfulUpdateAtUtc: now,
      notImported: parsed.notImported,
    );
    return _repositories.read((repositories) {
      final matches = <String>[];
      for (final record in repositories.workShifts.list(
        studentId: request.studentId,
      )) {
        final existing = record.value;
        if (existing.isImported) continue;
        if (parsed.shifts.any(
          (shift) =>
              shift.plannedInterval.startDate ==
                  existing.plannedInterval.startDate &&
              _overlaps(shift.plannedInterval, existing.plannedInterval),
        )) {
          matches.add(existing.id);
        }
      }
      return WorkScheduleFeedConnectionPreview(
        studentId: request.studentId,
        feed: feed,
        upcomingShifts: parsed.shifts,
        matchingHandEnteredWorkShiftIds: List.unmodifiable(matches),
        notImported: parsed.notImported,
      );
    });
  }

  Future<void> confirmConnection(WorkScheduleFeedConnectionPreview preview) =>
      _repositories.mutate((repositories) {
        final feedRepositories = _feedRepositories(repositories);
        final now = _clock.nowUtc();
        feedRepositories.workScheduleFeeds.put(
          studentId: preview.studentId,
          value: preview.feed,
          expectedRevision: 0,
          mutation: _mutation(now),
        );
        for (final id in preview.matchingHandEnteredWorkShiftIds) {
          final current = repositories.workShifts.find(
            studentId: preview.studentId,
            id: id,
          );
          if (current != null && !current.value.isImported) {
            repositories.workShifts.tombstone(
              studentId: preview.studentId,
              id: id,
              expectedRevision: current.revision,
              mutation: _mutation(now),
            );
          }
        }
        for (final shift in preview.upcomingShifts) {
          repositories.workShifts.put(
            studentId: preview.studentId,
            value: shift,
            expectedRevision: 0,
            mutation: _mutation(now),
          );
        }
      });

  Future<WorkScheduleFeedRefreshResult> refresh(
    WorkScheduleFeedRefreshRequest request,
  ) async {
    final feedRecord = await _repositories.read((repositories) {
      final feeds = _feedReadRepositories(repositories);
      final record = feeds.workScheduleFeeds.find(
        studentId: request.studentId,
        id: request.feedId,
      );
      if (record == null) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'Work Schedule Feed was not found.',
        );
      }
      return record;
    });
    final now = _clock.nowUtc();
    final parsed = _parse(
      request.ics,
      feedId: feedRecord.value.id,
      feedName: feedRecord.value.name,
      studentTimeZone: request.studentTimeZone,
      skipWords: feedRecord.value.skipWords,
      nowUtc: now,
    );
    if (_hasOverlaps(parsed.timedIntervals)) {
      return _repositories.mutate((repositories) {
        final feeds = _feedRepositories(repositories);
        final current = feeds.workScheduleFeeds.find(
          studentId: request.studentId,
          id: request.feedId,
        );
        if (current == null) {
          throw const RepositoryException(
            RepositoryFailureKind.notFound,
            'Work Schedule Feed was not found.',
          );
        }
        final held = current.value.copyWith(
          lastCheckedAtUtc: now,
          heldReason: WorkScheduleFeedTeamFeedException.message,
        );
        feeds.workScheduleFeeds.put(
          studentId: request.studentId,
          value: held,
          expectedRevision: current.revision,
          mutation: _mutation(now),
        );
        final shifts = _upcomingFeedShiftRecords(
          repositories,
          studentId: request.studentId,
          feedId: request.feedId,
          nowUtc: now,
        ).map((record) => record.value).toList(growable: false);
        return WorkScheduleFeedRefreshResult(
          disposition: WorkScheduleFeedRefreshDisposition.heldTeamFeed,
          feed: held,
          upcomingShifts: shifts,
        );
      });
    }
    if (parsed.shifts.isEmpty && !request.confirmEmpty) {
      final hasUpcoming = await _repositories.read(
        (repositories) => _upcomingFeedShiftRecords(
          repositories,
          studentId: request.studentId,
          feedId: request.feedId,
          nowUtc: now,
        ).isNotEmpty,
      );
      if (hasUpcoming) {
        return _repositories.mutate((repositories) {
          final feeds = _feedRepositories(repositories);
          final current = feeds.workScheduleFeeds.find(
            studentId: request.studentId,
            id: request.feedId,
          )!;
          final checked = current.value.copyWith(lastCheckedAtUtc: now);
          feeds.workScheduleFeeds.put(
            studentId: request.studentId,
            value: checked,
            expectedRevision: current.revision,
            mutation: _mutation(now),
          );
          final existing = _upcomingFeedShiftRecords(
            repositories,
            studentId: request.studentId,
            feedId: request.feedId,
            nowUtc: now,
          ).map((record) => record.value).toList(growable: false);
          return WorkScheduleFeedRefreshResult(
            disposition:
                WorkScheduleFeedRefreshDisposition.requiresEmptyConfirmation,
            feed: checked,
            upcomingShifts: existing,
          );
        });
      }
    }

    return _repositories.mutate((repositories) {
      final feeds = _feedRepositories(repositories);
      final currentFeed = feeds.workScheduleFeeds.find(
        studentId: request.studentId,
        id: request.feedId,
      );
      if (currentFeed == null) {
        throw const RepositoryException(
          RepositoryFailureKind.notFound,
          'Work Schedule Feed was not found.',
        );
      }
      final unmatched = _upcomingFeedShiftRecords(
        repositories,
        studentId: request.studentId,
        feedId: request.feedId,
        nowUtc: now,
      ).toList();
      final applied = <WorkShift>[];
      for (final candidate in parsed.shifts) {
        StoredDomainRecord<WorkShift>? match;
        for (final record in unmatched) {
          if (record.value.sourceEventUid == candidate.sourceEventUid) {
            match = record;
            break;
          }
        }
        for (final record in unmatched) {
          if (match == null &&
              _sameInstantRange(
                record.value.plannedInterval,
                candidate.plannedInterval,
              )) {
            match = record;
            break;
          }
        }
        final value = match == null
            ? candidate
            : WorkShift.imported(
                id: match.value.id,
                plannedInterval: candidate.plannedInterval,
                workScheduleFeedId: currentFeed.value.id,
                workScheduleFeedName: currentFeed.value.name,
                sourceEventUid: candidate.sourceEventUid,
              );
        if (match != null) unmatched.remove(match);
        repositories.workShifts.put(
          studentId: request.studentId,
          value: value,
          expectedRevision: match?.revision ?? 0,
          mutation: _mutation(now),
        );
        applied.add(value);
      }
      for (final removed in unmatched) {
        repositories.workShifts.tombstone(
          studentId: request.studentId,
          id: removed.value.id,
          expectedRevision: removed.revision,
          mutation: _mutation(now),
        );
      }
      final updatedFeed = currentFeed.value.copyWith(
        lastCheckedAtUtc: now,
        lastSuccessfulUpdateAtUtc: now,
        notImported: parsed.notImported,
        clearHeldReason: true,
      );
      feeds.workScheduleFeeds.put(
        studentId: request.studentId,
        value: updatedFeed,
        expectedRevision: currentFeed.revision,
        mutation: _mutation(now),
      );
      return WorkScheduleFeedRefreshResult(
        disposition: WorkScheduleFeedRefreshDisposition.updated,
        feed: updatedFeed,
        upcomingShifts: List.unmodifiable(applied),
      );
    });
  }

  Future<void> disconnect({
    required String studentId,
    required String feedId,
  }) => _repositories.mutate((repositories) {
    final feeds = _feedRepositories(repositories);
    final feed = feeds.workScheduleFeeds.find(studentId: studentId, id: feedId);
    if (feed == null) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'Work Schedule Feed was not found.',
      );
    }
    final now = _clock.nowUtc();
    for (final record in _upcomingFeedShiftRecords(
      repositories,
      studentId: studentId,
      feedId: feedId,
      nowUtc: now,
    )) {
      repositories.workShifts.tombstone(
        studentId: studentId,
        id: record.value.id,
        expectedRevision: record.revision,
        mutation: _mutation(now),
      );
    }
    feeds.workScheduleFeeds.tombstone(
      studentId: studentId,
      id: feedId,
      expectedRevision: feed.revision,
      mutation: _mutation(now),
    );
  });

  Future<StoredDomainRecord<WorkScheduleFeed>> updateSkipWords({
    required String studentId,
    required String feedId,
    required Iterable<String> skipWords,
  }) => _repositories.mutate((repositories) {
    final feeds = _feedRepositories(repositories);
    final current = feeds.workScheduleFeeds.find(
      studentId: studentId,
      id: feedId,
    );
    if (current == null) {
      throw const RepositoryException(
        RepositoryFailureKind.notFound,
        'Work Schedule Feed was not found.',
      );
    }
    final now = _clock.nowUtc();
    return feeds.workScheduleFeeds
        .put(
          studentId: studentId,
          value: current.value.copyWith(skipWords: skipWords),
          expectedRevision: current.revision,
          mutation: _mutation(now),
        )
        .record;
  });

  MutationToken _mutation(DateTime now) => MutationToken(
    operationId: _identifiers.nextIdentifier(),
    idempotencyKey: _identifiers.nextIdentifier(),
    occurredAtUtc: now,
  );
}

WorkScheduleFeedLocalWriteRepositories _feedRepositories(
  LocalWriteRepositories repositories,
) {
  if (repositories case WorkScheduleFeedLocalWriteRepositories feeds) {
    return feeds;
  }
  throw const RepositoryException(
    RepositoryFailureKind.uninitialized,
    'Work Schedule Feed storage is unavailable.',
  );
}

WorkScheduleFeedLocalReadRepositories _feedReadRepositories(
  LocalReadRepositories repositories,
) {
  if (repositories case WorkScheduleFeedLocalReadRepositories feeds) {
    return feeds;
  }
  throw const RepositoryException(
    RepositoryFailureKind.uninitialized,
    'Work Schedule Feed storage is unavailable.',
  );
}

final class _ParsedFeed {
  const _ParsedFeed({
    required this.shifts,
    required this.notImported,
    required this.timedIntervals,
  });

  final List<WorkShift> shifts;
  final List<WorkScheduleFeedNotImportedEvent> notImported;
  final List<ZonedInterval> timedIntervals;
}

_ParsedFeed _parse(
  String source, {
  required String feedId,
  required String feedName,
  required TimeZoneId studentTimeZone,
  required List<String> skipWords,
  required DateTime nowUtc,
}) {
  _initializeTimeZones();
  final lines = _unfold(source);
  if (!lines.contains('BEGIN:VCALENDAR') || !lines.contains('END:VCALENDAR')) {
    throw const WorkScheduleFeedFormatException('The feed is not a calendar.');
  }
  final events = <List<String>>[];
  List<String>? current;
  for (final line in lines) {
    if (line == 'BEGIN:VEVENT') {
      if (current != null) {
        throw const WorkScheduleFeedFormatException(
          'Nested events are invalid.',
        );
      }
      current = <String>[];
    } else if (line == 'END:VEVENT') {
      if (current == null) {
        throw const WorkScheduleFeedFormatException('Unexpected event end.');
      }
      events.add(current);
      current = null;
    } else {
      current?.add(line);
    }
  }
  if (current != null) {
    throw const WorkScheduleFeedFormatException('An event is incomplete.');
  }

  final shifts = <WorkShift>[];
  final notImported = <WorkScheduleFeedNotImportedEvent>[];
  final timedIntervals = <ZonedInterval>[];
  for (final eventLines in events) {
    final event = _CalendarEvent.parse(eventLines);
    if (event.allDay) {
      notImported.add(
        WorkScheduleFeedNotImportedEvent(
          sourceEventUid: event.uid,
          title: event.title,
          reason: WorkScheduleFeedNotImportedReason.allDay,
        ),
      );
      continue;
    }
    final interval = event.interval(studentTimeZone);
    timedIntervals.add(interval);
    if (skipWords.any(
      (word) => event.title.toLowerCase().contains(word.toLowerCase()),
    )) {
      notImported.add(
        WorkScheduleFeedNotImportedEvent(
          sourceEventUid: event.uid,
          title: event.title,
          reason: WorkScheduleFeedNotImportedReason.skipWord,
        ),
      );
      continue;
    }
    if (_hasStarted(interval, nowUtc)) continue;
    shifts.add(
      WorkShift.imported(
        id: _deterministicUuid(feedId, event.uid),
        plannedInterval: interval,
        workScheduleFeedId: feedId,
        workScheduleFeedName: feedName,
        sourceEventUid: event.uid,
      ),
    );
  }
  return _ParsedFeed(
    shifts: List.unmodifiable(shifts),
    notImported: List.unmodifiable(notImported),
    timedIntervals: List.unmodifiable(timedIntervals),
  );
}

final class _CalendarEvent {
  const _CalendarEvent({
    required this.uid,
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
  });

  factory _CalendarEvent.parse(List<String> lines) {
    _CalendarProperty? uid;
    _CalendarProperty? title;
    _CalendarProperty? start;
    _CalendarProperty? end;
    for (final line in lines) {
      final property = _CalendarProperty.parse(line);
      switch (property.name) {
        case 'UID':
          uid = property;
        case 'SUMMARY':
          title = property;
        case 'DTSTART':
          start = property;
        case 'DTEND':
          end = property;
      }
    }
    if (uid == null || start == null || end == null) {
      throw const WorkScheduleFeedFormatException(
        'Every event needs UID, DTSTART, and DTEND.',
      );
    }
    final allDay =
        start.value.length == 8 || start.parameters['VALUE'] == 'DATE';
    return _CalendarEvent(
      uid: uid.value,
      title: _unescape(title?.value ?? '(untitled)'),
      start: start,
      end: end,
      allDay: allDay,
    );
  }

  final String uid;
  final String title;
  final _CalendarProperty start;
  final _CalendarProperty end;
  final bool allDay;

  ZonedInterval interval(TimeZoneId studentTimeZone) {
    final startValue = _parseDateTime(start.value);
    final endValue = _parseDateTime(end.value);
    final zoneName = start.value.endsWith('Z')
        ? 'UTC'
        : start.parameters['TZID'] ?? studentTimeZone.value;
    final endZoneName = end.value.endsWith('Z')
        ? 'UTC'
        : end.parameters['TZID'] ?? zoneName;
    if (zoneName != endZoneName) {
      throw const WorkScheduleFeedFormatException(
        'An event must start and end in the same time zone.',
      );
    }
    final location = _location(zoneName);
    final startZoned = time_zone.TZDateTime(
      location,
      startValue.year,
      startValue.month,
      startValue.day,
      startValue.hour,
      startValue.minute,
      startValue.second,
    );
    final endZoned = time_zone.TZDateTime(
      location,
      endValue.year,
      endValue.month,
      endValue.day,
      endValue.hour,
      endValue.minute,
      endValue.second,
    );
    if (!endZoned.isAfter(startZoned) ||
        endZoned.difference(startZoned) > const Duration(hours: 24)) {
      throw const WorkScheduleFeedFormatException(
        'A timed event must have a positive duration of at most 24 hours.',
      );
    }
    return ZonedInterval(
      startDate: LocalDate(startZoned.year, startZoned.month, startZoned.day),
      startTime: LocalTime(startZoned.hour, startZoned.minute),
      endTime: LocalTime(endZoned.hour, endZoned.minute),
      timeZone: TimeZoneId(zoneName),
      startOffset: UtcOffset.inMinutes(startZoned.timeZoneOffset.inMinutes),
      endOffset: UtcOffset.inMinutes(endZoned.timeZoneOffset.inMinutes),
    );
  }
}

final class _CalendarProperty {
  const _CalendarProperty({
    required this.name,
    required this.parameters,
    required this.value,
  });

  factory _CalendarProperty.parse(String line) {
    final colon = line.indexOf(':');
    if (colon <= 0) {
      throw const WorkScheduleFeedFormatException(
        'A calendar line is invalid.',
      );
    }
    final head = line.substring(0, colon).split(';');
    final parameters = <String, String>{};
    for (final parameter in head.skip(1)) {
      final equals = parameter.indexOf('=');
      if (equals > 0) {
        parameters[parameter.substring(0, equals).toUpperCase()] = parameter
            .substring(equals + 1);
      }
    }
    return _CalendarProperty(
      name: head.first.toUpperCase(),
      parameters: parameters,
      value: line.substring(colon + 1),
    );
  }

  final String name;
  final Map<String, String> parameters;
  final String value;
}

List<String> _unfold(String source) {
  final result = <String>[];
  for (final line in source.replaceAll('\r\n', '\n').split('\n')) {
    if ((line.startsWith(' ') || line.startsWith('\t')) && result.isNotEmpty) {
      result[result.length - 1] += line.substring(1);
    } else if (line.isNotEmpty) {
      result.add(line);
    }
  }
  return result;
}

DateTime _parseDateTime(String value) {
  final normalized = value.endsWith('Z')
      ? value.substring(0, value.length - 1)
      : value;
  final match = RegExp(
    r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$',
  ).firstMatch(normalized);
  if (match == null) {
    throw const WorkScheduleFeedFormatException(
      'Timed events must use an iCalendar date-time.',
    );
  }
  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
    int.parse(match[6]!),
  );
}

String _unescape(String value) => value
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\N', '\n')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .replaceAll(r'\\', r'\');

bool _overlaps(ZonedInterval left, ZonedInterval right) =>
    left.startInstantUtc.isBefore(right.endInstantUtc) &&
    right.startInstantUtc.isBefore(left.endInstantUtc);

bool _sameInstantRange(ZonedInterval left, ZonedInterval right) =>
    left.startInstantUtc == right.startInstantUtc &&
    left.endInstantUtc == right.endInstantUtc;

bool _hasOverlaps(List<ZonedInterval> intervals) {
  for (var left = 0; left < intervals.length; left += 1) {
    for (var right = left + 1; right < intervals.length; right += 1) {
      if (_overlaps(intervals[left], intervals[right])) {
        return true;
      }
    }
  }
  return false;
}

bool _hasStarted(ZonedInterval interval, DateTime nowUtc) =>
    !interval.startInstantUtc.isAfter(nowUtc);

List<StoredDomainRecord<WorkShift>> _upcomingFeedShiftRecords(
  LocalReadRepositories repositories, {
  required String studentId,
  required String feedId,
  required DateTime nowUtc,
}) => repositories.workShifts
    .list(studentId: studentId)
    .where(
      (record) =>
          record.value.workScheduleFeedId == feedId &&
          record.value.plannedInterval.startInstantUtc.isAfter(nowUtc),
    )
    .toList(growable: false);

String _deterministicUuid(String feedId, String uid) {
  final bytes = sha1.convert(utf8.encode('$feedId\u0000$uid')).bytes.toList();
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .take(16)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}

bool _timeZonesInitialized = false;

void _initializeTimeZones() {
  if (_timeZonesInitialized) return;
  time_zone_data.initializeTimeZones();
  _timeZonesInitialized = true;
}

time_zone.Location _location(String name) {
  try {
    return name == 'UTC' ? time_zone.UTC : time_zone.getLocation(name);
  } on time_zone.LocationNotFoundException {
    throw WorkScheduleFeedFormatException('Unknown time zone: $name.');
  }
}
