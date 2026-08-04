import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import 'calendar/calendar_data_source.dart';
import 'calendar/calendar_period_view.dart';
import 'placements/placement_management_surface.dart';
import 'placements/placement_progress_controller.dart';
import 'placements/placement_progress_widgets.dart';
import 'responsive_shell.dart';
import 'support/profile_avatar_button.dart';
import 'support/settings_templates_surface.dart';
import 'support/student_profile_surface.dart';
import 'support/support_help_surface.dart';
import 'theme_contract.dart';
import 'variant_f_theme.dart';

final class ClinicalCalendarApp extends StatelessWidget {
  const ClinicalCalendarApp({
    required this.dependencies,
    required this.environmentName,
    required this.studentId,
    this.chooseAvatar,
    this.visualTheme = const VariantFVisualTheme(),
    this.helpGuides,
    super.key,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;
  final String studentId;
  final AvatarChooser? chooseAvatar;
  final ClinicalCalendarVisualTheme visualTheme;
  final ThemeHelpGuideRegistry? helpGuides;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: visualTheme.createThemeData(),
    home: _ApplicationHost(
      dependencies: dependencies,
      environmentName: environmentName,
      studentId: studentId,
      chooseAvatar: chooseAvatar,
      themeId: visualTheme.id,
      helpGuides: helpGuides ?? ThemeHelpGuideRegistry.standard(),
    ),
  );
}

final class _ApplicationHost extends StatefulWidget {
  const _ApplicationHost({
    required this.dependencies,
    required this.environmentName,
    required this.studentId,
    required this.chooseAvatar,
    required this.themeId,
    required this.helpGuides,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;
  final String studentId;
  final AvatarChooser? chooseAvatar;
  final String themeId;
  final ThemeHelpGuideRegistry helpGuides;

  @override
  State<_ApplicationHost> createState() => _ApplicationHostState();
}

final class _ApplicationHostState extends State<_ApplicationHost> {
  ClinicalCalendarDestination? _destination;
  DestinationEntry _entry = DestinationEntry.direct;
  late final SchedulingCalendarDataSource _calendarDataSource;
  late final PlacementProgressController _placementController;
  late final SupportApplicationService _supportService;
  SupportSnapshot? _support;
  Object? _supportError;
  bool _supportLoading = true;

  @override
  void initState() {
    super.initState();
    final dependencies = widget.dependencies;
    _calendarDataSource = SchedulingCalendarDataSource(
      SchedulingApplicationService(
        dependencies.repositories,
        dependencies.clock,
        dependencies.identifiers,
      ),
    );
    _placementController = PlacementProgressController(
      service: PlacementApplicationService(
        repositories: dependencies.repositories,
        clock: dependencies.clock,
        identifiers: dependencies.identifiers,
        studentId: widget.studentId,
      ),
      studentId: widget.studentId,
    );
    _supportService = SupportApplicationService(
      repositories: dependencies.repositories,
      clock: dependencies.clock,
      identifiers: dependencies.identifiers,
      studentId: widget.studentId,
    );
    unawaited(_placementController.load());
    unawaited(_loadSupport());
  }

  @override
  void dispose() {
    _placementController.dispose();
    super.dispose();
  }

  Future<void> _loadSupport() async {
    if (mounted) {
      setState(() {
        _supportLoading = true;
        _supportError = null;
      });
    }
    try {
      final loaded = await _supportService.load();
      if (!mounted) return;
      setState(() => _support = loaded);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _supportError = error);
    } finally {
      if (mounted) setState(() => _supportLoading = false);
    }
  }

  StudentProfile get _headerProfile =>
      _support?.profile.value ??
      StudentProfile(id: widget.studentId, displayName: 'Student');

  Future<void> _saveProfile(StudentProfile profile) async {
    final snapshot = _support;
    if (snapshot == null) return;
    final saved = await _supportService.saveProfile(
      expectedRevision: snapshot.profile.revision,
      displayName: profile.displayName,
      program: profile.program,
      accountIdentity: profile.accountIdentity,
      avatarBytes: profile.avatarBytes,
    );
    if (!mounted) return;
    setState(
      () => _support = SupportSnapshot(
        profile: saved,
        settings: snapshot.settings,
        scheduleTemplates: snapshot.scheduleTemplates,
      ),
    );
  }

  Future<void> _saveSettings(StudentSettings settings) async {
    final snapshot = _support;
    if (snapshot == null) return;
    final saved = await _supportService.saveSettings(
      expectedRevision: snapshot.settings.revision,
      settings: settings,
    );
    if (!mounted) return;
    setState(
      () => _support = SupportSnapshot(
        profile: snapshot.profile,
        settings: saved,
        scheduleTemplates: snapshot.scheduleTemplates,
      ),
    );
  }

  Future<void> _saveTemplate(ScheduleTemplate template) async {
    final snapshot = _support;
    if (snapshot == null) return;
    StoredSupportRecord<ScheduleTemplate>? existing;
    for (final record in snapshot.scheduleTemplates) {
      if (record.value.id == template.id) existing = record;
    }
    final saved = existing == null
        ? await _supportService.addScheduleTemplate(
            name: template.name,
            type: template.type,
            startTime: template.startTime,
            endTime: template.endTime,
            clinicalPlacementId: template.clinicalPlacementId,
            preceptorId: template.preceptorId,
          )
        : await _supportService.editScheduleTemplate(
            id: template.id,
            expectedRevision: existing.revision,
            name: template.name,
            type: template.type,
            startTime: template.startTime,
            endTime: template.endTime,
            clinicalPlacementId: template.clinicalPlacementId,
            preceptorId: template.preceptorId,
          );
    if (!mounted) return;
    final latest = _support;
    if (latest == null) return;
    setState(
      () => _support = SupportSnapshot(
        profile: latest.profile,
        settings: latest.settings,
        scheduleTemplates: [
          for (final record in latest.scheduleTemplates)
            if (record.value.id != template.id) record,
          saved,
        ],
      ),
    );
  }

  Future<void> _removeTemplate(String templateId) async {
    final snapshot = _support;
    if (snapshot == null) return;
    final record = snapshot.scheduleTemplates.singleWhere(
      (record) => record.value.id == templateId,
    );
    await _supportService.removeScheduleTemplate(
      id: templateId,
      expectedRevision: record.revision,
    );
    if (!mounted) return;
    final latest = _support;
    if (latest == null) return;
    setState(
      () => _support = SupportSnapshot(
        profile: latest.profile,
        settings: latest.settings,
        scheduleTemplates: latest.scheduleTemplates
            .where((record) => record.value.id != templateId)
            .toList(growable: false),
      ),
    );
  }

  Future<void> _showMenu() async {
    final destination = await showModalBottomSheet<ClinicalCalendarDestination>(
      context: context,
      backgroundColor: context.clinicalColors.structureRaised,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 440),
      builder: (context) => SafeArea(
        child: ApplicationMenu(
          onSelected: (destination) => Navigator.pop(context, destination),
        ),
      ),
    );
    if (destination != null && mounted) {
      setState(() {
        _destination = destination;
        _entry = DestinationEntry.applicationMenu;
      });
    }
  }

