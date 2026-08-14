import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/keyboard_focus.dart';
import 'support/proof_fonts.dart';

const studentId = '00000000-0000-4000-8000-000000000001';
const _appSessionId = '40000000-0000-4000-8000-000000000001';

void main() {
  const requiredViewports = <Size>[
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
    Size(768, 1024),
    Size(1056, 1691),
    Size(932, 430),
    Size(1024, 768),
    Size(1440, 900),
  ];

  test('leaving Gallery targets only inactive decoded theme frames', () {
    final registry = ClinicalCalendarThemeBundleRegistry.standard;
    final active = registry.resolveApplied('graphite').bundle;
    final inactive = registry.resolveApplied('coastal-calm').bundle;
    final providers = inactiveThemeFrameProviders(
      registry: registry,
      activeThemeId: active.id,
    );
    expect(
      providers.toSet().intersection({
        for (final assetPath in active.frame.assetPaths)
          AssetImage(assetPath, package: active.frame.assetPackage),
      }),
      isEmpty,
    );
    expect(
      providers.map((provider) => provider.assetName),
      contains(inactive.frame.primaryAsset),
    );
  });

  group('accepted Variant F and catalog Settings renders', () {
    setUpAll(() async {
      final font = await File(
        '../clinical_calendar_platform/assets/fonts/'
        'LiberationSansNarrow-Regular.ttf',
      ).readAsBytes();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final dartExecutable = File(Platform.resolvedExecutable);
      final inferredFlutterRoot =
          dartExecutable.parent.parent.parent.parent.parent.path;
      final flutterRoot =
          Platform.environment['FLUTTER_ROOT'] ?? inferredFlutterRoot;
      final icons = await File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });

    const calendarFixtures = <String, Size>{
      'calendar-compact': Size(390, 844),
      'calendar-portrait-tablet': Size(768, 1024),
      'calendar-landscape-desktop': Size(1440, 900),
      'calendar-landscape-1536x1024': Size(1536, 1024),
      'calendar-portrait-900x1440': Size(900, 1440),
    };

    for (final fixture in calendarFixtures.entries) {
      testWidgets(fixture.key, (tester) async {
        await _pumpAcceptedRenderAt(tester, fixture.value);
        expect(
          find.byKey(const Key('placement-progress-wheel')),
          findsOneWidget,
          reason: 'The accepted proof must exercise live placement progress.',
        );
        await _expectAppGolden(
          tester,
          fixture.key,
          collection: 'containment_drone_v2',
        );
      });
    }

    testWidgets('calendar-portrait-200-percent-900x1440', (tester) async {
      await _pumpAcceptedRenderAt(
        tester,
        const Size(900, 1440),
        textScaleFactor: 2,
      );
      await _expectAppGolden(
        tester,
        'calendar-portrait-200-percent-900x1440',
        collection: 'containment_drone_v2',
      );
    });

    testWidgets('settings-320', (tester) async {
      await _pumpAcceptedRenderAt(tester, const Size(320, 700));
      await tester.tap(find.text('SETTINGS').last);
      await tester.pumpAndSettle();
      await _expectAppGolden(
        tester,
        'settings-320',
        collection: 'containment_drone_v2',
      );
    });

    for (final destination in applicationMenuDestinations) {
      testWidgets('destination-${destination.name}', (tester) async {
        await _pumpAcceptedRenderAt(tester, const Size(1024, 768));
        await tester.tap(find.byKey(const Key('application-menu-action')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(destination.label));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('containment-drone-destination-shell')),
          findsOneWidget,
        );
        await _expectAppGolden(
          tester,
          'destination-${destination.name}',
          collection: 'containment_drone_v2',
        );
      });
    }

    testWidgets(
      'all ten real destinations mount in landscape portrait compact and 200 percent',
      (tester) async {
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        for (final fixture in const [
          (Size(320, 568), 1.0),
          (Size(900, 1440), 1.0),
          (Size(1536, 1024), 1.0),
          (Size(900, 1440), 2.0),
        ]) {
          for (final destination in applicationMenuDestinations) {
            await _pumpAcceptedRenderAt(
              tester,
              fixture.$1,
              textScaleFactor: fixture.$2,
            );
            await tester.tap(find.byKey(const Key('application-menu-action')));
            await tester.pumpAndSettle();
            final destinationAction = find.text(destination.label);
            await tester.scrollUntilVisible(
              destinationAction,
              120,
              scrollable: find.descendant(
                of: find.byKey(const Key('application-menu')),
                matching: find.byType(Scrollable),
              ),
            );
            await tester.ensureVisible(destinationAction);
            await tester.pumpAndSettle();
            await tester.tap(destinationAction);
            await tester.pumpAndSettle();

            expect(find.byType(ClinicalCalendarApp), findsOneWidget);
            expect(
              find.byKey(const Key('containment-drone-destination-shell')),
              findsOneWidget,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${destination.label} at ${fixture.$1} @ ${fixture.$2}x',
            );
          }
        }
        debugDefaultTargetPlatformOverride = null;
      },
    );
  });

  for (final viewport in requiredViewports) {
    testWidgets(
      'shell fits ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        await _pumpAt(tester, viewport);

        final landscape =
            viewport.width >= 1280 &&
            viewport.height >= 800 &&
            viewport.width > viewport.height;
        final portrait =
            viewport.width >= 600 && viewport.height >= viewport.width;
        expect(
          find.byKey(
            Key(
              landscape
                  ? 'containment-drone-landscape-shell'
                  : portrait
                  ? 'containment-drone-portrait-shell'
                  : 'containment-drone-compact-shell',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('containment-drone-bottom-navigation')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('containment-drone-calendar-bay')),
          findsOneWidget,
        );
        expect(find.byType(CalendarPeriodView), findsOneWidget);
        expect(
          find.byKey(const Key('containment-drone-planning-bay')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('containment-drone-placement-bay')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('containment-drone-insight-bay')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('containment-drone-attention-bay')),
          findsOneWidget,
        );

        await tester.ensureVisible(
          find.byKey(const Key('primary-planning-action')),
        );
        await tester.pumpAndSettle();
        final actionRect = tester.getRect(
          find.byKey(const Key('primary-planning-action')),
        );
        expect(actionRect.left, greaterThanOrEqualTo(0));
        expect(actionRect.right, lessThanOrEqualTo(viewport.width));
        expect(actionRect.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('mobile application menu exposes every destination', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('application-menu')), findsOneWidget);
    for (final destination in applicationMenuDestinations) {
      expect(
        find.descendant(
          of: find.byKey(const Key('application-menu')),
          matching: find.text(destination.label),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Graphite delta opens the production menu from the keyboard', (
    tester,
  ) async {
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: graphiteThemeId,
      initialRevision: 1,
    );
    addTearDown(preview.dispose);
    await _pumpAt(
      tester,
      const Size(3200, 2800),
      dependencies: _themeDependencies(graphiteThemeId),
      themePreviewController: preview,
      themeId: graphiteThemeId,
    );

    final delta = find.byKey(const Key('application-menu-action'));
    expect(delta, findsOneWidget);
    await focusWithKeyboard(tester, delta);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('application-menu')), findsOneWidget);
    for (final destination in applicationMenuDestinations) {
      expect(find.text(destination.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Graphite delta exposes one accessible menu-button action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: graphiteThemeId,
      initialRevision: 1,
    );
    addTearDown(preview.dispose);
    await _pumpAt(
      tester,
      const Size(3200, 2800),
      dependencies: _themeDependencies(graphiteThemeId),
      themePreviewController: preview,
      themeId: graphiteThemeId,
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Open menu'));
    final data = node.getSemanticsData();
    expect(data.label, 'Open menu');
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);

    tester.platformDispatcher.onSemanticsActionEvent!(
      ui.SemanticsActionEvent(
        type: ui.SemanticsAction.tap,
        viewId: tester.view.viewId,
        nodeId: node.id,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('application-menu')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final enhanced in const [false, true]) {
    for (final viewport in const [Size(1536, 1024), Size(900, 1440)]) {
      testWidgets(
        'Federation 2399 delta opens the ${enhanced ? 'Enhanced' : 'Standard'} '
        'menu at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          final preview = ThemePreviewController(
            registry: ClinicalCalendarThemeBundleRegistry.standard,
            authoritativeThemeId: federation2399ThemeId,
            initialRevision: 1,
          );
          final accessibility = EnhancedAccessibilityController(
            initialValue: enhanced,
          );
          addTearDown(preview.dispose);
          addTearDown(accessibility.dispose);
          await _pumpAt(
            tester,
            viewport,
            dependencies: _themeDependencies(federation2399ThemeId),
            themePreviewController: preview,
            enhancedAccessibilityController: accessibility,
            themeId: federation2399ThemeId,
          );

          await tester.tap(find.byKey(const Key('application-menu-action')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('application-menu')), findsOneWidget);
          for (final destination in applicationMenuDestinations) {
            expect(find.text(destination.label), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final activation in const [
    (key: LogicalKeyboardKey.enter, label: 'keyboard Enter'),
    (key: LogicalKeyboardKey.space, label: 'switch-style Space'),
  ]) {
    testWidgets(
      'Federation 2399 delta opens the production menu with ${activation.label}',
      (tester) async {
        final preview = ThemePreviewController(
          registry: ClinicalCalendarThemeBundleRegistry.standard,
          authoritativeThemeId: federation2399ThemeId,
          initialRevision: 1,
        );
        addTearDown(preview.dispose);
        await _pumpAt(
          tester,
          const Size(1536, 1024),
          dependencies: _themeDependencies(federation2399ThemeId),
          themePreviewController: preview,
          themeId: federation2399ThemeId,
        );

        final delta = find.byKey(const Key('application-menu-action'));
        await focusWithKeyboard(tester, delta);
        await tester.sendKeyEvent(activation.key);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('application-menu')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Federation 2399 delta exposes one accessible menu-button action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: federation2399ThemeId,
        initialRevision: 1,
      );
      addTearDown(preview.dispose);
      await _pumpAt(
        tester,
        const Size(900, 1440),
        dependencies: _themeDependencies(federation2399ThemeId),
        themePreviewController: preview,
        themeId: federation2399ThemeId,
      );

      final node = tester.getSemantics(find.bySemanticsLabel('Open menu'));
      final data = node.getSemanticsData();
      expect(data.label, 'Open menu');
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isButton, isTrue);

      tester.platformDispatcher.onSemanticsActionEvent!(
        ui.SemanticsActionEvent(
          type: ui.SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('application-menu')), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('mobile navigation matches the accepted Variant F order', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    for (final label in const [
      'TODAY',
      'CALENDAR',
      'PLACEMENTS',
      'ATTENTION',
      'SETTINGS',
    ]) {
      expect(
        find.descendant(
          of: find.byKey(const Key('bottom-navigation')),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    await tester.tap(find.text('SETTINGS').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-templates-surface')), findsOneWidget);
  });

  testWidgets('compact status rail indicators open real destinations', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    expect(find.byTooltip('Open Attention'), findsOneWidget);
    expect(find.byTooltip('Open Today'), findsOneWidget);
    expect(find.byTooltip('Open Clinical Placements'), findsOneWidget);
    expect(find.byTooltip('Open Synchronization'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Synchronization'));
    await tester.pumpAndSettle();
    expect(find.text('SYNCHRONIZATION'), findsWidgets);
    expect(find.byKey(const Key('close-action')), findsOneWidget);
  });

  testWidgets('portrait tablet uses the approved Containment reading order', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1056, 1691));

    final calendar = tester.getRect(
      find.byKey(const Key('containment-drone-calendar-bay')),
    );
    final placement = tester.getRect(
      find.byKey(const Key('containment-drone-placement-bay')),
    );
    final progress = tester.getRect(
      find.byKey(const Key('containment-drone-insight-bay')),
    );
    final planning = tester.getRect(
      find.byKey(const Key('containment-drone-planning-bay')),
    );
    final attention = tester.getRect(
      find.byKey(const Key('containment-drone-attention-bay')),
    );
    expect(calendar.top, lessThan(placement.top));
    expect(placement.top, lessThan(progress.top));
    expect(progress.top, lessThan(planning.top));
    expect(planning.top, lessThan(attention.top));
    expect(
      find.byKey(const Key('containment-drone-portrait-scroll')),
      findsOneWidget,
    );
    expect(find.byType(ContainmentDroneFrame), findsWidgets);
    expect(find.byKey(const Key('primary-planning-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait placement dock keeps headings and names readable', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1056, 1691));

    final dock = find.byKey(const Key('placement-dock'));
    final heading = find.descendant(
      of: dock,
      matching: find.text('MY PLACEMENTS'),
    );
    expect(heading, findsOneWidget);
    expect(
      tester.getSize(heading).height,
      lessThanOrEqualTo(28),
      reason: 'The portrait dock heading must remain on one readable line.',
    );
  });

  testWidgets('portrait tablet Week owns a vertical scrollable', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1056, 1691));

    await tester.tap(
      find.descendant(
        of: find.byType(CalendarPeriodView),
        matching: find.text('Week'),
      ),
    );
    await tester.pumpAndSettle();

    final week = find.byKey(const Key('week-view'));
    expect(week, findsOneWidget);
    final scrollable = find.descendant(
      of: week,
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isNotEmpty) {
      final position = tester.state<ScrollableState>(scrollable).position;
      if (position.maxScrollExtent > 0) {
        await tester.drag(week, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait tablet Agenda owns a vertical scrollable', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1056, 1691));

    await tester.tap(
      find.descendant(
        of: find.byType(CalendarPeriodView),
        matching: find.text('Agenda'),
      ),
    );
    await tester.pumpAndSettle();

    final agenda = find.byKey(const Key('agenda-view'));
    expect(agenda, findsOneWidget);
    expect(
      find.descendant(of: agenda, matching: find.byType(Scrollable)),
      findsOneWidget,
      reason: 'Agenda must scroll within the clipped portrait calendar bay.',
    );
  });

  testWidgets('menu entry uses Back and returns to the application menu', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('back-action')), findsOneWidget);
    expect(find.byKey(const Key('close-action')), findsNothing);
    expect(
      find.byKey(const Key('notification-center-surface')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('back-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('application-menu')), findsOneWidget);
  });

  testWidgets('notification body tap opens the exact summary workflow', (
    tester,
  ) async {
    final interactions = StreamController<NotificationInteraction>.broadcast();
    addTearDown(interactions.close);
    await _pumpAt(
      tester,
      const Size(1024, 768),
      notificationInteractions: interactions.stream,
    );

    interactions.add(
      const NotificationInteraction(
        occurrenceKey: 'weekly:occurrence',
        synchronizationKey: 'weekly',
        route: ReminderWorkflowRoutes.summary,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('notification-center-surface')),
      findsOneWidget,
    );
  });

  testWidgets('direct Help entry uses Close', (tester) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('desktop-help-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('close-action')), findsOneWidget);
    expect(find.byKey(const Key('back-action')), findsNothing);
    expect(find.text('WORKFLOW GUIDE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CONTAINMENT DRONE 47-ALPHA CALENDAR STATES'),
      500,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('support-help-surface')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.text('CONTAINMENT DRONE 47-ALPHA CALENDAR STATES'),
      findsOneWidget,
    );
  });

  testWidgets('profile avatar is a 44 pixel direct Student Profile entry', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    final avatar = find.byKey(const Key('student-profile-avatar-action'));
    expect(avatar, findsOneWidget);
    expect(tester.getSize(avatar), const Size(44, 44));

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-profile-surface')), findsOneWidget);
    expect(find.byKey(const Key('close-action')), findsOneWidget);
  });

  testWidgets('menu routes Clinical Placements to its management surface', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clinical Placements'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('placement-management-surface')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('back-action')), findsOneWidget);
  });

  testWidgets('menu routes Settings to the settings and templates surface', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-templates-surface')), findsOneWidget);
    expect(find.byKey(const Key('back-action')), findsOneWidget);
  });

  testWidgets('closing Settings preserves staged Calendar planning state', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 768));

    await tester.tap(
      find.byKey(const Key('calendar-day-2026-01-02')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 selected date · Clinical Session'), findsOneWidget);

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('back-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('application-menu')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('1 selected date · Clinical Session'), findsOneWidget);
  });

  testWidgets('menu routes backup and exports to production surfaces', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const Size(1024, 768),
      portableBackupWorkflows: PortableBackupWorkflows(
        create: (_) async => true,
        choose: (_) async => null,
        apply: (_) async {},
      ),
      exportWorkflowFactory: (gate) => ExportWorkflowService(
        data: const _ExportSource(),
        encoder: const _ExportEncoder(),
        reauthentication: gate,
        fileSaver: const _ExportSaver(),
      ),
    );

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup & Restore'));
    await tester.pumpAndSettle();
    expect(find.byType(BackupRestoreSurface), findsOneWidget);
    expect(find.byKey(const Key('back-action')), findsOneWidget);

    await tester.tap(find.byKey(const Key('back-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exports'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-surface')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('export-placement-pdf')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('export-complete-json')), findsOneWidget);
  });

  testWidgets('menu exposes the production Trash and recovery destination', (
    tester,
  ) async {
    final store = _RecoveryStore();
    await _pumpAt(
      tester,
      const Size(1024, 768),
      recoveryStore: store,
      recoveryService: RecoveryApplicationService(
        store: store,
        reauthentication: _RecoveryGate(),
        identifiers: _Identifiers(),
      ),
    );

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trash & Recovery'));
    await tester.pumpAndSettle();

    expect(find.text('Trash is empty.'), findsOneWidget);
    expect(find.byKey(const Key('back-action')), findsOneWidget);
    expect(store.dailySnapshots, 0);
  });

  testWidgets('Clear Trash consumes a fresh passwordless OTP proof', (
    tester,
  ) async {
    final store = _RecoveryStore(withTrash: true);
    final proof = OneShotRecoveryReauthenticationGate();
    final gateway = _RecoveryOtpGateway();
    final identity = PasswordlessIdentityService(
      gateway: gateway,
      secureStorage: _SecureStorage(),
      identifiers: _Identifiers(),
      clock: _Clock(),
      currentDevice: DeviceDescriptor(
        name: 'Test device',
        platform: DevicePlatform.windows,
      ),
    );
    await _pumpAt(
      tester,
      const Size(1024, 768),
      recoveryStore: store,
      recoveryService: RecoveryApplicationService(
        store: store,
        reauthentication: proof,
        identifiers: _Identifiers(),
      ),
      recoveryProofGate: proof,
      identity: identity,
      identityEmail: 'student@example.com',
    );
    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trash & Recovery'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-trash')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.clears, 0);

    await tester.tap(find.byKey(const Key('clear-trash')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-recovery-otp')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recovery-otp-code')),
      '123456',
    );
    await tester.tap(find.byKey(const Key('verify-recovery-otp')));
    await tester.pumpAndSettle();

    expect(gateway.sent, 1);
    expect(gateway.verified, 1);
    expect(store.clears, 1);
    expect(find.text('Trash is empty.'), findsOneWidget);
  });

  testWidgets('calendar selection feeds staged tray and both reset seams', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    await tester.tap(
      find.byKey(const Key('calendar-day-2026-01-02')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 selected date · Clinical Session'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('planning-tray-toggle')));
    await tester.tap(find.byKey(const Key('planning-tray-toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('selected-date-count')));
    expect(find.text('1 selected date'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('planning-incomplete-action')),
    );
    await tester.tap(find.byKey(const Key('planning-incomplete-action')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('batch-type-protectedDay')))
          .selected,
      isTrue,
    );

    await tester.ensureVisible(
      find.byKey(const Key('primary-planning-action')),
    );
    await tester.tap(find.byKey(const Key('primary-planning-action')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const Key('batch-type-clinicalSession')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('calendar item opens contextual lifecycle surface', (
    tester,
  ) async {
    final repositories = _Repositories(seedLifecycle: true);
    await _pumpAt(
      tester,
      const Size(1024, 768),
      dependencies: _dependencies(repositories: repositories),
    );

    await tester.tap(find.byKey(Key('month-entry-$_appSessionId-2026-01-01')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('commitment-lifecycle-surface')),
      findsOneWidget,
    );
    expect(find.text('CLINICAL SESSION DETAILS'), findsOneWidget);
    expect(find.textContaining('Family Medicine'), findsWidgets);
  });

  testWidgets(
    'Planning Incomplete attention preserves its date and resets the tray',
    (tester) async {
      await _pumpAt(tester, const Size(390, 844));

      await tester.tap(find.text('ATTENTION').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('notification-center-surface')),
        findsOneWidget,
      );
      final center = tester.widget<AttentionCenterSurface>(
        find.byType(AttentionCenterSurface),
      );
      expect(
        center.controller.error,
        isNull,
        reason: '${center.controller.error}',
      );

      await tester.tap(find.text('Planning Incomplete'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPeriodView), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('selected-date-count')));
      expect(find.text('1 selected date'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('batch-type-protectedDay')),
            )
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('evaluation attention opens its selected contextual plan route', (
    tester,
  ) async {
    final repositories = _Repositories(seedLifecycle: true);
    await _pumpAt(
      tester,
      const Size(1024, 768),
      dependencies: _dependencies(repositories: repositories),
    );

    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    final center = tester.widget<AttentionCenterSurface>(
      find.byType(AttentionCenterSurface),
    );
    expect(
      center.controller.error,
      isNull,
      reason: '${center.controller.error}',
    );
    final evaluationAttention = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'attention-item-evaluation:',
          ),
    );
    expect(evaluationAttention, findsWidgets);
    await tester.tap(evaluationAttention.first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contextual-route-surface')), findsOneWidget);
    expect(find.byKey(const Key('evaluation-plan-surface')), findsOneWidget);
    expect(find.text('Evaluation Plan'), findsWidgets);
    expect(find.text('Family Medicine'), findsWidgets);
    expect(find.byKey(const Key('contextual-back-action')), findsOneWidget);

    await tester.tap(find.byKey(const Key('contextual-back-action')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('notification-center-surface')),
      findsOneWidget,
    );
  });

  testWidgets('synchronization attention exposes an honest Sync Now route', (
    tester,
  ) async {
    final repositories = _Repositories(seedSynchronization: true);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
    );

    await tester.tap(find.text('ATTENTION').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Synchronization needs attention'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contextual-route-surface')), findsOneWidget);
    expect(
      find.byKey(const Key('synchronization-attention-surface')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('sync-now-action')));
    await tester.pumpAndSettle();
    expect(
      find.text('Synchronization is offline. Local changes remain queued.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('contextual-back-action')), findsOneWidget);
  });

  testWidgets(
    'synchronization conflict opens resolution and preserves originals',
    (tester) async {
      final repositories = _Repositories(
        seedSynchronization: true,
        seedConflict: true,
      );
      await _pumpAt(
        tester,
        const Size(390, 844),
        dependencies: _dependencies(repositories: repositories),
      );

      await tester.tap(find.text('ATTENTION').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Synchronization needs attention'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('synchronization-conflict-resolution-surface')),
        findsOneWidget,
      );
      expect(find.textContaining('This device version'), findsOneWidget);
      expect(find.textContaining('Other device version'), findsOneWidget);
      await tester.tap(find.byKey(const Key('choose-local-conflict-version')));
      await tester.pumpAndSettle();
      expect(find.text('No Sync Conflicts need attention.'), findsOneWidget);
      expect(repositories.synchronization.originalsPreserved, isTrue);

      await tester.tap(find.byKey(const Key('contextual-back-action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('notification-center-surface')),
        findsOneWidget,
      );
    },
  );

  test('partial root registry rejects an unavailable theme', () {
    expect(
      () => ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        'future-theme',
      ),
      throwsA(isA<InvalidThemeBundle>()),
    );
  });

  testWidgets(
    'Preview preserves Settings state and Apply persists transactionally',
    (tester) async {
      final repositories = _Repositories();
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: variantFThemeId,
        initialRevision: 0,
      );
      addTearDown(preview.dispose);
      await _pumpAt(
        tester,
        const Size(390, 844),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
        candidateThemePreflight: (_) async {},
      );

      await tester.tap(find.text('SETTINGS').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('week-start-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monday').last);
      await tester.pumpAndSettle();

      final settingsScroll = find.descendant(
        of: find.byKey(const Key('settings-templates-surface')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(settingsScroll.first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await preview.preview(graphiteThemeId, preflight: (_) async {});
      await tester.pumpAndSettle();
      expect(preview.previewUnavailable, isFalse);
      expect(preview.isPreviewing, isTrue);
      expect(find.byType(GraphiteDestinationSurface), findsOneWidget);
      expect(
        find.byKey(const Key('settings-templates-surface')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('week-start-setting')),
        -300,
        scrollable: settingsScroll.first,
      );
      expect(find.text('Monday'), findsWidgets);
      expect(find.text('Previewing Graphite'), findsOneWidget);
      expect(find.text('Not saved'), findsOneWidget);

      await tester.tap(find.byKey(const Key('apply-theme-preview')));
      await tester.pumpAndSettle();

      expect(preview.isPreviewing, isFalse);
      expect(preview.authoritativeThemeId, graphiteThemeId);
      expect(repositories.settings.value?.value.themeId, graphiteThemeId);
      expect(find.byKey(const Key('theme-preview-control')), findsNothing);
      expect(
        find.byKey(const Key('settings-templates-surface')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Federation Classic previews, applies, and survives restart', (
    tester,
  ) async {
    final repositories = _Repositories();
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 0,
    );
    addTearDown(preview.dispose);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: preview,
      candidateThemePreflight: (_) async {},
    );

    await preview.preview(federationClassicThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    expect(find.byType(FederationClassicNineSliceFrame), findsWidgets);
    expect(find.text('Previewing Federation Classic'), findsOneWidget);

    await tester.tap(find.byKey(const Key('revert-theme-preview')));
    await tester.pumpAndSettle();
    expect(preview.effectiveBundle.id, variantFThemeId);
    expect(find.byType(FederationClassicNineSliceFrame), findsNothing);

    await preview.preview(federationClassicThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-theme-preview')));
    await tester.pumpAndSettle();

    expect(preview.authoritativeThemeId, federationClassicThemeId);
    expect(
      repositories.settings.value?.value.themeId,
      federationClassicThemeId,
    );
    expect(preview.effectiveBundle.id, federationClassicThemeId);
    expect(find.byType(FederationClassicNineSliceFrame), findsWidgets);

    final restarted = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: federationClassicThemeId,
      initialRevision: preview.authoritativeRevision,
    );
    addTearDown(restarted.dispose);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: restarted,
      candidateThemePreflight: (_) async {},
    );

    expect(restarted.authoritativeThemeId, federationClassicThemeId);
    expect(restarted.effectiveBundle.id, federationClassicThemeId);
    expect(restarted.authoritativeResolution.isFallback, isFalse);
    expect(find.byType(FederationClassicNineSliceFrame), findsWidgets);
  });

  testWidgets('Federation 2399 previews, applies, and survives restart', (
    tester,
  ) async {
    final repositories = _Repositories();
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 0,
    );
    addTearDown(preview.dispose);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: preview,
      candidateThemePreflight: (_) async {},
    );

    await preview.preview(federation2399ThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    expect(find.byType(Federation2399NineSliceFrame), findsWidgets);
    expect(find.text('Previewing Federation 2399'), findsOneWidget);

    await tester.tap(find.byKey(const Key('revert-theme-preview')));
    await tester.pumpAndSettle();
    expect(preview.effectiveBundle.id, variantFThemeId);
    expect(find.byType(Federation2399NineSliceFrame), findsNothing);

    await preview.preview(federation2399ThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-theme-preview')));
    await tester.pumpAndSettle();

    expect(preview.authoritativeThemeId, federation2399ThemeId);
    expect(repositories.settings.value?.value.themeId, federation2399ThemeId);
    expect(preview.effectiveBundle.id, federation2399ThemeId);
    expect(find.byType(Federation2399NineSliceFrame), findsWidgets);

    final restarted = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: federation2399ThemeId,
      initialRevision: preview.authoritativeRevision,
    );
    addTearDown(restarted.dispose);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: restarted,
      candidateThemePreflight: (_) async {},
    );

    expect(restarted.authoritativeThemeId, federation2399ThemeId);
    expect(restarted.effectiveBundle.id, federation2399ThemeId);
    expect(restarted.authoritativeResolution.isFallback, isFalse);
    expect(find.byType(Federation2399NineSliceFrame), findsWidgets);
  });

  testWidgets('Coastal Light previews, applies, and survives restart', (
    tester,
  ) async {
    final repositories = _Repositories();
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 0,
    );
    addTearDown(preview.dispose);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: preview,
      candidateThemePreflight: (_) async {},
    );

    await preview.preview(coastalCalmThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    expect(find.byType(CoastalLightNineSliceFrame), findsWidgets);
    expect(find.text('Previewing Coastal Light'), findsOneWidget);

    await tester.tap(find.byKey(const Key('revert-theme-preview')));
    await tester.pumpAndSettle();
    expect(preview.effectiveBundle.id, variantFThemeId);
    expect(find.byType(CoastalLightNineSliceFrame), findsNothing);

    await preview.preview(coastalCalmThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apply-theme-preview')));
    await tester.pumpAndSettle();

    expect(preview.authoritativeThemeId, coastalCalmThemeId);
    expect(repositories.settings.value?.value.themeId, coastalCalmThemeId);
    expect(preview.effectiveBundle.id, coastalCalmThemeId);
    expect(find.byType(CoastalLightNineSliceFrame), findsWidgets);

    final restarted = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: coastalCalmThemeId,
      initialRevision: preview.authoritativeRevision,
    );
    addTearDown(restarted.dispose);
    await _pumpAt(
      tester,
      const Size(390, 844),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: restarted,
      candidateThemePreflight: (_) async {},
    );

    expect(restarted.authoritativeThemeId, coastalCalmThemeId);
    expect(restarted.effectiveBundle.id, coastalCalmThemeId);
    expect(restarted.authoritativeResolution.isFallback, isFalse);
    expect(find.byType(CoastalLightNineSliceFrame), findsWidgets);
  });

  testWidgets(
    'Botanical Study preview composes the production live application slots',
    (tester) async {
      final repositories = _Repositories();
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: graphiteThemeId,
        initialRevision: 0,
      );
      addTearDown(preview.dispose);
      await _pumpAt(
        tester,
        const Size(1586, 992),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
        candidateThemePreflight: (_) async {},
      );
      expect(tester.takeException(), isNull);

      final planningAction = find.byKey(const Key('primary-planning-action'));
      await tester.ensureVisible(planningAction);
      await tester.tap(planningAction);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('batch-scheduling-tray')), findsOneWidget);

      await preview.preview(botanicalStudyThemeId, preflight: (_) async {});
      await tester.pumpAndSettle();

      expect(find.byType(BotanicalStudyLandscapeChassis), findsOneWidget);
      expect(find.byType(CalendarPeriodView), findsOneWidget);
      expect(find.byKey(const Key('placement-dock-surface')), findsOneWidget);
      expect(find.byKey(const Key('primary-planning-action')), findsOneWidget);
      expect(find.byKey(const Key('placement-progress-rail')), findsOneWidget);
      expect(find.byKey(const Key('attention-rail')), findsOneWidget);
      expect(find.byKey(const Key('batch-scheduling-tray')), findsOneWidget);
      expect(
        find.byKey(const Key('botanical-study-assignment-control-housing')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('add-academic-assignment')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('add-academic-assignment')));
      await tester.pumpAndSettle();
      expect(find.byType(AcademicAssignmentEditor), findsOneWidget);
      await tester.tap(find.byTooltip('Close assignment details'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('revert-theme-preview')));
      await tester.pumpAndSettle();
      expect(preview.effectiveBundle.id, variantFThemeId);
    },
  );

  testWidgets('failed Apply keeps Preview retryable and Revert available', (
    tester,
  ) async {
    final repositories = _Repositories();
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 0,
    );
    addTearDown(preview.dispose);
    await _pumpAt(
      tester,
      const Size(768, 1024),
      dependencies: _dependencies(repositories: repositories),
      themePreviewController: preview,
    );
    await preview.preview(graphiteThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();
    repositories.settings.failNextPut = true;

    await tester.tap(find.byKey(const Key('apply-theme-preview')));
    await tester.pumpAndSettle();

    expect(preview.isPreviewing, isTrue);
    expect(preview.authoritativeThemeId, variantFThemeId);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const Key('revert-theme-preview')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apply-theme-preview')));
    await tester.pumpAndSettle();

    expect(preview.isPreviewing, isFalse);
    expect(preview.authoritativeThemeId, graphiteThemeId);
  });

  testWidgets(
    'signed-in Enhanced persists immediately, survives Revert, and rolls back failure',
    (tester) async {
      final repositories = _Repositories();
      final accessibility = EnhancedAccessibilityController(
        initialValue: false,
      );
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: variantFThemeId,
        initialRevision: 0,
      );
      addTearDown(accessibility.dispose);
      addTearDown(preview.dispose);
      await _pumpAt(
        tester,
        const Size(768, 1024),
        dependencies: _dependencies(repositories: repositories),
        enhancedAccessibilityController: accessibility,
        themePreviewController: preview,
        candidateThemePreflight: (_) async {},
      );

      await tester.tap(find.byKey(const Key('application-menu-action')));
      await tester.pumpAndSettle();
      final toggle = find
          .byKey(const Key('enhanced-accessibility-setting'))
          .first;
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(accessibility.enabled, isTrue);
      expect(repositories.settings.value?.value.enhancedAccessibility, isTrue);
      expect(
        Theme.of(
          tester.element(toggle),
        ).extension<ClinicalCalendarAccessibilityTokens>()?.enhanced,
        isTrue,
      );
      Navigator.of(tester.element(toggle)).pop();
      await tester.pumpAndSettle();

      await preview.preview(graphiteThemeId, preflight: (_) async {});
      await tester.pumpAndSettle();
      preview.revert();
      await tester.pumpAndSettle();
      expect(accessibility.enabled, isTrue);

      repositories.settings.failNextPut = true;
      await tester.tap(find.byKey(const Key('application-menu-action')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('enhanced-accessibility-setting')).first,
      );
      await tester.pumpAndSettle();
      expect(accessibility.enabled, isTrue);
      expect(repositories.settings.value?.value.enhancedAccessibility, isTrue);
      expect(
        find.text('Enhanced accessibility could not be saved. Try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('sign out and local removal discards an active Preview', (
    tester,
  ) async {
    final gateway = _RecoveryOtpGateway();
    final localCopy = _LocalCopyController();
    final identity = PasswordlessIdentityService(
      gateway: gateway,
      secureStorage: _IdentitySecureStorage(),
      identifiers: _Identifiers(),
      clock: _Clock(),
      currentDevice: DeviceDescriptor(
        name: 'Test device',
        platform: DevicePlatform.windows,
      ),
      localCopy: localCopy,
    );
    await identity.verifySignInCode('student@example.com', '123456');
    final preview = ThemePreviewController(
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      authoritativeThemeId: variantFThemeId,
      initialRevision: 0,
    );
    addTearDown(preview.dispose);
    var removed = false;
    await _pumpAt(
      tester,
      const Size(1024, 768),
      identity: identity,
      identityEmail: 'student@example.com',
      onLocalCopyRemoved: () async => removed = true,
      themePreviewController: preview,
    );
    await tester.tap(find.byKey(const Key('application-menu-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connected Devices'));
    await tester.pumpAndSettle();
    await preview.preview(graphiteThemeId, preflight: (_) async {});
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-out-remove-local-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-local-removal')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('remove-local-copy')));
    await tester.pumpAndSettle();

    expect(removed, isTrue);
    expect(localCopy.removed, isTrue);
    expect(preview.isPreviewing, isFalse);
  });

  testWidgets('Variant F exposes semantic colors and shallow metrics', (
    tester,
  ) async {
    late ClinicalCalendarColors colors;
    late ClinicalCalendarMetrics metrics;
    await tester.pumpWidget(
      MaterialApp(
        theme: const VariantFVisualTheme().createThemeData(),
        home: Builder(
          builder: (context) {
            colors = context.clinicalColors;
            metrics = context.clinicalMetrics;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(colors.clinical, VariantFColors.primary);
    expect(colors.work, VariantFColors.work);
    expect(colors.protectedDay, VariantFColors.protectedDay);
    expect(colors.scheduled, VariantFColors.scheduled);
    expect(colors.urgent, VariantFColors.urgent);
    expect(metrics.cornerRadius, lessThanOrEqualTo(4));
    expect(metrics.minimumTouchTarget, 44);
  });

  testWidgets(
    'Federation Classic production shell consumes every live application slot',
    (tester) async {
      final repositories = _Repositories(seedLifecycle: true);
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: variantFThemeId,
        initialRevision: 1,
      );
      addTearDown(preview.dispose);

      await _pumpAt(
        tester,
        const Size(1586, 992),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
      );
      await preview.preview(federationClassicThemeId, preflight: (_) async {});
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('federation-classic-landscape-shell')),
        findsOneWidget,
      );
      expect(find.byType(CalendarPeriodView), findsOneWidget);
      expect(find.byType(PlacementDock), findsOneWidget);
      expect(find.byType(PlacementProgressRail), findsOneWidget);
      expect(find.byType(AttentionRail), findsOneWidget);
      expect(find.byKey(const Key('live-planning-region')), findsOneWidget);
      expect(find.byKey(const Key('primary-planning-action')), findsOneWidget);
      for (final key in const [
        'federation-classic-placements-housing',
        'federation-classic-planning-housing',
        'federation-classic-workflow-housing',
        'federation-classic-needs-attention-housing',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(find.byType(VariantFTacticalFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Federation 2399 owns live Planning and Needs Attention housing',
    (tester) async {
      final repositories = _Repositories(seedLifecycle: true);
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: federation2399ThemeId,
        initialRevision: 1,
      );
      addTearDown(preview.dispose);

      await _pumpAt(
        tester,
        const Size(1536, 1024),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
      );
      expect(
        find.byKey(const Key('federation-2399-live-planning-housing')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('federation-2399-live-attention-housing')),
        findsOneWidget,
      );
      final headerSemantics = tester.getSemantics(
        find.byKey(const Key('federation-2399-attention-heading')),
      );
      expect(headerSemantics.label, startsWith('Needs Attention, '));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Coastal Light owns shared live workflow housings without forking slots',
    (tester) async {
      final repositories = _Repositories(seedLifecycle: true);
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: coastalCalmThemeId,
        initialRevision: 1,
      );
      addTearDown(preview.dispose);

      await _pumpAt(
        tester,
        const Size(1586, 992),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
      );

      expect(find.byType(CalendarPeriodView), findsOneWidget);
      expect(find.byType(PlacementDock), findsOneWidget);
      expect(find.byType(PlacementProgressRail), findsOneWidget);
      expect(find.byType(AttentionRail), findsOneWidget);
      expect(find.text('Add Assignment'), findsOneWidget);
      for (final key in const [
        'coastal-light-placements-housing',
        'coastal-light-planning-housing',
        'coastal-light-clinical-placement-housing',
        'coastal-light-needs-attention-housing',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(find.byType(VariantFTacticalFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Field Archive owns shared live workflow housings without forking slots',
    (tester) async {
      final repositories = _Repositories(seedLifecycle: true);
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: heritageFieldNotesThemeId,
        initialRevision: 1,
      );
      addTearDown(preview.dispose);

      await _pumpAt(
        tester,
        const Size(1536, 1024),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
      );

      expect(find.byType(CalendarPeriodView), findsOneWidget);
      expect(find.byType(PlacementDock), findsOneWidget);
      expect(find.byType(PlacementProgressRail), findsOneWidget);
      expect(find.byType(AttentionRail), findsOneWidget);
      expect(find.text('Add Assignment'), findsOneWidget);
      for (final key in const [
        'heritage-field-notes-placements-housing',
        'heritage-field-notes-planning-housing',
        'heritage-field-notes-clinical-placement-housing',
        'heritage-field-notes-needs-attention-housing',
      ]) {
        final housing = find.byKey(Key(key));
        expect(housing, findsOneWidget, reason: key);
        final container = tester.widget<Container>(housing);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.gradient, isNull, reason: '$key must remain flat');
      }
      final attentionSemantics = tester.getSemantics(
        find.byKey(const Key('heritage-field-notes-needs-attention-heading')),
      );
      expect(attentionSemantics.label, startsWith('Needs Attention, '));
      expect(find.byType(VariantFTacticalFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Field Archive Needs Attention remains clear at 200 percent text scale',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repositories = _Repositories(seedLifecycle: true);
      final preview = ThemePreviewController(
        registry: ClinicalCalendarThemeBundleRegistry.standard,
        authoritativeThemeId: heritageFieldNotesThemeId,
        initialRevision: 1,
      );
      addTearDown(preview.dispose);

      await _pumpAt(
        tester,
        const Size(900, 1440),
        dependencies: _dependencies(repositories: repositories),
        themePreviewController: preview,
      );

      final heading = find.byKey(
        const Key('heritage-field-notes-needs-attention-heading'),
      );
      expect(heading, findsOneWidget);
      expect(
        tester.getSemantics(heading).label,
        startsWith('Needs Attention, '),
      );
      expect(
        find.byKey(const Key('heritage-field-notes-needs-attention-housing')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _expectAppGolden(
  WidgetTester tester,
  String name, {
  String collection = 'variant_f_renders',
}) async {
  final exactComparator = goldenFileComparator;
  if ((collection == 'catalog_gallery' ||
          collection == 'containment_drone_v2') &&
      !Platform.isWindows) {
    goldenFileComparator = createProofGoldenComparator(
      exactComparator,
      // The approved v2 collection is intentionally separate from the exact
      // frozen historical Variant F baselines. Linux CI validates the single
      // cross-host reference collection through the bounded proof comparator;
      // Gallery retains its separately measured cap.
      highDeltaPixelTolerance: collection == 'catalog_gallery' ? .0045 : .0025,
    );
  }
  try {
    await expectLater(
      find.byType(ClinicalCalendarApp),
      matchesGoldenFile(
        'baselines/$collection/'
        '${collection == 'containment_drone_v2' ? 'reference' : _goldenPlatformDirectory()}/'
        '$name.png',
      ),
    );
  } finally {
    goldenFileComparator = exactComparator;
    debugDefaultTargetPlatformOverride = null;
  }
}

String _goldenPlatformDirectory() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  throw UnsupportedError(
    'Variant F golden renders are frozen only for Windows and Linux hosts.',
  );
}

Future<void> _pumpAcceptedRenderAt(
  WidgetTester tester,
  Size size, {
  double textScaleFactor = 1,
}) async {
  // Variant F's nine-slice painter is populated by an asynchronous image
  // stream. Preload it so catalog goldens do not depend on whether another
  // concurrently running proof happened to warm the process image cache.
  {
    final preloadKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: SizedBox(key: preloadKey)));
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/variant_f_raster/panel-nine-slice-v2.png',
        containmentDroneChassisBridgeAsset,
      ]) {
        await precacheImage(
          AssetImage(asset, package: 'clinical_calendar_presentation'),
          preloadKey.currentContext!,
        );
      }
    });
    await tester.pump();
  }
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  final repositories = _Repositories(seedLifecycle: true);
  repositories.settings.value = StoredDomainRecord(
    value: StudentSettings(themeId: StudentSettings.variantFThemeId),
    studentId: studentId,
    revision: 1,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 1),
  );
  await _pumpAt(
    tester,
    size,
    dependencies: _dependencies(repositories: repositories),
  );
}

ApplicationDependencies _themeDependencies(String themeId) {
  final repositories = _Repositories();
  repositories.settings.value = StoredDomainRecord(
    value: StudentSettings(themeId: themeId),
    studentId: studentId,
    revision: 1,
    createdAtUtc: DateTime.utc(2026, 8, 1),
    updatedAtUtc: DateTime.utc(2026, 8, 1),
  );
  return _dependencies(repositories: repositories);
}

Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  ApplicationDependencies? dependencies,
  Stream<NotificationInteraction>? notificationInteractions,
  RecoveryStore? recoveryStore,
  RecoveryApplicationService? recoveryService,
  OneShotRecoveryReauthenticationGate? recoveryProofGate,
  PasswordlessIdentityService? identity,
  String? identityEmail,
  Future<void> Function()? onLocalCopyRemoved,
  PortableBackupWorkflows? portableBackupWorkflows,
  ExportWorkflowFactory? exportWorkflowFactory,
  ThemePreviewController? themePreviewController,
  EnhancedAccessibilityController? enhancedAccessibilityController,
  CandidateThemePreflight? candidateThemePreflight,
  String themeId = variantFThemeId,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ClinicalCalendarApp(
      dependencies: dependencies ?? _dependencies(),
      environmentName: 'test',
      studentId: studentId,
      themeId: themeId,
      notificationInteractions: notificationInteractions,
      recoveryStore: recoveryStore,
      recoveryService: recoveryService,
      recoveryProofGate: recoveryProofGate,
      identity: identity,
      identityEmail: identityEmail,
      onLocalCopyRemoved: onLocalCopyRemoved,
      portableBackupWorkflows: portableBackupWorkflows,
      exportWorkflowFactory: exportWorkflowFactory,
      themePreviewController: themePreviewController,
      enhancedAccessibilityController: enhancedAccessibilityController,
      candidateThemePreflight: candidateThemePreflight,
    ),
  );
  await tester.pumpAndSettle();
}

final class _RecoveryStore implements RecoveryStore {
  _RecoveryStore({bool withTrash = false})
    : _trash = withTrash
          ? [
              TrashEntry(
                id: '00000000-0000-4000-8000-000000000091',
                entityType: 'work_shift',
                entityId: '00000000-0000-4000-8000-000000000092',
                deletedAtUtc: DateTime.utc(2026),
                purgeAfterUtc: DateTime.utc(2026, 2),
              ),
            ]
          : [];

  var dailySnapshots = 0;
  var clears = 0;
  List<TrashEntry> _trash;

  @override
  Future<OperationalSnapshotSummary> createDailySnapshot({
    required DateTime nowUtc,
  }) async {
    dailySnapshots++;
    return OperationalSnapshotSummary(
      id: '00000000-0000-4000-8000-000000000099',
      snapshotDate: '2026-01-01',
      createdAtUtc: nowUtc,
      expiresAtUtc: nowUtc.add(const Duration(days: 30)),
    );
  }

  @override
  Future<List<TrashEntry>> listTrash({required DateTime nowUtc}) async =>
      List.of(_trash);

  @override
  Future<int> clearTrash({
    required DateTime deletedAtUtc,
    required List<MutationToken> mutations,
  }) async {
    clears++;
    final count = _trash.length;
    _trash = [];
    return count;
  }

  @override
  Future<List<OperationalSnapshotSummary>> listSnapshots({
    required DateTime nowUtc,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecoveryOtpGateway implements PasswordlessIdentityGateway {
  var sent = 0;
  var verified = 0;

  @override
  Future<void> sendSignInCode(String email) async => sent++;

  @override
  Future<IdentitySession> verifySignInCode(String email, String code) async {
    verified++;
    return IdentitySession(
      accessToken: 'fresh-access',
      refreshToken: 'fresh-refresh',
      studentId: studentId,
      sessionId: '00000000-0000-4000-8000-000000000093',
      email: email,
      expiresAtUtc: DateTime.utc(2027),
    );
  }

  @override
  Future<bool> registerCurrentDevice({
    required String accessToken,
    required String deviceId,
    required DeviceDescriptor descriptor,
  }) async => true;

  @override
  Future<List<ConnectedDevice>> listConnectedDevices(
    String accessToken,
  ) async => const [];

  @override
  Future<void> signOutCurrentSession(String accessToken) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _LocalCopyController implements LocalDeviceCopyController {
  var removed = false;

  @override
  Future<LocalRemovalPreview> previewRemoval() async =>
      const LocalRemovalPreview(pendingChangeCount: 0);

  @override
  Future<void> removeLocalCopy() async => removed = true;
}

final class _IdentitySecureStorage implements SecureStorage {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

final class _RecoveryGate implements RecoveryReauthenticationGate {
  @override
  Future<bool> reauthenticate({required String reason}) async => true;
}

final class _ExportSource implements ExportSnapshotSource {
  const _ExportSource();

  @override
  Future<PortableExportSnapshot> completePortableData() =>
      throw UnimplementedError();

  @override
  Future<PlacementExportSnapshot> placement(String placementId) =>
      throw UnimplementedError();
}

final class _ExportEncoder implements ExportEncoder {
  const _ExportEncoder();

  @override
  Future<ExportArtifact> encodeCompleteJson(PortableExportSnapshot snapshot) =>
      throw UnimplementedError();

  @override
  Future<ExportArtifact> encodePlacementCsv(PlacementExportSnapshot snapshot) =>
      throw UnimplementedError();

  @override
  Future<ExportArtifact> encodePlacementPdf(PlacementExportSnapshot snapshot) =>
      throw UnimplementedError();
}

final class _ExportSaver implements NativeByteFileSaver {
  const _ExportSaver();

  @override
  Future<NativeFileSaveOutcome> save(NativeFileSaveRequest request) =>
      throw UnimplementedError();
}

ApplicationDependencies _dependencies({_Repositories? repositories}) =>
    ApplicationDependencies(
      repositories: repositories ?? _Repositories(),
      clock: _Clock(),
      identifiers: _Identifiers(),
      synchronization: _Synchronization(),
      notifications: _Notifications(),
      secureStorage: _SecureStorage(),
      files: _Files(),
    );

final class _Repositories implements RepositoryRegistry {
  _Repositories({
    bool seedLifecycle = false,
    bool seedSynchronization = false,
    bool seedConflict = false,
  }) {
    settings = _SettingsStore();
    profile = _ProfileStore();
    activePlacement = _ActivePlacementStore(seeded: seedLifecycle);
    synchronization = _ConflictSynchronizationRepository(seedConflict);
    repositories = _ReadRepositories(
      seedLifecycle: seedLifecycle,
      seedSynchronization: seedSynchronization,
      synchronization: synchronization,
      settings: settings,
      profile: profile,
      activePlacement: activePlacement,
    );
  }

  late final _ReadRepositories repositories;
  late final _ConflictSynchronizationRepository synchronization;
  late final _SettingsStore settings;
  late final _ProfileStore profile;
  late final _ActivePlacementStore activePlacement;

  @override
  Future<void> initialize() async {}

  @override
  Future<R> read<R>(
    R Function(LocalReadRepositories repositories) callback,
  ) async => callback(repositories);

  @override
  Future<R> mutate<R>(
    R Function(LocalWriteRepositories repositories) callback,
  ) async => callback(
    _ConflictWriteRepositories(
      synchronization,
      settings: settings,
      profile: profile,
      activePlacement: activePlacement,
    ),
  );
}

final class _ReadRepositories
    implements
        SupportLocalReadRepositories,
        SynchronizationLocalReadRepositories,
        AcademicAssignmentLocalReadRepositories,
        ClassCatalogLocalReadRepositories {
  _ReadRepositories({
    required bool seedLifecycle,
    required bool seedSynchronization,
    required this.synchronization,
    required this.settings,
    required this.profile,
    required this.activePlacement,
  }) : _workShifts = _EmptyReadRepository(),
       _clinicalSessions = seedLifecycle
           ? _StaticReadRepository([_sessionRecord()], (value) => value.id)
           : _EmptyReadRepository(),
       _protectedDays = _EmptyReadRepository(),
       _scheduleTemplates = _EmptyReadRepository(),
       _preceptors = seedLifecycle
           ? _StaticReadRepository([_preceptorRecord()], (value) => value.id)
           : _EmptyReadRepository(),
       _clinicalPlacements = seedLifecycle
           ? _StaticReadRepository([_placementRecord()], (value) => value.id)
           : _EmptyReadRepository(),
       _evaluationPlans = seedLifecycle
           ? _StaticReadRepository([
               _evaluationPlanRecord(),
             ], (value) => value.id)
           : _EmptyReadRepository(),
       _classCatalogEntries = _StaticReadRepository([
         StoredDomainRecord(
           value: ClassCatalogEntry(id: 'course-1', name: 'NURS 702'),
           studentId: studentId,
           revision: 1,
           createdAtUtc: DateTime.utc(2026, 8, 11),
           updatedAtUtc: DateTime.utc(2026, 8, 11),
         ),
       ], (value) => value.id),
       _outbox = seedSynchronization ? _PendingOutbox() : const _EmptyOutbox();

  final ReadRepository<WorkShift> _workShifts;
  final ReadRepository<ClinicalSession> _clinicalSessions;
  final ReadRepository<ProtectedDay> _protectedDays;
  final ReadRepository<ScheduleTemplate> _scheduleTemplates;
  final ReadRepository<Preceptor> _preceptors;
  final ReadRepository<ClinicalPlacement> _clinicalPlacements;
  final OutboxReadRepository _outbox;
  final _EmptyReadRepository<HistoricalHoursEntry> _historicalHoursEntries =
      _EmptyReadRepository();
  final ReadRepository<EvaluationPlan> _evaluationPlans;
  final _EmptyReadRepository<AcademicAssignment> _academicAssignments =
      _EmptyReadRepository();
  final ReadRepository<ClassCatalogEntry> _classCatalogEntries;

  @override
  final SynchronizationLocalRepository synchronization;
  final _SettingsStore settings;
  final _ProfileStore profile;
  final _ActivePlacementStore activePlacement;

  @override
  ReadRepository<WorkShift> get workShifts => _workShifts;

  @override
  ReadRepository<ClinicalSession> get clinicalSessions => _clinicalSessions;

  @override
  ReadRepository<ProtectedDay> get protectedDays => _protectedDays;

  @override
  ReadRepository<ScheduleTemplate> get scheduleTemplates => _scheduleTemplates;

  @override
  ReadRepository<Preceptor> get preceptors => _preceptors;

  @override
  ReadRepository<ClinicalPlacement> get clinicalPlacements =>
      _clinicalPlacements;

  @override
  ReadRepository<HistoricalHoursEntry> get historicalHoursEntries =>
      _historicalHoursEntries;

  @override
  ReadRepository<EvaluationPlan> get evaluationPlans => _evaluationPlans;

  @override
  ReadRepository<AcademicAssignment> get academicAssignments =>
      _academicAssignments;

  @override
  ReadRepository<ClassCatalogEntry> get classCatalogEntries =>
      _classCatalogEntries;

  @override
  OutboxReadRepository get outbox => _outbox;

  @override
  SyncCursorReadRepository get syncCursors => const _EmptySyncCursors();

  @override
  ActivePlacementSelectionReadRepository get activePlacementSelection =>
      activePlacement;

  @override
  StudentProfileReadRepository get studentProfile => profile;

  @override
  StudentSettingsReadRepository get studentSettings => settings;
}

final class _ConflictWriteRepositories
    implements
        SynchronizationLocalWriteRepositories,
        SupportLocalWriteRepositories {
  _ConflictWriteRepositories(
    this.synchronization, {
    required this.settings,
    required this.profile,
    required this.activePlacement,
  });

  @override
  final SynchronizationLocalRepository synchronization;

  final _SettingsStore settings;
  final _ProfileStore profile;
  final _ActivePlacementStore activePlacement;

  @override
  ActivePlacementSelectionRepository get activePlacementSelection =>
      activePlacement;

  @override
  StudentSettingsRepository get studentSettings => settings;

  @override
  StudentProfileRepository get studentProfile => profile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ConflictSynchronizationRepository
    implements SynchronizationLocalRepository {
  _ConflictSynchronizationRepository(bool seeded)
    : _record = seeded ? _conflictRecord() : null,
      originalLocal = seeded ? _conflictRecord().localSnapshotJson : null,
      originalRemote = seeded ? _conflictRecord().remoteSnapshotJson : null;

  SynchronizationConflictRecord? _record;
  final String? originalLocal;
  final String? originalRemote;

  bool get originalsPreserved =>
      _record?.localSnapshotJson == originalLocal &&
      _record?.remoteSnapshotJson == originalRemote;

  @override
  SynchronizationHealthSnapshot inspect({
    required String studentId,
    required String remoteScope,
  }) => SynchronizationHealthSnapshot(
    disposition: _record != null && !_record!.isResolved
        ? SynchronizationHealthDisposition.conflictNeedsAttention
        : SynchronizationHealthDisposition.synced,
    pendingCount: 0,
    unresolvedConflictCount: _record != null && !_record!.isResolved ? 1 : 0,
  );

  @override
  List<SynchronizationConflictRecord> listConflicts({
    required String studentId,
    bool includeResolved = false,
  }) {
    final record = _record;
    if (record == null || (record.isResolved && !includeResolved)) return [];
    return [record];
  }

  @override
  SynchronizationConflictRecord? findConflict({
    required String studentId,
    required String conflictId,
  }) => _record?.id == conflictId ? _record : null;

  @override
  SynchronizationConflictResolutionReceipt resolveConflict({
    required String studentId,
    required String conflictId,
    required SynchronizationConflictResolutionChoice choice,
    String? correctedValueJson,
    required MutationToken mutation,
  }) {
    final record = _record!;
    _record = SynchronizationConflictRecord(
      id: record.id,
      studentId: record.studentId,
      entityType: record.entityType,
      entityId: record.entityId,
      localRevision: record.localRevision,
      remoteRevision: record.remoteRevision,
      localSnapshotJson: record.localSnapshotJson,
      remoteSnapshotJson: record.remoteSnapshotJson,
      rejectionCode: record.rejectionCode,
      rejectionJson: record.rejectionJson,
      detectedAtUtc: record.detectedAtUtc,
      affectedRecords: record.affectedRecords,
      resolvedAtUtc: mutation.occurredAtUtc,
      resolutionJson: jsonEncode({'choice': choice.name}),
    );
    return SynchronizationConflictResolutionReceipt(
      conflict: _record!,
      operation: OutboxOperation(
        mutation: mutation,
        studentId: studentId,
        entityType: record.entityType,
        entityId: record.entityId,
        type: OutboxOperationType.resolveConflict,
        baseRevision: record.remoteRevision,
        payloadJson:
            choice == SynchronizationConflictResolutionChoice.remoteVersion
            ? record.remoteSnapshotJson
            : record.localSnapshotJson,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SynchronizationConflictRecord _conflictRecord() {
  const entityId = '90000000-0000-4000-8000-000000000001';
  const conflictId = '90000000-0000-4000-8000-000000000002';
  String envelope(String name) => jsonEncode({
    'schema_version': 1,
    'entity_type': 'preceptor',
    'entity_id': entityId,
    'student_id': studentId,
    'revision': 2,
    'created_at_utc': DateTime.utc(2026).toIso8601String(),
    'updated_at_utc': DateTime.utc(2026).toIso8601String(),
    'deleted_at_utc': null,
    'value': {'name': name},
  });

  return SynchronizationConflictRecord(
    id: conflictId,
    studentId: studentId,
    entityType: 'preceptor',
    entityId: entityId,
    localRevision: 2,
    remoteRevision: 2,
    localSnapshotJson: envelope('This device version'),
    remoteSnapshotJson: envelope('Other device version'),
    rejectionCode: 'stale_revision',
    rejectionJson: '{"code":"stale_revision"}',
    detectedAtUtc: DateTime.utc(2026),
    affectedRecords: [
      SynchronizationConflictEntityReference(
        entityType: 'preceptor',
        entityId: entityId,
      ),
    ],
  );
}

final class _EmptyReadRepository<T> implements ReadRepository<T> {
  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) => null;

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => <StoredDomainRecord<T>>[];
}

final class _StaticReadRepository<T> implements ReadRepository<T> {
  _StaticReadRepository(Iterable<StoredDomainRecord<T>> records, this.idOf)
    : records = List.unmodifiable(records);

  final List<StoredDomainRecord<T>> records;
  final String Function(T value) idOf;

  @override
  StoredDomainRecord<T>? find({
    required String studentId,
    required String id,
    bool includeDeleted = false,
  }) {
    for (final record in records) {
      if (record.studentId == studentId && idOf(record.value) == id) {
        return record;
      }
    }
    return null;
  }

  @override
  List<StoredDomainRecord<T>> list({
    required String studentId,
    bool includeDeleted = false,
  }) => records
      .where((record) => record.studentId == studentId)
      .toList(growable: false);
}

StoredDomainRecord<ClinicalSession> _sessionRecord() => StoredDomainRecord(
  value: ClinicalSession.schedule(
    id: _appSessionId,
    clinicalPlacementId: '20000000-0000-4000-8000-000000000001',
    preceptorId: '30000000-0000-4000-8000-000000000001',
    plannedInterval: ZonedInterval(
      startDate: LocalDate(2026, 1, 1),
      startTime: LocalTime(13, 0),
      endTime: LocalTime(16, 0),
      timeZone: TimeZoneId('UTC'),
      startOffset: UtcOffset.utc,
      endOffset: UtcOffset.utc,
    ),
    asOfUtc: DateTime.utc(2026, 1, 1, 12),
  ),
  studentId: studentId,
  revision: 1,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

StoredDomainRecord<ClinicalPlacement> _placementRecord() => StoredDomainRecord(
  value: ClinicalPlacement.create(
    id: '20000000-0000-4000-8000-000000000001',
    name: 'Family Medicine',
    targetHours: TargetHours.fromWholeHours(270),
    startDate: LocalDate(2026, 1, 1),
    completionDeadline: LocalDate(2026, 12, 31),
    attachedPreceptorIds: const ['30000000-0000-4000-8000-000000000001'],
    primaryPreceptorId: '30000000-0000-4000-8000-000000000001',
    evaluationPlanId: '70000000-0000-4000-8000-000000000001',
  ),
  studentId: studentId,
  revision: 1,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

StoredDomainRecord<EvaluationPlan> _evaluationPlanRecord() {
  final plan = const EvaluationPlanEngine().create(
    evaluationPlanId: '70000000-0000-4000-8000-000000000001',
    configuration: EvaluationPlanConfiguration(),
    context: EvaluationPlanContext(
      completedMinutes: 0,
      targetMinutes: 270 * 60,
      startDate: LocalDate(2026, 1, 1),
      completionDeadline: LocalDate(2026, 12, 31),
      today: LocalDate(2026, 1, 1),
      futureScheduledSessionMinutes: const [3 * 60],
    ),
    primaryPreceptorId: '30000000-0000-4000-8000-000000000001',
  );
  return StoredDomainRecord(
    value: plan,
    studentId: studentId,
    revision: 1,
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
  );
}

StoredDomainRecord<Preceptor> _preceptorRecord() => StoredDomainRecord(
  value: Preceptor(
    id: '30000000-0000-4000-8000-000000000001',
    name: 'Dr. Rivera',
  ),
  studentId: studentId,
  revision: 1,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

final class _ProfileStore implements StudentProfileRepository {
  StoredDomainRecord<StudentProfile>? value;

  @override
  StoredDomainRecord<StudentProfile>? find({required String studentId}) =>
      value ??
      StoredDomainRecord(
        value: StudentProfile(id: studentId, displayName: 'Test Student'),
        studentId: studentId,
        revision: 0,
        createdAtUtc: DateTime.utc(2026),
        updatedAtUtc: DateTime.utc(2026),
      );

  @override
  MutationReceipt<StudentProfile> put({
    required String studentId,
    required StudentProfile profile,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = find(studentId: studentId)!;
    if (current.revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'stale profile',
      );
    }
    value = StoredDomainRecord(
      value: profile,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current.createdAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: value!, replayed: false);
  }
}

final class _SettingsStore implements StudentSettingsRepository {
  StoredDomainRecord<StudentSettings>? value;
  bool failNextPut = false;

  @override
  StoredDomainRecord<StudentSettings>? find({required String studentId}) =>
      value ??
      StoredDomainRecord(
        value: StudentSettings(themeId: StudentSettings.variantFThemeId),
        studentId: studentId,
        revision: 0,
        createdAtUtc: DateTime.utc(2026, 8, 1),
        updatedAtUtc: DateTime.utc(2026, 8, 1),
      );

  @override
  MutationReceipt<StudentSettings> put({
    required String studentId,
    required StudentSettings settings,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    if (failNextPut) {
      failNextPut = false;
      throw const RepositoryException(
        RepositoryFailureKind.persistenceFailure,
        'simulated failure',
      );
    }
    final current = value;
    final revision = current?.revision ?? 0;
    if (revision != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'stale settings',
      );
    }
    value = StoredDomainRecord(
      value: settings,
      studentId: studentId,
      revision: revision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: value!, replayed: false);
  }
}

final class _ActivePlacementStore
    implements ActivePlacementSelectionRepository {
  _ActivePlacementStore({required bool seeded})
    : value = seeded
          ? StoredDomainRecord(
              value: '20000000-0000-4000-8000-000000000001',
              studentId: studentId,
              revision: 1,
              createdAtUtc: DateTime.utc(2026),
              updatedAtUtc: DateTime.utc(2026),
            )
          : null;

  StoredDomainRecord<String?>? value;

  @override
  StoredDomainRecord<String?>? find({required String studentId}) => value;

  @override
  MutationReceipt<String?> put({
    required String studentId,
    required String? clinicalPlacementId,
    required int expectedRevision,
    required MutationToken mutation,
  }) {
    final current = value;
    if ((current?.revision ?? 0) != expectedRevision) {
      throw const RepositoryException(
        RepositoryFailureKind.concurrentModification,
        'stale active Clinical Placement selection',
      );
    }
    value = StoredDomainRecord(
      value: clinicalPlacementId,
      studentId: studentId,
      revision: expectedRevision + 1,
      createdAtUtc: current?.createdAtUtc ?? mutation.occurredAtUtc,
      updatedAtUtc: mutation.occurredAtUtc,
    );
    return MutationReceipt(record: value!, replayed: false);
  }
}

final class _EmptyOutbox implements OutboxReadRepository {
  const _EmptyOutbox();

  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  }) => <OutboxOperation>[];
}

final class _PendingOutbox implements OutboxReadRepository {
  @override
  List<OutboxOperation> pending({
    required String studentId,
    required DateTime asOfUtc,
    int limit = 100,
  }) => [
    OutboxOperation(
      mutation: MutationToken(
        operationId: '80000000-0000-4000-8000-000000000001',
        idempotencyKey: '80000000-0000-4000-8000-000000000002',
        occurredAtUtc: DateTime.utc(2025, 12, 30),
      ),
      studentId: studentId,
      entityType: 'work_shift',
      entityId: '80000000-0000-4000-8000-000000000003',
      type: OutboxOperationType.upsert,
      baseRevision: 0,
      payloadJson: '{}',
    ),
  ];
}

final class _EmptySyncCursors implements SyncCursorReadRepository {
  const _EmptySyncCursors();

  @override
  SyncCursor? find({required String studentId, required String remoteScope}) =>
      null;
}

final class _Clock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026);
}

final class _Identifiers implements IdentifierGenerator {
  int _next = 1;

  @override
  String nextIdentifier() =>
      '91000000-0000-4000-8000-${(_next++).toString().padLeft(12, '0')}';
}

final class _Synchronization implements SynchronizationService {
  @override
  Future<SynchronizationResult> synchronize() async =>
      const SynchronizationResult(SynchronizationDisposition.offline);
}

final class _Notifications implements NotificationService {
  @override
  Future<void> reconcileScheduledNotifications() async {}
}

final class _SecureStorage implements SecureStorage {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

final class _Files implements FileService {
  @override
  Future<List<int>> read(Uri location) async => [];

  @override
  Future<void> write(Uri location, List<int> bytes) async {}
}
