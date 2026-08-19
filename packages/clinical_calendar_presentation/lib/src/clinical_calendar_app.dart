import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calendar/calendar_data_source.dart';
import 'calendar/calendar_models.dart';
import 'calendar/calendar_period_view.dart';
import 'assignments/academic_assignment_surface.dart';
import 'backup/backup_restore_surface.dart';
import 'code_only_presentation_recovery.dart';
import 'commitments/commitment_lifecycle_controller.dart';
import 'commitments/commitment_lifecycle_surface.dart';
import 'conflict_resolution/conflict_resolution_controller.dart';
import 'conflict_resolution/conflict_resolution_surface.dart';
import 'coastal_light_panel_scope.dart';
import 'evaluation_attention/attention_surfaces.dart';
import 'evaluation_attention/evaluation_attention_controller.dart';
import 'evaluation_attention/evaluation_plan_surface.dart';
import 'exports/export_surface.dart';
import 'federation_2399_console_scope.dart';
import 'enhanced_accessibility_controller.dart';
import 'enhanced_focus_perimeter.dart';
import 'graphite_frame.dart';
import 'graphite_shell.dart';
import 'heritage_field_notes_panel_scope.dart';
import 'identity/identity_devices_surface.dart';
import 'placements/placement_management_surface.dart';
import 'placements/placement_progress_controller.dart';
import 'placements/placement_progress_widgets.dart';
import 'recovery/trash_recovery_surface.dart';
import 'responsive_shell.dart';
import 'scheduling/batch_scheduling_controller.dart';
import 'scheduling/staged_batch_scheduling_tray.dart';
import 'support/profile_avatar_button.dart';
import 'support/settings_templates_surface.dart';
import 'support/student_profile_onboarding_dialog.dart';
import 'support/student_profile_surface.dart';
import 'support/support_help_surface.dart';
import 'theme_contract.dart';
import 'theme_preview_control.dart';
import 'theme_preview_controller.dart';
import 'variant_f_theme.dart';

typedef ExportWorkflowFactory =
    ExportWorkflowService Function(ExportReauthenticationGate gate);
typedef ScheduleDateFactory = ZonedScheduleDate Function(LocalDate date);
typedef CandidateThemePreflight =
    Future<void> Function(ClinicalCalendarThemeBundle candidate);
typedef TodayResolver = LocalDate Function(DateTime nowUtc);

const _androidMemoryLifecycle = MethodChannel(
  'com.clinicalcalendar.clinical_calendar/memory_lifecycle',
);

@visibleForTesting
List<AssetImage> inactiveThemeFrameProviders({
  required ClinicalCalendarThemeBundleRegistry registry,
  required String activeThemeId,
}) {
  final active = registry.resolveApplied(activeThemeId).bundle;
  final activeProviders = {
    for (final assetPath in active.frame.assetPaths)
      AssetImage(assetPath, package: active.frame.assetPackage),
  };
  return [
    for (final bundle in registry.galleryBundles)
      if (bundle.id != activeThemeId)
        for (final assetPath in bundle.frame.assetPaths)
          if (!activeProviders.contains(
            AssetImage(assetPath, package: bundle.frame.assetPackage),
          ))
            AssetImage(assetPath, package: bundle.frame.assetPackage),
  ];
}

@visibleForTesting
Future<void> evictInactiveThemeFrameAssets({
  required BuildContext context,
  required ClinicalCalendarThemeBundleRegistry registry,
  required String activeThemeId,
  bool clearLiveImages = true,
}) async {
  final configuration = createLocalImageConfiguration(context);
  final cache = PaintingBinding.instance.imageCache;
  for (final provider in inactiveThemeFrameProviders(
    registry: registry,
    activeThemeId: activeThemeId,
  )) {
    final key = await provider.obtainKey(configuration);
    cache.evict(key, includeLive: true);
  }
  // The Gallery's resized thumbnails use derived cache keys rather than the
  // source-provider keys evicted above. Clear those non-live entries after the
  // route disposes. Clearing live-image bookkeeping removes listener handles;
  // it does not evict the active Calendar frame from the cache, so that frame
  // remains available without a second decode.
  cache.clear();
  if (clearLiveImages) cache.clearLiveImages();
}

final class ClinicalCalendarApp extends StatefulWidget {
  const ClinicalCalendarApp({
    required this.dependencies,
    required this.environmentName,
    required this.studentId,
    this.chooseAvatar,
    this.themeId = variantFThemeId,
    this.enhancedAccessibility = false,
    this.enhancedAccessibilityController,
    this.themePreviewController,
    this.candidateThemePreflight,
    this.onLaunchOrResume,
    this.connectivityChanges,
    this.onConnectivityChanged,
    this.onRealtimeHint,
    this.notificationInteractions,
    this.notificationDevicePolicyStore,
    this.notificationDeviceClass,
    this.identity,
    this.identityEmail,
    this.onLocalCopyRemoved,
    this.createAccountBackup,
    this.portableBackupWorkflows,
    this.exportWorkflowFactory,
    this.recoveryStore,
    this.recoveryService,
    this.recoveryProofGate,
    this.scheduleDateFactory,
    this.todayResolver,
    this.onPresentationRestart,
    super.key,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;
  final String studentId;
  final AvatarChooser? chooseAvatar;
  final String themeId;
  final bool enhancedAccessibility;
  final EnhancedAccessibilityController? enhancedAccessibilityController;
  final ThemePreviewController? themePreviewController;
  final CandidateThemePreflight? candidateThemePreflight;
  final Future<void> Function()? onLaunchOrResume;
  final Stream<bool>? connectivityChanges;
  final Future<void> Function(bool connected)? onConnectivityChanged;

  /// Reserved for the realtime subscription owned by the authentication
  /// integration. Realtime is only a wake hint; durable pull remains truth.
  final Future<void> Function()? onRealtimeHint;
  final Stream<NotificationInteraction>? notificationInteractions;
  final NotificationDevicePolicyStore? notificationDevicePolicyStore;
  final NotificationDeviceClass? notificationDeviceClass;
  final PasswordlessIdentityService? identity;
  final String? identityEmail;
  final Future<void> Function()? onLocalCopyRemoved;
  final Future<bool> Function(String passphrase)? createAccountBackup;
  final PortableBackupWorkflows? portableBackupWorkflows;
  final ExportWorkflowFactory? exportWorkflowFactory;
  final RecoveryStore? recoveryStore;
  final RecoveryApplicationService? recoveryService;
  final OneShotRecoveryReauthenticationGate? recoveryProofGate;
  final ScheduleDateFactory? scheduleDateFactory;
  final TodayResolver? todayResolver;
  final VoidCallback? onPresentationRestart;

  LocalDate resolveToday() => _resolveToday(dependencies, todayResolver);

  @override
  State<ClinicalCalendarApp> createState() => _ClinicalCalendarAppState();
}

final class _ClinicalCalendarAppState extends State<ClinicalCalendarApp> {
  final _applicationHostKey = GlobalKey<_ApplicationHostState>();
  late ThemePreviewController _themePreview;
  late bool _ownsThemePreview;
  late EnhancedAccessibilityController _enhancedAccessibility;
  late bool _ownsEnhancedAccessibility;
  bool _useImmediateTheme = false;
  int _themeChangeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _adoptThemePreviewController();
    _adoptEnhancedAccessibilityController();
  }

  @override
  void didUpdateWidget(ClinicalCalendarApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themePreviewController != widget.themePreviewController) {
      _themePreview.removeListener(_presentationChanged);
      if (_ownsThemePreview) _themePreview.dispose();
      _adoptThemePreviewController();
    }
    if (oldWidget.enhancedAccessibilityController !=
        widget.enhancedAccessibilityController) {
      _enhancedAccessibility.removeListener(_presentationChanged);
      if (_ownsEnhancedAccessibility) _enhancedAccessibility.dispose();
      _adoptEnhancedAccessibilityController();
    }
  }

  void _adoptThemePreviewController() {
    _ownsThemePreview = widget.themePreviewController == null;
    _themePreview =
        widget.themePreviewController ??
        ThemePreviewController(
          registry: ClinicalCalendarThemeBundleRegistry.standard,
          authoritativeThemeId: widget.themeId,
          initialRevision: 0,
        );
    _themePreview.addListener(_presentationChanged);
  }

