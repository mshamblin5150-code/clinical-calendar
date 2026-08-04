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

      expect(find.textContaining('4 hours automatically'), findsOneWidget);
      expect(find.text('Family Medicine / Jordan Lee'), findsOneWidget);
      await tester.tap(find.byKey(const Key('weekly-summary-setting')));
      final settingsScrollable = find.descendant(
        of: find.byKey(const Key('settings-templates-surface')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('add-template-action')),
        300,
        scrollable: settingsScrollable.first,
      );
      await tester.tap(find.byKey(const Key('add-template-action')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('template-start-1')),
        300,
        scrollable: settingsScrollable.first,
      );
      await tester.enterText(
        find.byKey(const Key('template-start-1')),
        '19:00',
      );
      await tester.enterText(find.byKey(const Key('template-end-1')), '07:00');
      await tester.pump();
      expect(find.textContaining('12 hours automatically'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('save-settings-templates-action')),
        300,
        scrollable: settingsScrollable.first,
      );
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

  testWidgets('Help keeps shared workflows separate from theme fallback', (
    tester,
  ) async {
    final guide = ThemeHelpGuideRegistry.standard().resolve('future-theme');
    await _pump(
      tester,
      SupportHelpSurface(themeGuide: guide),
      size: const Size(390, 844),
    );

    for (final section in SupportHelpSurface.workflowSections) {
      expect(find.text(section.title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('CALENDAR STATES'), 400);
    expect(find.text('Calendar states'.toUpperCase()), findsOneWidget);
    expect(find.textContaining('offline source of truth'), findsOneWidget);
    expect(
      find.textContaining('not Synced until a server acknowledges'),
      findsOneWidget,
    );
    expect(find.textContaining('delivery remains deferred'), findsOneWidget);
    expect(find.text('Calendar state'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
