import 'dart:convert';
import 'dart:io';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test('diagnostic snapshot excludes every sentinel private value', () {
    const privateName = 'SENTINEL PRECEPTOR NAME';
    const privateNotes = 'SENTINEL PRIVATE NOTES';
    const privateLocation = 'SENTINEL CLINIC LOCATION';
    const privateClassTitle = 'SENTINEL CLASS TITLE';
    const privateAssignmentTitle = 'SENTINEL ASSIGNMENT TITLE';
    const privateFeedName = 'SENTINEL FEED NAME';
    const privateFeedUrl =
        'https://calendar.example.test/private/sentinel-feed-token';

    final snapshot = const TicketDiagnosticBuilder().build(
      TicketDiagnosticFacts(
        build: '253',
        timeZone: 'America/New_York',
        settings: StudentSettings(),
        preceptors: [
          Preceptor(
            id: 'preceptor-253',
            name: privateName,
            organizationOrSite: privateLocation,
            schedulingNotes: privateNotes,
          ),
        ],
        academicAssignments: [
          AcademicAssignment(
            id: 'assignment-253',
            title: privateAssignmentTitle,
            course: privateClassTitle,
            dueDate: LocalDate(2026, 10, 1),
          ),
        ],
        classCatalogEntries: [
          ClassCatalogEntry(id: 'class-253', name: privateClassTitle),
        ],
        workScheduleFeeds: [
          WorkScheduleFeed(
            id: 'feed-253',
            name: privateFeedName,
            url: Uri.parse(privateFeedUrl),
            lastCheckedAtUtc: DateTime.utc(2026, 9, 27),
            lastSuccessfulUpdateAtUtc: DateTime.utc(2026, 9, 27),
          ),
        ],
      ),
    );

    expect(snapshot.values['build'], '253');
    expect(snapshot.values['time_zone'], 'America/New_York');
    expect(snapshot.values['count.preceptors'], 1);
    expect(snapshot.values['count.academic_assignments'], 1);
    expect(snapshot.values['count.class_catalog_entries'], 1);
    expect(snapshot.values['count.work_schedule_feeds'], 1);
    expect(snapshot.values['state.academic_assignment.pending'], 1);
    expect(snapshot.values['state.work_schedule_feed.active'], 1);
    expect(snapshot.values['setting.time_display'], 'military');

    final encoded = jsonEncode(snapshot.values);
    for (final privateValue in [
      privateName,
      privateNotes,
      privateLocation,
      privateClassTitle,
      privateAssignmentTitle,
      privateFeedName,
      privateFeedUrl,
    ]) {
      expect(encoded, isNot(contains(privateValue)));
    }
  });

  test('client and database diagnostic allowlists stay identical', () {
    var repository = Directory.current;
    while (!File(
      '${repository.path}${Platform.pathSeparator}supabase${Platform.pathSeparator}config.toml',
    ).existsSync()) {
      final parent = repository.parent;
      if (parent.path == repository.path) {
        fail('Could not locate the repository root.');
      }
      repository = parent;
    }

    final migration = File(
      '${repository.path}${Platform.pathSeparator}supabase'
      '${Platform.pathSeparator}migrations${Platform.pathSeparator}'
      '202609270011_ticket_thread_and_diagnostics.sql',
    ).readAsStringSync();
    final allowlist = RegExp(
      r'where entry\.key <> all \(array\[(.*?)\]::text\[\]\)',
      dotAll: true,
    ).firstMatch(migration);
    expect(allowlist, isNotNull, reason: 'Database allowlist was not found.');

    final databaseKeys = RegExp(
      r"'([^']+)'",
    ).allMatches(allowlist!.group(1)!).map((match) => match.group(1)!).toSet();

    expect(databaseKeys, TicketDiagnosticSnapshot.allowedKeys);
  });
}