  void _adoptEnhancedAccessibilityController() {
    _ownsEnhancedAccessibility = widget.enhancedAccessibilityController == null;
    _enhancedAccessibility =
        widget.enhancedAccessibilityController ??
        EnhancedAccessibilityController(
          initialValue: widget.enhancedAccessibility,
        );
    _enhancedAccessibility.addListener(_presentationChanged);
  }

  void _presentationChanged() {
    if (!mounted) return;
    final generation = ++_themeChangeGeneration;
    setState(() => _useImmediateTheme = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _themeChangeGeneration) return;
      setState(() => _useImmediateTheme = false);
    });
  }

  @override
  void dispose() {
    _themePreview.removeListener(_presentationChanged);
    if (_ownsThemePreview) _themePreview.dispose();
    _enhancedAccessibility.removeListener(_presentationChanged);
    if (_ownsEnhancedAccessibility) _enhancedAccessibility.dispose();
    super.dispose();
  }

  Future<void> _previewTheme(String themeId) => _themePreview.preview(
    themeId,
    preflight: widget.candidateThemePreflight ?? _preflightCandidate,
  );

  Future<void> _preflightCandidate(
    ClinicalCalendarThemeBundle candidate,
  ) async {
    final candidateTheme = candidate.standardPresentation.createThemeData(
      enhancedAccessibility: _enhancedAccessibility.enabled,
    );
    for (final assetPath in candidate.frame.assetPaths) {
      Object? decodeError;
      StackTrace? decodeStack;
      await precacheImage(
        AssetImage(assetPath, package: candidate.frame.assetPackage),
        context,
        onError: (error, stackTrace) {
          decodeError = error;
          decodeStack = stackTrace;
        },
      );
      if (decodeError != null) {
        Error.throwWithStackTrace(
          decodeError!,
          decodeStack ?? StackTrace.current,
        );
      }
    }

    if (!mounted) {
      throw StateError('The live application host is unavailable.');
    }
    final hostContext = _applicationHostKey.currentContext;
    if (hostContext == null || !hostContext.mounted) {
      throw StateError('The live application host is unavailable.');
    }
    final overlay = Overlay.of(hostContext, rootOverlay: true);
    final mountedCandidateKey = GlobalKey();
    final entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Offstage(
          offstage: true,
          child: Theme(
            data: candidateTheme,
            child: ClinicalCalendarSemanticMarkScope(
              marks: candidate.marks,
              child: KeyedSubtree(
                key: mountedCandidateKey,
                child: candidate.shellRenderer.build(
                  environmentName: widget.environmentName,
                  onOpenMenu: () {},
                  onOpenDestination: (_) {},
                  onOpenAttention: () {},
                  onAddSchedule: () {},
                  slots: const ResponsiveShellSlots(
                    centralContent: SizedBox.expand(),
                    planningRegion: SizedBox.expand(),
                    placementDock: SizedBox.expand(),
                    insightRail: SizedBox.expand(),
                    mobilePlacementSummary: SizedBox.expand(),
                    mobileAttention: SizedBox.expand(),
                    profileAvatar: SizedBox.square(dimension: 44),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = mountedCandidateKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize) {
        throw StateError('The candidate renderer did not complete layout.');
      }
    } finally {
      entry.remove();
    }
  }

  Future<void> _applyThemePreview() async {
    final host = _applicationHostKey.currentState;
    if (host == null) return;
    await host.applyThemePreview();
    if (!_themePreview.isPreviewing) {
      await host.releaseThemeTransitionMemory();
    }
  }

  void _revertThemePreview() {
    _themePreview.revert();
    final host = _applicationHostKey.currentState;
    if (host != null) {
      unawaited(host.releaseThemeTransitionMemory());
    }
  }

  Future<void> _launchOrResume() async {
    await widget.onLaunchOrResume?.call();
    await _applicationHostKey.currentState?.refreshAuthoritativeSettings();
  }

  Future<void> _connectivityChanged(bool connected) async {
    await widget.onConnectivityChanged?.call(connected);
    await _applicationHostKey.currentState?.refreshAuthoritativeSettings();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final themeBundle = _themePreview.effectiveBundle;
      final standardTheme = themeBundle.standardPresentation.createThemeData(
        enhancedAccessibility: _enhancedAccessibility.enabled,
      );
      final theme = _useImmediateTheme
          ? _withoutControlInterpolation(standardTheme)
          : standardTheme;
      return GraphitePresentationFailureBoundary(
        onRestart: widget.onPresentationRestart,
        onBundleFailure: _themePreview.handleRuntimeBundleFailure,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Clinical Calendar',
          theme: theme,
          themeAnimationDuration: Duration.zero,
          builder: (context, child) => EnhancedGlobalFocusOverlay(
            child: Stack(
              fit: StackFit.expand,
              children: [
                child ?? const SizedBox.shrink(),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: ThemePreviewControl(
                      controller: _themePreview,
                      onApply: _applyThemePreview,
                      onRevert: _revertThemePreview,
                    ),
                  ),
                ),
              ],
            ),
          ),
          home: ClinicalCalendarLifecycleHost(
            onLaunchOrResume: _launchOrResume,
            connectivityChanges: widget.connectivityChanges,
            onConnectivityChanged: widget.onConnectivityChanged == null
                ? null
                : _connectivityChanged,
            child: ClinicalCalendarSemanticMarkScope(
              marks: themeBundle.marks,
              child: _ApplicationHost(
                key: _applicationHostKey,
                dependencies: widget.dependencies,
                environmentName: widget.environmentName,
                studentId: widget.studentId,
                chooseAvatar: widget.chooseAvatar,
                themeBundle: themeBundle,
                themePreviewController: _themePreview,
                enhancedAccessibilityController: _enhancedAccessibility,
                onPreviewTheme: _previewTheme,
                identity: widget.identity,
                identityEmail: widget.identityEmail,
                onLocalCopyRemoved: widget.onLocalCopyRemoved,
                createAccountBackup: widget.createAccountBackup,
                portableBackupWorkflows: widget.portableBackupWorkflows,
                exportWorkflowFactory: widget.exportWorkflowFactory,
                recoveryStore: widget.recoveryStore,
                recoveryService: widget.recoveryService,
                recoveryProofGate: widget.recoveryProofGate,
                notificationInteractions: widget.notificationInteractions,
                notificationDevicePolicyStore:
                    widget.notificationDevicePolicyStore,
                notificationDeviceClass: widget.notificationDeviceClass,
                scheduleDateFactory: widget.scheduleDateFactory,
                todayResolver: widget.todayResolver,
              ),
            ),
          ),
        ),
      );
    } on Object {
      final restart = widget.onPresentationRestart;
      return CodeOnlyPresentationRecoveryApplication(
        surfaceKey: const Key('theme-construction-recovery'),
        icon: Icons.restart_alt,
        title: 'Presentation could not start.',
        guidance:
            'No Calendar or Student data was displayed. Restart the '
            'presentation. If this continues, record the app version '
            'and device model for Help.',
        actionLabel: restart == null ? 'Close app' : 'Restart',
        actionKey: const Key('restart-presentation'),
        onAction: restart ?? SystemNavigator.pop,
      );
    }
  }
}