  void _openDirect(ClinicalCalendarDestination destination) {
    if (destination == ClinicalCalendarDestination.calendar) {
      setState(() => _destination = null);
      return;
    }
    if (destination == ClinicalCalendarDestination.settings) {
      _showMenu();
      return;
    }
    setState(() {
      _destination = destination;
      _entry = DestinationEntry.direct;
    });
  }

  void _exitDestination() {
    final returnToMenu = _entry == DestinationEntry.applicationMenu;
    setState(() => _destination = null);
    if (returnToMenu) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMenu());
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    if (destination != null) {
      return DestinationSurface(
        destination: destination,
        entry: _entry,
        onExit: _exitDestination,
        child: _destinationBody(destination),
      );
    }

    final settings = _support?.settings.value ?? StudentSettings();
    return ResponsiveApplicationShell(
      environmentName: widget.environmentName,
      onOpenMenu: _showMenu,
      onOpenDestination: _openDirect,
      slots: ResponsiveShellSlots(
        placementDock: _PlacementLoadState(
          controller: _placementController,
          onRetry: _placementController.load,
          child: PlacementDock(
            controller: _placementController,
            studentId: widget.studentId,
            onManage: () =>
                _openDirect(ClinicalCalendarDestination.clinicalPlacements),
          ),
        ),
        centralContent: CalendarPeriodView(
          dataSource: _calendarDataSource,
          studentId: widget.studentId,
          today: _today(widget.dependencies.clock),
          weekStartsOn: settings.weekStart,
          twelveHourTime:
              settings.timeDisplay == TimeDisplayPreference.twelveHour,
        ),
        insightRail: _PlacementLoadState(
          controller: _placementController,
          onRetry: _placementController.load,
          child: PlacementProgressRail(
            controller: _placementController,
            studentId: widget.studentId,
          ),
        ),
        mobilePlacementSummary: _PlacementLoadState(
          controller: _placementController,
          onRetry: _placementController.load,
          child: PlacementMobileSummary(
            controller: _placementController,
            studentId: widget.studentId,
          ),
        ),
        planningRegion: const _PlanningRegion(),
        profileAvatar: ProfileAvatarButton(
          profile: _headerProfile,
          onPressed: () =>
              _openDirect(ClinicalCalendarDestination.studentProfile),
        ),
      ),
    );
  }

