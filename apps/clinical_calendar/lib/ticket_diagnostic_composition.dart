import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

Future<TicketDiagnosticSnapshot> buildTicketDiagnosticSnapshot({
  required RepositoryRegistry repositories,
  required String studentId,
  required String build,
  required String timeZone,
}) => repositories.read((local) {
  List<T> values<T>(ReadRepository<T> repository) => repository
      .list(studentId: studentId)
      .map((record) => record.value)
      .toList(growable: false);

  final workScheduleFeeds = local is WorkScheduleFeedLocalReadRepositories
      ? values(local.workScheduleFeeds)
      : const <WorkScheduleFeed>[];
  final academicAssignments = switch (local) {
    AcademicAssignmentLocalReadRepositories capable =>
      values<AcademicAssignment>(capable.academicAssignments),
    _ => const <AcademicAssignment>[],
  };
  final classCatalogEntries = switch (local) {
    ClassCatalogLocalReadRepositories capable => values<ClassCatalogEntry>(
      capable.classCatalogEntries,
    ),
    _ => const <ClassCatalogEntry>[],
  };
  final settings = local is SupportLocalReadRepositories
      ? local.studentSettings.find(studentId: studentId)?.value ??
            StudentSettings()
      : StudentSettings();

  return const TicketDiagnosticBuilder().build(
    TicketDiagnosticFacts(
      build: build,
      timeZone: timeZone,
      settings: settings,
      workShifts: values(local.workShifts),
      clinicalSessions: values(local.clinicalSessions),
      protectedDays: values(local.protectedDays),
      scheduleTemplates: values(local.scheduleTemplates),
      preceptors: values(local.preceptors),
      clinicalPlacements: values(local.clinicalPlacements),
      historicalHoursEntries: values(local.historicalHoursEntries),
      evaluationPlans: values(local.evaluationPlans),
      workScheduleFeeds: workScheduleFeeds,
      academicAssignments: academicAssignments,
      classCatalogEntries: classCatalogEntries,
    ),
  );
});