ThemeData _withoutControlInterpolation(ThemeData theme) {
  ButtonStyle immediate(ButtonStyle? style) =>
      (style ?? const ButtonStyle()).copyWith(animationDuration: Duration.zero);
  return theme.copyWith(
    textButtonTheme: TextButtonThemeData(
      style: immediate(theme.textButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: immediate(theme.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: immediate(theme.outlinedButtonTheme.style),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: immediate(theme.elevatedButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: immediate(theme.iconButtonTheme.style),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: immediate(theme.segmentedButtonTheme.style),
    ),
  );
}

/// Bridges Flutter host lifecycle/connectivity events into synchronization.
final class ClinicalCalendarLifecycleHost extends StatefulWidget {
  const ClinicalCalendarLifecycleHost({
    required this.child,
    this.onLaunchOrResume,
    this.connectivityChanges,
    this.onConnectivityChanged,
    super.key,
  });

  final Widget child;
  final Future<void> Function()? onLaunchOrResume;
  final Stream<bool>? connectivityChanges;
  final Future<void> Function(bool connected)? onConnectivityChanged;

  @override
  State<ClinicalCalendarLifecycleHost> createState() =>
      _ClinicalCalendarLifecycleHostState();
}

final class _ClinicalCalendarLifecycleHostState
    extends State<ClinicalCalendarLifecycleHost>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeConnectivity();
    _invoke(widget.onLaunchOrResume);
  }

  @override
  void didUpdateWidget(ClinicalCalendarLifecycleHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectivityChanges != widget.connectivityChanges) {
      unawaited(_connectivitySubscription?.cancel());
      _subscribeConnectivity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _invoke(widget.onLaunchOrResume);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }

  void _subscribeConnectivity() {
    final changes = widget.connectivityChanges;
    final callback = widget.onConnectivityChanged;
    if (changes == null || callback == null) return;
    _connectivitySubscription = changes.listen(
      (connected) => _invoke(() => callback(connected)),
    );
  }

  void _invoke(Future<void> Function()? callback) {
    if (callback == null) return;
    unawaited(callback().catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final class _ApplicationHost extends StatefulWidget {
  const _ApplicationHost({
    required this.dependencies,
    required this.environmentName,
    required this.studentId,
    required this.chooseAvatar,
    required this.themeBundle,
    required this.themePreviewController,
    required this.enhancedAccessibilityController,
    required this.onPreviewTheme,
    required this.identity,
    required this.identityEmail,
    required this.onLocalCopyRemoved,
    required this.createAccountBackup,
    required this.portableBackupWorkflows,
    required this.exportWorkflowFactory,
    required this.recoveryStore,
    required this.recoveryService,
    required this.recoveryProofGate,
    required this.notificationInteractions,
    required this.notificationDevicePolicyStore,
    required this.notificationDeviceClass,
    required this.scheduleDateFactory,
    required this.todayResolver,
    super.key,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;
  final String studentId;
  final AvatarChooser? chooseAvatar;
  final ClinicalCalendarThemeBundle themeBundle;
  final ThemePreviewController themePreviewController;
  final EnhancedAccessibilityController enhancedAccessibilityController;
  final Future<void> Function(String themeId) onPreviewTheme;
  final PasswordlessIdentityService? identity;
  final String? identityEmail;
  final Future<void> Function()? onLocalCopyRemoved;
  final Future<bool> Function(String passphrase)? createAccountBackup;
  final PortableBackupWorkflows? portableBackupWorkflows;
  final ExportWorkflowFactory? exportWorkflowFactory;
  final RecoveryStore? recoveryStore;
  final RecoveryApplicationService? recoveryService;
  final OneShotRecoveryReauthenticationGate? recoveryProofGate;
  final Stream<NotificationInteraction>? notificationInteractions;
  final NotificationDevicePolicyStore? notificationDevicePolicyStore;
  final NotificationDeviceClass? notificationDeviceClass;
  final ScheduleDateFactory? scheduleDateFactory;
  final TodayResolver? todayResolver;

  @override
  State<_ApplicationHost> createState() => _ApplicationHostState();
}

final class _ApplicationHostState extends State<_ApplicationHost> {
  ClinicalCalendarDestination? _destination;
  DestinationEntry _entry = DestinationEntry.direct;
  late final SchedulingApplicationService _schedulingService;
  late final SchedulingCalendarDataSource _schedulingCalendarDataSource;
  late final AcademicAssignmentCalendarDataSource _assignmentCalendarDataSource;
  late final AcademicAssignmentApplicationService _academicAssignmentService;
  late final ClassCatalogApplicationService _classCatalogService;
  late final PlacementProgressController _placementController;
  late final CommitmentLifecycleController _commitmentController;
  late final EvaluationAttentionController _attentionController;
  late final ConflictResolutionController _conflictController;
  BatchSchedulingController? _batchController;
  final _planningRegionKey = GlobalKey<_PlanningRegionState>();
  final _destinationContentKey = GlobalKey();
  final _calendarContentKey = GlobalKey();
  final _placementDockContentKey = GlobalKey();
  final _insightRailContentKey = GlobalKey();
  final _mobilePlacementContentKey = GlobalKey();
  final _mobileAttentionContentKey = GlobalKey();
  late final SupportApplicationService _supportService;
  Set<LocalDate> _selectedDates = const {};
  int _calendarRevision = 0;
  SupportSnapshot? _support;
  Object? _supportError;
  bool _supportLoading = true;
  StreamSubscription<NotificationInteraction>? _notificationSubscription;
  NotificationDevicePolicy? _notificationDevicePolicy;
  Timer? _profileOnboardingTimer;
  bool _profileOnboardingOpen = false;

  @override
  void initState() {
    super.initState();
    final dependencies = widget.dependencies;
    _schedulingService = SchedulingApplicationService(
      dependencies.repositories,
      dependencies.clock,
      dependencies.identifiers,
    );
    _schedulingCalendarDataSource = SchedulingCalendarDataSource(
      _schedulingService,
    );
    _academicAssignmentService = AcademicAssignmentApplicationService(
      repositories: dependencies.repositories,
      clock: dependencies.clock,
      identifiers: dependencies.identifiers,
      studentId: widget.studentId,
    );
    _classCatalogService = ClassCatalogApplicationService(
      repositories: dependencies.repositories,
      clock: dependencies.clock,
      identifiers: dependencies.identifiers,
      studentId: widget.studentId,
    );
    _assignmentCalendarDataSource = AcademicAssignmentCalendarDataSource(
      base: _schedulingCalendarDataSource,
      assignments: _academicAssignmentService,
    );
    final placementService = PlacementApplicationService(
      repositories: dependencies.repositories,
      clock: dependencies.clock,
      identifiers: dependencies.identifiers,
      studentId: widget.studentId,
    );
    _placementController = PlacementProgressController(
      service: placementService,
      studentId: widget.studentId,
    );
    _attentionController = EvaluationAttentionController(
      service: EvaluationAttentionApplicationService(
        placements: PlacementEvaluationGateway(placementService),
        attentionSource: LocalAttentionRepositorySource(
          dependencies.repositories,
        ),
        clock: dependencies.clock,
        studentId: widget.studentId,
      ),
    );
    _commitmentController = CommitmentLifecycleController(
      service: _schedulingService,
      studentId: widget.studentId,
      onChanged: _reloadSchedulingSurfaces,
    );
    _conflictController = ConflictResolutionController(
      ConflictResolutionApplicationService(
        repositories: dependencies.repositories,
        clock: dependencies.clock,
        identifiers: dependencies.identifiers,
        studentId: widget.studentId,
        synchronization: dependencies.synchronization,
      ),
    );
    _supportService = SupportApplicationService(
      repositories: dependencies.repositories,
      clock: dependencies.clock,
      identifiers: dependencies.identifiers,
      studentId: widget.studentId,
    );
    _notificationSubscription = widget.notificationInteractions?.listen(
      (interaction) => unawaited(_handleNotificationInteraction(interaction)),
    );
    unawaited(_initializeScheduling());
    if (widget.identityEmail != null) {
      _profileOnboardingTimer = Timer(
        const Duration(seconds: 2),
        () => unawaited(_refreshSupportAndOfferOnboarding()),
      );
    }
  }

  @override
  void dispose() {
    _batchController?.dispose();
    _commitmentController.dispose();
    _attentionController.dispose();
    _conflictController.dispose();
    _placementController.dispose();
    _profileOnboardingTimer?.cancel();
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }

  Future<void> _initializeScheduling() async {
    await Future.wait([
      _placementController.load(),
      _attentionController.load(),
      _loadSupport(),
      _loadNotificationDevicePolicy(),
    ]);
    if (!mounted) return;
    _replaceBatchController();
  }

  void _replaceBatchController({
    BatchSchedulingReset reset = BatchSchedulingReset.addSchedule,
  }) {
    final previous = _batchController;
    previous?.removeListener(_synchronizeSelectedDatesFromBatch);
    previous?.dispose();
    final controller = BatchSchedulingController(
      operations: _ReloadingBatchOperations(
        SchedulingBatchCoordinator(_schedulingService),
        _reloadSchedulingSurfaces,
      ),
      studentId: widget.studentId,
      placements: _batchPlacementOptions,
      templates:
          _support?.scheduleTemplates.map((record) => record.value) ?? const [],
      selectedDates: _selectedDates.map(_scheduleDate),
      useTwelveHourTime:
          (_support?.settings.value.timeDisplay ??
              TimeDisplayPreference.military) ==
          TimeDisplayPreference.twelveHour,
      activeClinicalPlacementId: _placementController.activePlacementId,
      reset: reset,
    );
    controller.addListener(_synchronizeSelectedDatesFromBatch);
    setState(() => _batchController = controller);
  }

  void _synchronizeSelectedDatesFromBatch() {
    final controller = _batchController;
    if (!mounted || controller == null) return;
    final next = controller.selectedDates.map((value) => value.date).toSet();
    if (_sameDates(_selectedDates, next)) return;
    setState(() => _selectedDates = Set.unmodifiable(next));
  }

  void _updateCalendarSelection(Set<LocalDate> dates) {
    final next = Set<LocalDate>.unmodifiable(dates);
    if (!_sameDates(_selectedDates, next)) {
      setState(() => _selectedDates = next);
    }
    final controller = _batchController;
    if (controller == null) return;
    final current = controller.selectedDates.map((value) => value.date).toSet();
    for (final date in current.difference(next)) {
      controller.toggleDate(_scheduleDate(date));
    }
    for (final date in next.difference(current)) {
      controller.toggleDate(_scheduleDate(date));
    }
  }

  ZonedScheduleDate _scheduleDate(LocalDate date) =>
      widget.scheduleDateFactory?.call(date) ?? _zonedScheduleDate(date);

  void _resetPlanning(BatchSchedulingReset reset) {
    final controller = _batchController;
    if (controller == null) return;
    controller.reset(
      reset,
      activeClinicalPlacementId: _placementController.activePlacementId,
    );
  }

  void _openPlanning() => _openPlanningFor(BatchSchedulingReset.addSchedule);

  void _openPlanningFor(BatchSchedulingReset reset) {
    _resetPlanning(reset);
    _planningRegionKey.currentState?.expand();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _planningRegionKey.currentState?.expand();
      final context = _planningRegionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          alignment: .1,
        );
      }
    });
  }

  Future<void> _reloadSchedulingSurfaces() async {
    if (mounted) setState(() => _calendarRevision++);
    await Future.wait([
      _placementController.load(),
      _attentionController.load(),
      _reconcileNotifications(),
    ]);
  }

  Future<void> _afterPlacementDeleted() async {
    _selectedDates = const {};
    await Future.wait([_loadSupport(), _reloadSchedulingSurfaces()]);
    if (mounted) _replaceBatchController();
  }

  Future<void> _reconcileNotifications() async {
    try {
      await widget.dependencies.notifications.reconcileScheduledNotifications();
    } on Object {
      // Native delivery availability must never block the student workflow.
    }
  }

  Future<void> _loadNotificationDevicePolicy() async {
    final store = widget.notificationDevicePolicyStore;
    final deviceClass = widget.notificationDeviceClass;
    if (store == null || deviceClass == null) return;
    final stored = await store.read(deviceClass);
    if (!mounted) return;
    setState(
      () => _notificationDevicePolicy =
          stored ?? NotificationDevicePolicy(deviceClass: deviceClass),
    );
  }

  Future<void> _saveNotificationDevicePreferences(
    DeviceNotificationPreferences preferences,
  ) async {
    final store = widget.notificationDevicePolicyStore;
    final deviceClass = widget.notificationDeviceClass;
    if (store == null || deviceClass == null) return;
    final policy = NotificationDevicePolicy(
      deviceClass: deviceClass,
      enabled: preferences.deliveryEnabled,
      detailedPreview: preferences.detailedPreview,
      quietStartsAtHour: preferences.quietStartsAtHour,
      quietStartsAtMinute: preferences.quietStartsAtMinute,
      quietEndsAtHour: preferences.quietEndsAtHour,
      quietEndsAtMinute: preferences.quietEndsAtMinute,
    );
    await store.write(policy);
    if (mounted) setState(() => _notificationDevicePolicy = policy);
    await _reconcileNotifications();
  }

  Future<void> _handleNotificationInteraction(
    NotificationInteraction interaction,
  ) async {
    if (!mounted) return;
    final route = Uri.tryParse(interaction.route);
    final segments = route?.pathSegments ?? const <String>[];
    if (segments.length < 2 || segments.first != 'reminders') return;
    switch (segments[1]) {
      case 'summary':
        _openAttentionCenter();
      case 'commitment':
        if (segments.length != 4) return;
        final kind = switch (segments[2]) {
          'work' => CommitmentLifecycleKind.workShift,
          'clinical' => CommitmentLifecycleKind.clinicalSession,
          _ => null,
        };
        if (kind != null) {
          await _openCommitmentLifecycle(kind: kind, id: segments[3]);
        }
      case 'planning':
        if (segments.length != 3) return;
        final parts = segments[2].split('-').map(int.tryParse).toList();
        if (parts.length != 3 || parts.any((value) => value == null)) return;
        final date = LocalDate(parts[0]!, parts[1]!, parts[2]!);
        _updateCalendarSelection({..._selectedDates, date});
        if (!mounted) return;
        setState(() => _destination = null);
        _openPlanningFor(BatchSchedulingReset.planningIncomplete);
      case 'evaluation':
        if (segments.length != 3) return;
        _attentionController.selectPlacement(segments[2]);
        await _openContextualRoute(
          title: 'Evaluation Plan',
          child: EvaluationPlanSurface(controller: _attentionController),
        );
        await _reloadSchedulingSurfaces();
      case 'backup':
        await _openContextualRoute(
          title: 'Portable Backup',
          child: _portableBackupSurface(),
        );
      case 'synchronization':
        await _openSynchronization();
    }
  }

  Future<void> _openCommitment(CalendarItemReference reference) async {
    if (reference.kind == CalendarEntryKind.academicAssignment) {
      await _openAcademicAssignment(reference.id);
      return;
    }
    final kind = switch (reference.kind) {
      CalendarEntryKind.workShift => CommitmentLifecycleKind.workShift,
      CalendarEntryKind.clinicalSession =>
        CommitmentLifecycleKind.clinicalSession,
      CalendarEntryKind.protectedDay => CommitmentLifecycleKind.protectedDay,
      CalendarEntryKind.academicAssignment => throw StateError(
        'Academic Assignments use their dedicated editor.',
      ),
    };
    await _openCommitmentLifecycle(kind: kind, id: reference.id);
  }

  Future<void> _openAcademicAssignment([String? assignmentId]) async {
    StoredDomainRecord<AcademicAssignment>? record;
    if (assignmentId != null) {
      try {
        record = await _academicAssignmentService.find(assignmentId);
      } on Object catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignment could not be opened: $error')),
          );
        }
        return;
      }
      if (record == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment was not found.')),
          );
        }
        return;
      }
    }
    var catalogEntries = await _classCatalogService.list(includeArchived: true);
    if (record == null &&
        !catalogEntries.any((entry) => !entry.value.isArchived)) {
      await _openClassCatalog();
      catalogEntries = await _classCatalogService.list(includeArchived: true);
      if (!catalogEntries.any((entry) => !entry.value.isArchived)) return;
    }
    if (!mounted) return;
    final current = record;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            width: size.width < 720 ? size.width - 24 : 620,
            height: size.height * .9,
            child: AcademicAssignmentEditor(
              record: current,
              catalogEntries: catalogEntries,
              onClose: () => Navigator.pop(dialogContext),
              onSave:
                  ({
                    required title,
                    required course,
                    required courseId,
                    required dueDate,
                    required status,
                  }) async {
                    if (current == null) {
                      await _academicAssignmentService.create(
                        title: title,
                        courseId: courseId!,
                        dueDate: dueDate,
                      );
                    } else {
                      await _academicAssignmentService.update(
                        assignmentId: current.value.id,
                        expectedRevision: current.revision,
                        title: title,
                        courseId: courseId,
                        dueDate: dueDate,
                        status: status,
                      );
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
              onDelete: current == null
                  ? null
                  : () async {
                      await _academicAssignmentService.delete(
                        assignmentId: current.value.id,
                        expectedRevision: current.revision,
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    },
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _calendarRevision++);
  }

  Future<void> _openClassCatalog() async {
    Future<List<StoredDomainRecord<ClassCatalogEntry>>> reload() =>
        _classCatalogService.list(includeArchived: true);

    var entries = await reload();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            width: size.width < 720 ? size.width - 24 : 620,
            height: size.height * .9,
            child: ClassCatalogManager(
              initialEntries: entries,
              onClose: () => Navigator.pop(dialogContext),
              onAdd: (name) async {
                await _classCatalogService.create(name: name);
                entries = await reload();
                return entries;
              },
              onRename: (record, name) async {
                await _classCatalogService.rename(
                  entryId: record.value.id,
                  expectedRevision: record.revision,
                  name: name,
                );
                entries = await reload();
                return entries;
              },
              onSetArchived: (record, archived) async {
                await _classCatalogService.setArchived(
                  entryId: record.value.id,
                  expectedRevision: record.revision,
                  archived: archived,
                );
                entries = await reload();
                return entries;
              },
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _calendarRevision++);
  }

  Future<void> _openCommitmentLifecycle({
    required CommitmentLifecycleKind kind,
    required String id,
  }) async {
    await _commitmentController.open(kind: kind, id: id);
    if (!mounted || _commitmentController.snapshot == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            width: size.width < 720 ? size.width - 24 : 700,
            height: size.height * .9,
            child: CommitmentLifecycleSurface(
              controller: _commitmentController,
              studentId: widget.studentId,
              twelveHourTime:
                  (_support?.settings.value.timeDisplay ??
                      TimeDisplayPreference.military) ==
                  TimeDisplayPreference.twelveHour,
              onClose: () => Navigator.pop(dialogContext),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAttentionItem(AttentionItem item) async {
    switch (item.destination) {
      case AttentionDestination.confirmClinicalSession:
        final id = item.clinicalSessionId;
        if (id == null) return;
        await _openCommitmentLifecycle(
          kind: CommitmentLifecycleKind.clinicalSession,
          id: id,
        );
      case AttentionDestination.planProtectedDay:
        final date = item.suggestedDate;
        if (date != null) {
          _updateCalendarSelection({..._selectedDates, date});
        }
        if (!mounted) return;
        setState(() => _destination = null);
        _openPlanningFor(BatchSchedulingReset.planningIncomplete);
      case AttentionDestination.documentEvaluation:
        final placementId = item.clinicalPlacementId;
        if (placementId != null) {
          _attentionController.selectPlacement(placementId);
        }
        await _openContextualRoute(
          title: 'Evaluation Plan',
          child: EvaluationPlanSurface(controller: _attentionController),
        );
        await _reloadSchedulingSurfaces();
      case AttentionDestination.manageClinicalPlacement:
        final placementId = item.clinicalPlacementId;
        if (placementId != null) {
          await _placementController.selectPlacement(placementId);
        }
        if (!mounted) return;
        setState(() {
          _destination = ClinicalCalendarDestination.clinicalPlacements;
          _entry = DestinationEntry.direct;
        });
      case AttentionDestination.createPortableBackup:
        await _openContextualRoute(
          title: 'Portable Backup',
          child: _portableBackupSurface(),
        );
      case AttentionDestination.resolveSynchronization:
        await _openSynchronization();
    }
  }

  Future<void> _openSynchronization() async {
    await _conflictController.load();
    if (!mounted) return;
    await _openContextualRoute(
      title: 'Synchronization',
      child: _SynchronizationDestinationSurface(
        controller: _conflictController,
        synchronization: widget.dependencies.synchronization,
        onSynchronized: refreshAuthoritativeSettings,
        onOpenRecordAction: _openConflictRecord,
      ),
    );
    await _reloadSchedulingSurfaces();
  }

  void _openConflictRecord(
    SynchronizationConflictEntityReference record,
    CrossRecordResolutionAction action,
  ) {
    if (action != CrossRecordResolutionAction.move) return;
    final kind = switch (record.entityType) {
      'work_shift' => CommitmentLifecycleKind.workShift,
      'clinical_session' => CommitmentLifecycleKind.clinicalSession,
      'protected_day' => CommitmentLifecycleKind.protectedDay,
      _ => null,
    };
    if (kind != null) {
      unawaited(_openCommitmentLifecycle(kind: kind, id: record.entityId));
    }
  }

  Future<void> _openContextualRoute({
    required String title,
    required Widget child,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            _ContextualRouteSurface(title: title, child: child),
      ),
    );
  }

  void _openAttentionCenter() {
    setState(() {
      _destination = ClinicalCalendarDestination.notifications;
      _entry = DestinationEntry.direct;
    });
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
      _acceptSupportSnapshot(loaded);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _supportError = error);
    } finally {
      if (mounted) setState(() => _supportLoading = false);
    }
  }

  Future<void> refreshAuthoritativeSettings() async {
    try {
      final loaded = await _supportService.load();
      if (!mounted) return;
      _acceptSupportSnapshot(loaded);
    } on Object {
      // The current authoritative presentation stays intact when refresh
      // cannot prove that a newer synchronized setting exists.
    }
  }

  void _acceptSupportSnapshot(SupportSnapshot snapshot) {
    widget.themePreviewController.updateAuthoritativeTheme(
      themeId: snapshot.settings.value.themeId,
      revision: snapshot.settings.revision,
    );
    widget.enhancedAccessibilityController.acceptAuthoritative(
      snapshot.settings.value.enhancedAccessibility,
    );
    setState(() => _support = snapshot);
  }

  Future<void> _refreshSupportAndOfferOnboarding() async {
    if (!mounted || _profileOnboardingOpen) return;
    try {
      final loaded = await _supportService.load();
      if (!mounted) return;
      _acceptSupportSnapshot(loaded);
      final email = widget.identityEmail;
      final profile = loaded.profile.value;
      if (email == null ||
          profile.displayName != 'Student' ||
          (profile.accountIdentity?.isNotEmpty ?? false)) {
        return;
      }
      _profileOnboardingOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: StudentProfileOnboardingDialog(
            email: email,
            onSave: _completeProfileOnboarding,
          ),
        ),
      );
    } on Object {
      // A profile can still be completed from Student Profile after a local
      // read failure. Never block the rest of the recovered calendar.
    } finally {
      _profileOnboardingOpen = false;
    }
  }

  Future<void> _completeProfileOnboarding(
    String firstName,
    String lastName,
  ) async {
    final snapshot = _support;
    final email = widget.identityEmail;
    if (snapshot == null || email == null) return;
    final saved = await _supportService.saveProfile(
      expectedRevision: snapshot.profile.revision,
      displayName: '$firstName $lastName',
      program: snapshot.profile.value.program,
      accountIdentity: email,
      avatarBytes: snapshot.profile.value.avatarBytes,
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
    _acceptSupportSnapshot(
      SupportSnapshot(
        profile: snapshot.profile,
        settings: saved,
        scheduleTemplates: snapshot.scheduleTemplates,
      ),
    );
    _replaceBatchController();
    await _reconcileNotifications();
  }

  Future<void> _persistEnhancedAccessibility(bool enabled) async {
    final snapshot = _support;
    if (snapshot == null) {
      throw StateError('Student Settings are still loading.');
    }
    final current = snapshot.settings.value;
    final saved = await _supportService.saveSettings(
      expectedRevision: snapshot.settings.revision,
      settings: StudentSettings(
        weekStart: current.weekStart,
        timeDisplay: current.timeDisplay,
        themeId: current.themeId,
        enhancedAccessibility: enabled,
        synchronization: current.synchronization,
        notifications: current.notifications,
      ),
    );
    if (!mounted) return;
    _acceptSupportSnapshot(
      SupportSnapshot(
        profile: snapshot.profile,
        settings: saved,
        scheduleTemplates: snapshot.scheduleTemplates,
      ),
    );
  }

  Future<void> applyThemePreview() async {
    ThemeApplyRequest request;
    try {
      request = widget.themePreviewController.beginApply();
    } on StateError {
      return;
    }
    final snapshot = _support;
    if (snapshot == null) {
      widget.themePreviewController.failApply(
        'Student Settings are still loading. Try again.',
      );
      return;
    }
    try {
      final current = snapshot.settings.value;
      final saved = await _supportService.saveSettings(
        expectedRevision: request.expectedRevision,
        settings: StudentSettings(
          weekStart: current.weekStart,
          timeDisplay: current.timeDisplay,
          themeId: request.themeId,
          enhancedAccessibility: current.enhancedAccessibility,
          synchronization: current.synchronization,
          notifications: current.notifications,
        ),
      );
      if (!mounted) return;
      setState(
        () => _support = SupportSnapshot(
          profile: snapshot.profile,
          settings: saved,
          scheduleTemplates: snapshot.scheduleTemplates,
        ),
      );
      widget.themePreviewController.completeApply(revision: saved.revision);
    } on Object catch (error) {
      await refreshAuthoritativeSettings();
      if (!mounted) return;
      final message = error is RepositoryException
          ? error.message
          : 'Theme could not be applied. Try again.';
      widget.themePreviewController.failApply(message);
    }
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
    _replaceBatchController();
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
    _replaceBatchController();
  }

  Future<void> _showMenu() async {
    final destination = await showModalBottomSheet<ClinicalCalendarDestination>(
      context: context,
      backgroundColor: context.clinicalColors.structureRaised,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
      builder: (context) => SafeArea(
        child: ApplicationMenu(
          onSelected: (destination) => Navigator.pop(context, destination),
          enhancedAccessibilityController:
              widget.enhancedAccessibilityController,
          onPersistEnhancedAccessibility: _persistEnhancedAccessibility,
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
    if (destination == ClinicalCalendarDestination.planning) {
      setState(() => _destination = null);
      _resetPlanning(BatchSchedulingReset.addSchedule);
      return;
    }
    setState(() {
      _destination = destination;
      _entry = DestinationEntry.direct;
    });
  }

  void _exitDestination() {
    final returnToMenu = _entry == DestinationEntry.applicationMenu;
    final exited = _destination;
    setState(() => _destination = null);
    if (exited == ClinicalCalendarDestination.settings && !returnToMenu) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _releaseGalleryMemory(),
      );
    }
    if (exited == ClinicalCalendarDestination.clinicalPlacements ||
        exited == ClinicalCalendarDestination.settings ||
        exited == ClinicalCalendarDestination.backupRestore) {
      unawaited(_refreshAfterDestinationExit(exited!));
    }
    if (returnToMenu) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showMenu();
        if (exited == ClinicalCalendarDestination.settings) {
          await _releaseGalleryMemory();
        }
      });
    }
  }

  Future<void> _releaseGalleryMemory() async {
    final activeThemeId = widget.themePreviewController.effectiveBundle.id;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await evictInactiveThemeFrameAssets(
      context: context,
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      activeThemeId: activeThemeId,
    );
    try {
      await _androidMemoryLifecycle.invokeMethod<void>('trimGallery');
      // Raster cleanup is asynchronous in the engine. A second pressure pass
      // catches resources released by the first pass without replacing the
      // Activity, Flutter engine, Dart isolate, or user-owned planning state.
      await Future<void>.delayed(const Duration(milliseconds: 750));
      await _androidMemoryLifecycle.invokeMethod<void>('trimGallery');
    } on MissingPluginException {
      // Widget and non-Android hosts have no native memory lifecycle.
    }
  }

  Future<void> releaseThemeTransitionMemory() async {
    final activeThemeId = widget.themePreviewController.effectiveBundle.id;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await evictInactiveThemeFrameAssets(
      context: context,
      registry: ClinicalCalendarThemeBundleRegistry.standard,
      activeThemeId: activeThemeId,
      clearLiveImages: false,
    );
    try {
      await _androidMemoryLifecycle.invokeMethod<void>('trimGallery');
    } on MissingPluginException {
      // Widget and non-Android hosts have no native memory lifecycle.
    }
  }

  Future<void> _refreshAfterDestinationExit(
    ClinicalCalendarDestination destination,
  ) async {
    if (destination == ClinicalCalendarDestination.backupRestore) {
      await _initializeScheduling();
      return;
    }
    await _attentionController.load();
    if (!mounted) return;
    if (destination == ClinicalCalendarDestination.clinicalPlacements) {
      _replaceBatchController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    if (destination != null) {
      return widget.themeBundle.shellRenderer.buildDestination(
        destination: destination,
        entry: _entry,
        onExit: _exitDestination,
        child: KeyedSubtree(
          key: _destinationContentKey,
          child: _destinationBody(destination),
        ),
      );
    }

    final settings = _support?.settings.value ?? StudentSettings();
    final placementProgress = _PlacementLoadState(
      controller: _placementController,
      onRetry: _placementController.load,
      child: PlacementProgressRail(
        controller: _placementController,
        studentId: widget.studentId,
      ),
    );
    final attention = AttentionRail(
      controller: _attentionController,
      onOpenAction: _openAttentionItem,
      onOpenAll: _openAttentionCenter,
    );
    final insightRail = widget.themeBundle.id == graphiteThemeId
        ? GraphiteInsightRailSlots(
            key: _insightRailContentKey,
            placementProgress: placementProgress,
            attention: attention,
          )
        : widget.themeBundle.id == variantFThemeId
        ? KeyedSubtree(key: _insightRailContentKey, child: placementProgress)
        : KeyedSubtree(
            key: _insightRailContentKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  placementProgress,
                  const SizedBox(height: 10),
                  attention,
                ],
              ),
            ),
          );
    return widget.themeBundle.shellRenderer.build(
      environmentName: widget.environmentName,
      onOpenMenu: _showMenu,
      onOpenDestination: _openDirect,
      onOpenAttention: _openAttentionCenter,
      onAddSchedule: _openPlanning,
      slots: ResponsiveShellSlots(
        placementDock: KeyedSubtree(
          key: _placementDockContentKey,
          child: _PlacementLoadState(
            controller: _placementController,
            onRetry: _placementController.load,
            child: PlacementDock(
              controller: _placementController,
              studentId: widget.studentId,
              onManage: () =>
                  _openDirect(ClinicalCalendarDestination.clinicalPlacements),
            ),
          ),
        ),
        centralContent: KeyedSubtree(
          key: _calendarContentKey,
          child: AcademicAssignmentCalendarWorkspace(
            themeId: widget.themeBundle.id,
            onAddAssignment: _openAcademicAssignment,
            onManageClasses: _openClassCatalog,
            calendar: CalendarPeriodView(
              key: ValueKey('calendar-period-view-$_calendarRevision'),
              dataSource: _assignmentCalendarDataSource,
              studentId: widget.studentId,
              today: _resolveToday(widget.dependencies, widget.todayResolver),
              weekStartsOn: settings.weekStart,
              twelveHourTime:
                  settings.timeDisplay == TimeDisplayPreference.twelveHour,
              initialSelectedDates: _selectedDates,
              onSelectionChanged: _updateCalendarSelection,
              onOpenItem: _openCommitment,
            ),
          ),
        ),
        insightRail: insightRail,
        mobilePlacementSummary: KeyedSubtree(
          key: _mobilePlacementContentKey,
          child: _PlacementLoadState(
            controller: _placementController,
            onRetry: _placementController.load,
            child: PlacementMobileSummary(
              controller: _placementController,
              studentId: widget.studentId,
            ),
          ),
        ),
        mobileAttention: KeyedSubtree(
          key: _mobileAttentionContentKey,
          child: AttentionRail(
            controller: _attentionController,
            onOpenAction: _openAttentionItem,
            onOpenAll: _openAttentionCenter,
          ),
        ),
        planningRegion: KeyedSubtree(
          key: const Key('live-planning-region'),
          child: _PlanningRegion(
            key: _planningRegionKey,
            controller: _batchController,
            onAddSchedule: () =>
                _resetPlanning(BatchSchedulingReset.addSchedule),
            onPlanningIncomplete: () =>
                _resetPlanning(BatchSchedulingReset.planningIncomplete),
          ),
        ),
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
        final activePlacementId = _placementController.activePlacementId;
        return PlacementManagementSurface(
          controller: _placementController,
          studentId: widget.studentId,
          onOpenEvaluations: _openActivePlacementEvaluations,
          unsavedSchedulingDraftCount: activePlacementId == null
              ? 0
              : _batchController?.unsavedDraftCountForPlacement(
                      activePlacementId,
                    ) ??
                    0,
          onDiscardUnsavedSchedulingDrafts: () {
            unawaited(_afterPlacementDeleted());
          },
        );
      case ClinicalCalendarDestination.studentProfile:
        return _supportBody(
          (snapshot) => StudentProfileSurface(
            profile: snapshot.profile.value,
            chooseAvatar: widget.chooseAvatar ?? () async => null,
            onSave: _saveProfile,
          ),
        );
      case ClinicalCalendarDestination.connectedDevices:
        final identity = widget.identity;
        final email = widget.identityEmail;
        final onLocalCopyRemoved = widget.onLocalCopyRemoved;
        if (identity == null || email == null || onLocalCopyRemoved == null) {
          return const _IdentityUnavailable();
        }
        return IdentityDevicesSurface(
          identity: identity,
          email: email,
          onLocalCopyRemoved: () async {
            widget.themePreviewController.revert();
            await onLocalCopyRemoved();
          },
          createAccountBackup: widget.createAccountBackup,
        );
      case ClinicalCalendarDestination.trashRecovery:
        final store = widget.recoveryStore;
        final service = widget.recoveryService;
        if (store == null || service == null) {
          return const _IdentityUnavailable();
        }
        DateTime now() => widget.dependencies.clock.nowUtc();
        return TrashRecoverySurface(
          showAppBar: false,
          loadTrash: () => store.listTrash(nowUtc: now()),
          restore: (trashId) async {
            await service.restoreTrash(trashId: trashId, nowUtc: now());
            await _reloadSchedulingSurfaces();
            await _loadSupport();
            if (mounted) _replaceBatchController();
          },
          permanentlyDelete: (trashId) => service.permanentlyDelete(
            trashId: trashId,
            confirmed: true,
            nowUtc: now(),
          ),
          clearTrash: () => service.clearTrash(confirmed: true, nowUtc: now()),
          reauthenticateForClear: _freshRecoveryReauthentication,
          loadSnapshots: () => store.listSnapshots(nowUtc: now()),
          previewSnapshot: (snapshotId) =>
              store.previewSnapshot(snapshotId: snapshotId, nowUtc: now()),
          restoreSnapshot: (snapshotId, choices) async {
            await store.restoreSnapshot(
              snapshotId: snapshotId,
              choices: choices,
              nowUtc: now(),
            );
          },
        );
      case ClinicalCalendarDestination.backupRestore:
        return _portableBackupSurface();
      case ClinicalCalendarDestination.exports:
        final factory = widget.exportWorkflowFactory;
        if (factory == null) {
          return const _UnavailableAttentionWorkflow(
            message: 'Exports are not available in this build.',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ExportSurface(
            workflow: factory(
              _CallbackExportReauthenticationGate(_freshExportReauthentication),
            ),
            clinicalPlacementId: _placementController.activePlacementId,
          ),
        );
      case ClinicalCalendarDestination.synchronization:
        return _SynchronizationDestinationSurface(
          controller: _conflictController,
          synchronization: widget.dependencies.synchronization,
          onSynchronized: refreshAuthoritativeSettings,
          onOpenRecordAction: _openConflictRecord,
        );
      case ClinicalCalendarDestination.settings:
        final devicePolicy = _notificationDevicePolicy;
        return _supportBody(
          (snapshot) => SettingsTemplatesSurface(
            settings: snapshot.settings.value,
            authoritativeThemeId:
                widget.themePreviewController.authoritativeThemeId,
            onPreviewTheme: widget.onPreviewTheme,
            scheduleTemplates: snapshot.scheduleTemplates
                .map((record) => record.value)
                .toList(growable: false),
            clinicalDefaults: _clinicalDefaults,
            newTemplateId: widget.dependencies.identifiers.nextIdentifier,
            onSaveSettings: _saveSettings,
            onSaveTemplate: _saveTemplate,
            onRemoveTemplate: _removeTemplate,
            deviceNotifications: devicePolicy == null
                ? null
                : DeviceNotificationPreferences(
                    deliveryEnabled: devicePolicy.effectiveEnabled,
                    detailedPreview: devicePolicy.detailedPreview,
                    quietStartsAtHour: devicePolicy.quietStartsAtHour,
                    quietStartsAtMinute: devicePolicy.quietStartsAtMinute,
                    quietEndsAtHour: devicePolicy.quietEndsAtHour,
                    quietEndsAtMinute: devicePolicy.quietEndsAtMinute,
                  ),
            onSaveDeviceNotifications: devicePolicy == null
                ? null
                : _saveNotificationDevicePreferences,
          ),
        );
      case ClinicalCalendarDestination.help:
        return SupportHelpSurface(themeGuide: widget.themeBundle.helpGuide);
      case ClinicalCalendarDestination.notifications:
        return AttentionCenterSurface(
          controller: _attentionController,
          notificationMode: true,
          onOpenAction: _openAttentionItem,
        );
      case ClinicalCalendarDestination.calendar:
      case ClinicalCalendarDestination.planning:
        return _PendingDestination(destination: destination);
    }
  }

  Future<void> _openActivePlacementEvaluations() async {
    final placementId = _placementController.activePlacementId;
    if (placementId != null) {
      _attentionController.selectPlacement(placementId);
    }
    await _openContextualRoute(
      title: 'Reviews & Evaluations',
      child: EvaluationPlanSurface(controller: _attentionController),
    );
    await _reloadSchedulingSurfaces();
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

  Future<bool> _freshRecoveryReauthentication() async {
    final identity = widget.identity;
    final email = widget.identityEmail;
    final proof = widget.recoveryProofGate;
    if (identity == null || email == null || proof == null) return false;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecoveryOtpDialog(
        identity: identity,
        email: email,
        title: 'Reauthenticate to clear Trash',
      ),
    );
    if (verified != true) return false;
    proof.grantOnce();
    return true;
  }

  Future<bool> _freshExportReauthentication(String reason) async {
    final identity = widget.identity;
    final email = widget.identityEmail;
    if (identity == null || email == null) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _RecoveryOtpDialog(
            identity: identity,
            email: email,
            title: reason,
          ),
        ) ==
        true;
  }

  Widget _portableBackupSurface() {
    final workflows = widget.portableBackupWorkflows;
    if (workflows == null) {
      return const _UnavailableAttentionWorkflow(
        message: 'Portable backup is not available in this build.',
      );
    }
    return BackupRestoreSurface(
      showAppBar: false,
      onCreateBackup: workflows.create,
      onChooseBackup: workflows.choose,
      onApplyRestore: workflows.apply,
    );
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

  List<BatchClinicalPlacementOption> get _batchPlacementOptions => [
    for (final placement in _placementController.placements)
      BatchClinicalPlacementOption(
        id: placement.placement.id,
        name: placement.placement.name,
        primaryPreceptorId: placement.placement.primaryPreceptorId,
        preceptors: [
          for (final attached in placement.attachedPreceptors)
            BatchPreceptorOption(
              id: attached.preceptor.id,
              name: attached.preceptor.name,
            ),
        ],
      ),
  ];
}

