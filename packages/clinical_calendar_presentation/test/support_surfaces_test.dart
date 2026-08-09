import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _profileId = '00000000-0000-4000-8000-000000000002';

void main() {
  testWidgets(
    'profile avatar is a 44px header control with initials fallback',
    (tester) async {
      var pressed = false;
      await _pump(
        tester,
        Center(
          child: ProfileAvatarButton(
            profile: StudentProfile(
              id: _profileId,
              displayName: 'Alex Bennett',
            ),
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('AB'), findsOneWidget);
      final rect = tester.getRect(
        find.byKey(const Key('student-profile-avatar-action')),
      );
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
      await tester.tap(find.byKey(const Key('student-profile-avatar-action')));
      expect(pressed, isTrue);
    },
  );

  testWidgets(
    'Student Profile derives initials and selects then removes avatar',
    (tester) async {
      StudentProfile? saved;
      await _pump(
        tester,
        StudentProfileSurface(
          profile: StudentProfile(id: _profileId, displayName: 'Student'),
          chooseAvatar: () async => _onePixelPng,
          onSave: (profile) async => saved = profile,
        ),
        size: const Size(390, 844),
      );

      await tester.enterText(
        find.byKey(const Key('profile-display-name')),
        'Alex Bennett Carter',
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('profile-initials')),
          matching: find.text('AB'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('choose-avatar-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('remove-avatar-action')), findsOneWidget);
      await tester.tap(find.byKey(const Key('remove-avatar-action')));
      await tester.pump();
      expect(find.byKey(const Key('remove-avatar-action')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('save-profile-action')));
      await tester.tap(find.byKey(const Key('save-profile-action')));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.initials, 'AB');
      expect(saved!.avatarBytes, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile onboarding collects names and locks signed-in email', (
    tester,
  ) async {
    String? firstName;
    String? lastName;
    await _pump(
      tester,
      Builder(
        builder: (context) => FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => StudentProfileOnboardingDialog(
              email: 'student@example.com',
              onSave: (first, last) async {
                firstName = first;
                lastName = last;
              },
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-profile-onboarding')), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('onboarding-email')),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(find.text('student@example.com'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('save-onboarding-profile')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('onboarding-first-name')),
      '  Alex  ',
    );
    await tester.enterText(
      find.byKey(const Key('onboarding-last-name')),
      ' Bennett ',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('save-onboarding-profile')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-onboarding-profile')),
    );
    await tester.tap(find.byKey(const Key('save-onboarding-profile')));
    await tester.pumpAndSettle();

    expect(firstName, 'Alex');
    expect(lastName, 'Bennett');
    expect(find.byKey(const Key('student-profile-onboarding')), findsNothing);
  });

  testWidgets(
    'Settings edits preferences and templates with derived duration',
    (tester) async {
      StudentSettings? savedSettings;
      final savedTemplates = <ScheduleTemplate>[];
      final initial = ScheduleTemplate(
        id: _id(10),
        name: 'Clinic morning',
        type: ScheduleTemplateType.clinicalSession,
        startTime: LocalTime(8, 0),
        endTime: LocalTime(12, 0),
        clinicalPlacementId: _id(20),
        preceptorId: _id(21),
      );
      await _pump(
        tester,
        SettingsTemplatesSurface(
          settings: StudentSettings(),
          scheduleTemplates: [initial],
          clinicalDefaults: [
            ClinicalTemplateDefaultOption(
              clinicalPlacementId: _id(20),
              preceptorId: _id(21),
              label: 'Family Medicine / Jordan Lee',
            ),
          ],
          newTemplateId: () => _id(11),
          onSaveSettings: (settings) async => savedSettings = settings,
          onSaveTemplate: (template) async => savedTemplates.add(template),
          onRemoveTemplate: (_) async {},
        ),
        size: const Size(768, 1024),
      );

      final settingsScrollable = find.descendant(
        of: find.byKey(const Key('settings-templates-surface')),
        matching: find.byType(Scrollable),
      );
      await _bringIntoView(
        tester,
        find.textContaining('4 hours automatically'),
        settingsScrollable.first,
      );
      expect(find.textContaining('4 hours automatically'), findsOneWidget);
      expect(find.text('Family Medicine / Jordan Lee'), findsOneWidget);
      await _bringIntoView(
        tester,
        find.byKey(const Key('weekly-summary-setting')),
        settingsScrollable.first,
      );
      await tester.tap(find.byKey(const Key('weekly-summary-setting')));
      await tester.scrollUntilVisible(
        find.byKey(const Key('add-template-action')),
        300,
        scrollable: settingsScrollable.first,
      );
      await tester.ensureVisible(find.byKey(const Key('add-template-action')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add-template-action')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('template-start-1')),
        300,
        scrollable: settingsScrollable.first,
      );
      await tester.ensureVisible(find.byKey(const Key('template-start-1')));
      await tester.pump();
      tester
          .widget<ClinicalTimePickerField>(
            find.byKey(const Key('template-start-1')),
          )
          .onChanged(LocalTime(19, 0));
      tester
          .widget<ClinicalTimePickerField>(
            find.byKey(const Key('template-end-1')),
          )
          .onChanged(LocalTime(7, 0));
      await tester.pump();
      expect(find.textContaining('12 hours automatically'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('save-settings-templates-action')),
        300,
        scrollable: settingsScrollable.first,
      );
      await tester.ensureVisible(
        find.byKey(const Key('save-settings-templates-action')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-settings-templates-action')));
      await tester.pumpAndSettle();
      expect(savedSettings, isNotNull);
      expect(savedSettings!.notifications.weeklySummaryEnabled, isFalse);
      expect(savedTemplates, hasLength(2));
      expect(savedTemplates.first.clinicalPlacementId, _id(20));
      expect(savedTemplates.first.preceptorId, _id(21));
      expect(savedTemplates.last.isOvernight, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Settings persists reminder defaults and this-device preferences',
    (tester) async {
      StudentSettings? savedSettings;
      DeviceNotificationPreferences? savedDeviceNotifications;
      final initialNotifications = const NotificationPreferences(
        upcomingWorkShiftsEnabled: true,
        upcomingClinicalSessionsEnabled: false,
        confirmationFirstDelayMinutes: 45,
        evaluationRepeatDays: 5,
      );
      await _pump(
        tester,
        SettingsTemplatesSurface(
          settings: StudentSettings(notifications: initialNotifications),
          scheduleTemplates: const [],
          deviceNotifications: const DeviceNotificationPreferences(
            deliveryEnabled: false,
          ),
          newTemplateId: () => _id(30),
          onSaveSettings: (settings) async => savedSettings = settings,
          onSaveDeviceNotifications: (preferences) async =>
              savedDeviceNotifications = preferences,
          onSaveTemplate: (_) async {},
          onRemoveTemplate: (_) async {},
        ),
        size: const Size(768, 1024),
      );

      final scrollable = find.descendant(
        of: find.byKey(const Key('settings-templates-surface')),
        matching: find.byType(Scrollable),
      );

      await _bringIntoView(
        tester,
        find.byKey(const Key('work-shift-first-lead-setting')),
        scrollable.first,
      );
      await tester.tap(find.byKey(const Key('work-shift-first-lead-setting')));
      await tester.pumpAndSettle();
      expect(find.text('Never'), findsOneWidget);
      await tester.tap(find.text('12 hours before').last);
      await tester.pumpAndSettle();
      await _bringIntoView(
        tester,
        find.byKey(const Key('work-shift-notifications-setting')),
        scrollable.first,
      );
      await tester.tap(
        find.byKey(const Key('work-shift-notifications-setting')),
      );
      await tester.pump();
      expect(find.text('Work Shift reminders — Muted'), findsOneWidget);
      await _bringIntoView(
        tester,
        find.byKey(const Key('weekly-summary-weekday-setting')),
        scrollable.first,
      );
      await tester.tap(find.byKey(const Key('weekly-summary-weekday-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monday').last);
      await tester.pumpAndSettle();
      tester
          .widget<ClinicalTimePickerField>(
            find.byKey(const Key('weekly-summary-hour-setting')),
          )
          .onChanged(LocalTime(17, 30));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('no-backup-reminder-days-setting')),
        '10',
      );
      await tester.enterText(
        find.byKey(const Key('stale-backup-reminder-days-setting')),
        '45',
      );
      await _bringIntoView(
        tester,
        find.byKey(const Key('device-notification-delivery-setting')),
        scrollable.first,
      );
      await tester.tap(
        find.byKey(const Key('device-notification-delivery-setting')),
      );
      await _bringIntoView(
        tester,
        find.byKey(const Key('device-detailed-preview-setting')),
        scrollable.first,
      );
      await tester.tap(
        find.byKey(const Key('device-detailed-preview-setting')),
      );
      await _bringIntoView(
        tester,
        find.byKey(const Key('device-quiet-start-setting')),
        scrollable.first,
      );
      tester
          .widget<ClinicalTimePickerField>(
            find.byKey(const Key('device-quiet-start-setting')),
          )
          .onChanged(LocalTime(22, 15));
      await tester.pump();

      await _bringIntoView(
        tester,
        find.byKey(const Key('save-settings-templates-action')),
        scrollable.first,
      );
      await tester.tap(find.byKey(const Key('save-settings-templates-action')));
      await tester.pumpAndSettle();

      expect(savedSettings, isNotNull);
      expect(savedSettings!.notifications.upcomingWorkShiftsEnabled, isFalse);
      expect(
        savedSettings!.notifications.upcomingClinicalSessionsEnabled,
        isFalse,
      );
      expect(savedSettings!.notifications.workShiftFirstLeadMinutes, 720);
      expect(
        savedSettings!.notifications.weeklySummaryWeekday,
        DateTime.monday,
      );
      expect(savedSettings!.notifications.weeklySummaryHour, 17);
      expect(savedSettings!.notifications.weeklySummaryMinute, 30);
      expect(savedSettings!.notifications.noBackupReminderDays, 10);
      expect(savedSettings!.notifications.staleBackupReminderDays, 45);
      expect(savedSettings!.notifications.confirmationFirstDelayMinutes, 45);
      expect(savedSettings!.notifications.evaluationRepeatDays, 5);
      expect(savedDeviceNotifications, isNotNull);
      expect(savedDeviceNotifications!.deliveryEnabled, isTrue);
      expect(savedDeviceNotifications!.detailedPreview, isTrue);
      expect(savedDeviceNotifications!.quietStartsAtHour, 22);
      expect(savedDeviceNotifications!.quietStartsAtMinute, 15);
      expect(savedDeviceNotifications!.quietEndsAtHour, 7);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Settings rebases its saved theme after synchronized updates', (
    tester,
  ) async {
    StudentSettings? savedSettings;
    Widget app(StudentSettings settings) => MaterialApp(
      theme: const VariantFVisualTheme().createThemeData(),
      home: Scaffold(
        body: SafeArea(
          child: SettingsTemplatesSurface(
            key: const Key('synchronized-settings'),
            settings: settings,
            authoritativeThemeId: settings.themeId,
            scheduleTemplates: const [],
            newTemplateId: () => _id(31),
            onSaveSettings: (settings) async => savedSettings = settings,
            onSaveTemplate: (_) async {},
            onRemoveTemplate: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(StudentSettings(themeId: variantFThemeId)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(StudentSettings(themeId: graphiteThemeId)));
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byKey(const Key('settings-templates-surface')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-settings-templates-action')),
      300,
      scrollable: scrollable.first,
    );
    await tester.tap(find.byKey(const Key('save-settings-templates-action')));
    await tester.pumpAndSettle();

    expect(savedSettings?.themeId, graphiteThemeId);
  });

  testWidgets('Settings notification controls do not overflow at 320px', (
    tester,
  ) async {
    await _pump(
      tester,
      SettingsTemplatesSurface(
        settings: StudentSettings(),
        scheduleTemplates: const [],
        deviceNotifications: const DeviceNotificationPreferences(
          deliveryEnabled: true,
        ),
        newTemplateId: () => _id(31),
        onSaveSettings: (_) async {},
        onSaveDeviceNotifications: (_) async {},
        onSaveTemplate: (_) async {},
        onRemoveTemplate: (_) async {},
      ),
      size: const Size(320, 700),
    );

    final scrollable = find.descendant(
      of: find.byKey(const Key('settings-templates-surface')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-settings-templates-action')),
      300,
      scrollable: scrollable.first,
    );
    expect(find.byKey(const Key('device-quiet-end-setting')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings labels unknown applied theme as Graphite fallback', (
    tester,
  ) async {
    await _pump(
      tester,
      SettingsTemplatesSurface(
        settings: StudentSettings(themeId: 'future-theme'),
        scheduleTemplates: const [],
        newTemplateId: () => _id(40),
        onSaveSettings: (_) async {},
        onSaveTemplate: (_) async {},
        onRemoveTemplate: (_) async {},
      ),
      size: const Size(768, 1024),
    );

    final graphiteRow = find.byKey(
      const Key('theme-gallery-row-$graphiteThemeId'),
    );
    expect(find.byKey(const Key('theme-gallery')), findsOneWidget);
    expect(
      find.descendant(of: graphiteRow, matching: find.text('Fallback in use')),
      findsOneWidget,
    );
    expect(find.text('Applied'), findsNothing);
  });

  testWidgets('Settings labels catalog Graphite as Applied', (tester) async {
    await _pump(
      tester,
      SettingsTemplatesSurface(
        settings: StudentSettings(themeId: graphiteThemeId),
        scheduleTemplates: const [],
        newTemplateId: () => _id(41),
        onSaveSettings: (_) async {},
        onSaveTemplate: (_) async {},
        onRemoveTemplate: (_) async {},
      ),
      size: const Size(768, 1024),
    );

    final graphiteRow = find.byKey(
      const Key('theme-gallery-row-$graphiteThemeId'),
    );
    expect(
      find.descendant(of: graphiteRow, matching: find.text('Applied')),
      findsOneWidget,
    );
    expect(find.text('Fallback in use'), findsNothing);
  });

  testWidgets('Help keeps shared workflows separate from theme bundle', (
    tester,
  ) async {
    final guide = const VariantFThemeBundle().helpGuide;
    await _pump(
      tester,
      SupportHelpSurface(themeGuide: guide),
      size: const Size(390, 844),
    );

    for (final section in SupportHelpSurface.workflowSections) {
      expect(find.text(section.title), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('CONTAINMENT DRONE 47-ALPHA CALENDAR STATES'),
      400,
    );
    expect(
      find.text('Containment Drone 47-Alpha calendar states'.toUpperCase()),
      findsOneWidget,
    );
    expect(find.textContaining('offline source of truth'), findsOneWidget);
    expect(
      find.textContaining('not Synced until a server acknowledges'),
      findsOneWidget,
    );
    expect(find.textContaining('delivery remains deferred'), findsOneWidget);
    expect(find.text('Clinical Session'), findsOneWidget);
    expect(find.text(guide.calendarStates.first.nonColorCue), findsNothing);
    expect(
      find.text(guide.calendarStates.first.enhancedBehavior),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Graphite Help renders its complete theme-specific guidance', (
    tester,
  ) async {
    final bundle = const GraphiteThemeBundle();
    final clinicalSession = bundle.helpGuide.calendarStates.first;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: bundle.standardPresentation.createThemeData(),
        home: Scaffold(
          body: ClinicalCalendarSemanticMarkScope(
            marks: bundle.marks,
            child: SupportHelpSurface(themeGuide: bundle.helpGuide),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(clinicalSession.nonColorCue),
      400,
    );
    expect(find.text(clinicalSession.nonColorCue), findsOneWidget);
    expect(find.text(clinicalSession.enhancedBehavior), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Help explains where and how to configure Evaluation Plans', () {
    final section = SupportHelpSurface.workflowSections.singleWhere(
      (section) => section.title == 'Evaluation Plans',
    );

    expect(section.body, contains('Open Reviews & Evaluations'));
    expect(section.body, contains('Interim Review cadence'));
    expect(section.body, contains('Not required'));
    expect(section.body, contains('Preview Evaluation Plan changes'));
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(800, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: const VariantFVisualTheme().createThemeData(),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _bringIntoView(
  WidgetTester tester,
  Finder target,
  Finder scrollable,
) async {
  for (var attempt = 0; attempt < 40 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pump();
  }
  await tester.scrollUntilVisible(target, 250, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pump();
}

String _id(int value) =>
    '00000000-0000-4000-8000-${value.toRadixString(16).padLeft(12, '0')}';

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  129,
  189,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