  Widget _destinationBody(ClinicalCalendarDestination destination) {
    switch (destination) {
      case ClinicalCalendarDestination.clinicalPlacements:
        return PlacementManagementSurface(
          controller: _placementController,
          studentId: widget.studentId,
        );
      case ClinicalCalendarDestination.studentProfile:
        return _supportBody(
          (snapshot) => StudentProfileSurface(
            profile: snapshot.profile.value,
            chooseAvatar: widget.chooseAvatar ?? () async => null,
            onSave: _saveProfile,
          ),
        );
      case ClinicalCalendarDestination.settings:
        return _supportBody(
          (snapshot) => SettingsTemplatesSurface(
            settings: snapshot.settings.value,
            scheduleTemplates: snapshot.scheduleTemplates
                .map((record) => record.value)
                .toList(growable: false),
            clinicalDefaults: _clinicalDefaults,
            newTemplateId: widget.dependencies.identifiers.nextIdentifier,
            onSaveSettings: _saveSettings,
            onSaveTemplate: _saveTemplate,
            onRemoveTemplate: _removeTemplate,
          ),
        );
      case ClinicalCalendarDestination.help:
        return SupportHelpSurface(
          themeGuide: widget.helpGuides.resolve(widget.themeId),
        );
      case ClinicalCalendarDestination.calendar:
      case ClinicalCalendarDestination.planning:
      case ClinicalCalendarDestination.notifications:
        return _PendingDestination(destination: destination);
    }
  }

  Widget _supportBody(Widget Function(SupportSnapshot snapshot) ready) {
    final snapshot = _support;
    if (_supportLoading && snapshot == null) {
      return const _DestinationLoading(label: 'Loading student data');
    }
    if (_supportError != null && snapshot == null) {
      return _DestinationFailure(
        message: 'Student data could not be loaded.',
        onRetry: _loadSupport,
      );
    }
    return ready(snapshot!);
  }

  List<ClinicalTemplateDefaultOption> get _clinicalDefaults => [
    for (final placement in _placementController.placements)
      for (final attached in placement.attachedPreceptors)
        ClinicalTemplateDefaultOption(
          clinicalPlacementId: placement.placement.id,
          preceptorId: attached.preceptor.id,
          label:
              '${placement.placement.name} · ${attached.preceptor.name}'
              '${attached.isPrimary ? ' (Primary)' : ''}',
        ),
  ];
}

final class _PlanningRegion extends StatelessWidget {
  const _PlanningRegion();

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Planning',
    accent: context.clinicalColors.scheduled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Build the monthly plan in this in-flow region.'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('primary-planning-action'),
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add schedule'),
          ),
        ),
      ],
    ),
  );
}

final class _PlacementLoadState extends StatelessWidget {
  const _PlacementLoadState({
    required this.controller,
    required this.onRetry,
    required this.child,
  });

  final PlacementProgressController controller;
  final Future<void> Function() onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.isBusy && controller.placements.isEmpty) {
        return const _DestinationLoading(label: 'Loading placements');
      }
      if (controller.error != null && controller.placements.isEmpty) {
        return _DestinationFailure(
          message: 'Clinical Placements could not be loaded.',
          onRetry: onRetry,
        );
      }
      return child;
    },
  );
}

final class _DestinationLoading extends StatelessWidget {
  const _DestinationLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: label,
      child: const SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

final class _DestinationFailure extends StatelessWidget {
  const _DestinationFailure({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

final class _PendingDestination extends StatelessWidget {
  const _PendingDestination({required this.destination});

  final ClinicalCalendarDestination destination;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: ShellPanel(
      label: destination.label,
      child: Text('${destination.label} opens from the calendar workflow.'),
    ),
  );
}

LocalDate _today(Clock clock) {
  final now = clock.nowUtc();
  return LocalDate(now.year, now.month, now.day);
}