final class _CallbackExportReauthenticationGate
    implements ExportReauthenticationGate {
  const _CallbackExportReauthenticationGate(this.callback);

  final Future<bool> Function(String reason) callback;

  @override
  Future<bool> reauthenticate({required String reason}) => callback(reason);
}

final class _SynchronizationDestinationSurface extends StatefulWidget {
  const _SynchronizationDestinationSurface({
    required this.controller,
    required this.synchronization,
    required this.onSynchronized,
    required this.onOpenRecordAction,
  });

  final ConflictResolutionController controller;
  final SynchronizationService synchronization;
  final Future<void> Function() onSynchronized;
  final void Function(
    SynchronizationConflictEntityReference record,
    CrossRecordResolutionAction action,
  )
  onOpenRecordAction;

  @override
  State<_SynchronizationDestinationSurface> createState() =>
      _SynchronizationDestinationSurfaceState();
}

final class _SynchronizationDestinationSurfaceState
    extends State<_SynchronizationDestinationSurface> {
  bool _conflictReported = false;

  Future<void> _afterSynchronization(SynchronizationResult result) async {
    await widget.controller.load();
    if (!mounted) return;
    final conflictReported =
        result.detail ==
            PublicSynchronizationFailureReference.conflictNeedsAttention &&
        !(widget.controller.snapshot?.hasConflicts ?? false);
    if (_conflictReported != conflictReported) {
      setState(() => _conflictReported = conflictReported);
    }
  }

  Future<void> _refreshConflicts() async {
    await widget.controller.load();
    if (!mounted ||
        !_conflictReported ||
        !(widget.controller.snapshot?.hasConflicts ?? false)) {
      return;
    }
    setState(() => _conflictReported = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final conflicts = widget.controller.snapshot;
      if (_conflictReported ||
          widget.controller.error != null ||
          (conflicts != null && conflicts.hasConflicts)) {
        return SynchronizationConflictResolutionSurface(
          controller: widget.controller,
          onOpenRecordAction: widget.onOpenRecordAction,
          conflictReported: _conflictReported,
          onRefresh: _refreshConflicts,
        );
      }
      return SynchronizationAttentionSurface(
        synchronization: widget.synchronization,
        onSynchronized: widget.onSynchronized,
        onSynchronizationAttempted: _afterSynchronization,
      );
    },
  );
}

final class _RecoveryOtpDialog extends StatefulWidget {
  const _RecoveryOtpDialog({
    required this.identity,
    required this.email,
    required this.title,
  });

  final PasswordlessIdentityService identity;
  final String email;
  final String title;

  @override
  State<_RecoveryOtpDialog> createState() => _RecoveryOtpDialogState();
}

final class _RecoveryOtpDialogState extends State<_RecoveryOtpDialog> {
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('A fresh one-time code will be sent to ${widget.email}.'),
        if (_codeSent) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('recovery-otp-code'),
            controller: _code,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(labelText: 'One-time code'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, key: const Key('recovery-otp-error')),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: Key(_codeSent ? 'verify-recovery-otp' : 'send-recovery-otp'),
        onPressed: _busy ? null : (_codeSent ? _verify : _send),
        child: Text(_codeSent ? 'Verify and continue' : 'Send code'),
      ),
    ],
  );

  Future<void> _send() => _run(() async {
    await widget.identity.sendSignInCode(widget.email);
    _codeSent = true;
  });

  Future<void> _verify() => _run(() async {
    await widget.identity.verifySignInCode(widget.email, _code.text);
    if (mounted) Navigator.pop(context, true);
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Object {
      _error = 'The code could not be verified.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

final class _PlanningRegion extends StatefulWidget {
  const _PlanningRegion({
    required this.controller,
    required this.onAddSchedule,
    required this.onPlanningIncomplete,
    super.key,
  });

  final BatchSchedulingController? controller;
  final VoidCallback onAddSchedule;
  final VoidCallback onPlanningIncomplete;

  @override
  State<_PlanningRegion> createState() => _PlanningRegionState();
}

final class _PlanningRegionState extends State<_PlanningRegion> {
  bool _expanded = false;
  bool? _responsiveExpandedByDefault;
  bool _studentControlledExpansion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final expandedByDefault = VariantFPlanningBayMode.expandedByDefaultOf(
      context,
    );
    if (_responsiveExpandedByDefault == expandedByDefault) return;
    if (!_studentControlledExpansion) _expanded = expandedByDefault;
    _responsiveExpandedByDefault = expandedByDefault;
  }

  void expand() {
    _studentControlledExpansion = true;
    if (!_expanded) setState(() => _expanded = true);
  }

  void toggleExpanded() {
    _studentControlledExpansion = true;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Build the monthly plan in this in-flow region.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('primary-planning-action'),
              onPressed: widget.controller == null
                  ? null
                  : () {
                      expand();
                      widget.onAddSchedule();
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add schedule'),
            ),
            OutlinedButton.icon(
              key: const Key('planning-incomplete-action'),
              onPressed: widget.controller == null
                  ? null
                  : () {
                      expand();
                      widget.onPlanningIncomplete();
                    },
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Planning Incomplete'),
            ),
            if (widget.controller != null)
              OutlinedButton.icon(
                key: const Key('planning-tray-toggle'),
                onPressed: toggleExpanded,
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_expanded ? 'Collapse' : 'Expand'),
              ),
          ],
        ),
        if (widget.controller != null && !_expanded) ...[
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: widget.controller!,
            builder: (context, _) {
              final count = widget.controller!.selectedDates.length;
              return Text(
                '$count selected ${count == 1 ? 'date' : 'dates'} · '
                '${_batchTypeLabel(widget.controller!.type)}',
                key: const Key('planning-tray-summary'),
              );
            },
          ),
        ],
        if (widget.controller != null && _expanded) ...[
          const SizedBox(height: 12),
          StagedBatchSchedulingTray(controller: widget.controller!),
        ],
      ],
    );
    if (Federation2399ConsoleScope.isActive(context)) {
      return Federation2399SectionHousing(
        key: const Key('federation-2399-live-planning-housing'),
        label: 'Planning',
        accent: context.clinicalColors.scheduled,
        child: content,
      );
    }
    if (CoastalLightPanelScope.isActive(context)) {
      return CoastalLightWorkflowHousing(
        role: CoastalLightPanelRole.planning,
        label: 'Planning',
        accent: context.clinicalColors.scheduled,
        child: content,
      );
    }
    if (HeritageFieldNotesPanelScope.isActive(context)) {
      return HeritageFieldNotesWorkflowHousing(
        role: HeritageFieldNotesPanelRole.planning,
        label: 'Planning',
        accent: context.clinicalColors.scheduled,
        child: content,
      );
    }
    return ShellPanel(
      label: 'Planning',
      accent: context.clinicalColors.scheduled,
      child: content,
    );
  }
}

String _batchTypeLabel(BatchCommitmentType type) => switch (type) {
  BatchCommitmentType.workShift => 'Work Shift',
  BatchCommitmentType.clinicalSession => 'Clinical Session',
  BatchCommitmentType.protectedDay => 'Protected Day',
};

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

final class _ContextualRouteSurface extends StatelessWidget {
  const _ContextualRouteSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('contextual-route-surface'),
    appBar: AppBar(
      backgroundColor: context.clinicalColors.structure,
      leadingWidth: 88,
      leading: TextButton.icon(
        key: const Key('contextual-back-action'),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Back'),
      ),
      title: Text(title),
    ),
    body: SafeArea(child: child),
  );
}

final class _UnavailableAttentionWorkflow extends StatelessWidget {
  const _UnavailableAttentionWorkflow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ShellPanel(label: 'Workflow unavailable', child: Text(message)),
    ),
  );
}

final class _IdentityUnavailable extends StatelessWidget {
  const _IdentityUnavailable();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Connected Devices becomes available after passwordless sign-in.',
        key: Key('identity-unavailable'),
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

final class _ReloadingBatchOperations implements BatchSchedulingOperations {
  const _ReloadingBatchOperations(this.delegate, this.onApplied);

  final BatchSchedulingOperations delegate;
  final Future<void> Function() onApplied;

  @override
  Future<BatchSchedulingReview> review(BatchSchedulingDraft draft) =>
      delegate.review(draft);

  @override
  Future<BatchSchedulingApplyResult> apply(BatchSchedulingDraft draft) async {
    final result = await delegate.apply(draft);
    if (result.applied) await onApplied();
    return result;
  }
}

ZonedScheduleDate _zonedScheduleDate(LocalDate date) => ZonedScheduleDate(
  date: date,
  timeZone: TimeZoneId('UTC'),
  startOffset: UtcOffset.utc,
  endOffset: UtcOffset.utc,
);

bool _sameDates(Set<LocalDate> left, Set<LocalDate> right) =>
    left.length == right.length && left.containsAll(right);

LocalDate _resolveToday(
  ApplicationDependencies dependencies,
  TodayResolver? resolver,
) {
  final now = dependencies.clock.nowUtc();
  return resolver?.call(now) ?? LocalDate(now.year, now.month, now.day);
}
