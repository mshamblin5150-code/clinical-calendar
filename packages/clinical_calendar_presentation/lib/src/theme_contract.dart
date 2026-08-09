import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'botanical_study_frame.dart';
import 'botanical_study_shell.dart';
import 'botanical_study_theme.dart';
import 'coastal_light_frame.dart';
import 'coastal_light_shell.dart';
import 'coastal_light_theme.dart';
import 'federation_classic_frame.dart';
import 'federation_classic_shell.dart';
import 'federation_classic_theme.dart';
import 'federation_2399_frame.dart';
import 'federation_2399_shell.dart';
import 'federation_2399_theme.dart';
import 'graphite_frame.dart';
import 'graphite_shell.dart';
import 'graphite_theme.dart';
import 'responsive_shell.dart';
import 'tactical_frame.dart';
import 'variant_f_theme.dart';

const variantFThemeId = 'variant-f';
const federationClassicThemeId = 'federation-classic';
const federation2399ThemeId = 'federation-2399';
const coastalCalmThemeId = 'coastal-calm';
const botanicalStudyThemeId = 'botanical-study';
const graphiteThemeId = 'graphite';
const themeGalleryFixtureId = 'theme-gallery-android-tablet-calendar-v1';
const themeGalleryViewport = Size(1280, 800);

enum ThemeBundleOrigin { compiled, runtime, remote }

abstract interface class ThemeOwnedComponent {
  String get themeId;
}

@immutable
final class ThemeCatalogMetadata implements ThemeOwnedComponent {
  const ThemeCatalogMetadata({
    required this.themeId,
    required this.displayName,
    required this.personality,
  });

  @override
  final String themeId;
  final String displayName;
  final String personality;
}

/// Standard presentation tokens and Material styling for one complete bundle.
abstract interface class ClinicalCalendarStandardPresentation
    implements ThemeOwnedComponent {
  ClinicalCalendarColors get semanticColors;

  ThemeData createThemeData({bool enhancedAccessibility = false});
}

/// Kept as the narrow public name used by existing presentation tests.
abstract interface class ClinicalCalendarVisualTheme
    implements ClinicalCalendarStandardPresentation {
  String get id;
}

final class VariantFVisualTheme implements ClinicalCalendarVisualTheme {
  const VariantFVisualTheme();

  @override
  String get id => variantFThemeId;

  @override
  String get themeId => id;

  @override
  ClinicalCalendarColors get semanticColors => variantFSemanticColors;

  @override
  ThemeData createThemeData({bool enhancedAccessibility = false}) =>
      buildVariantFTheme(enhancedAccessibility: enhancedAccessibility);
}

final class GraphiteVisualTheme implements ClinicalCalendarVisualTheme {
  const GraphiteVisualTheme();

  @override
  String get id => graphiteThemeId;

  @override
  String get themeId => id;

  @override
  ClinicalCalendarColors get semanticColors => graphiteSemanticColors;

  @override
  ThemeData createThemeData({bool enhancedAccessibility = false}) =>
      buildGraphiteTheme(enhancedAccessibility: enhancedAccessibility);
}

final class FederationClassicVisualTheme
    implements ClinicalCalendarVisualTheme {
  const FederationClassicVisualTheme();

  @override
  String get id => federationClassicThemeId;

  @override
  String get themeId => id;

  @override
  ClinicalCalendarColors get semanticColors => federationClassicSemanticColors;

  @override
  ThemeData createThemeData({bool enhancedAccessibility = false}) =>
      buildFederationClassicTheme(enhancedAccessibility: enhancedAccessibility);
}

final class Federation2399VisualTheme implements ClinicalCalendarVisualTheme {
  const Federation2399VisualTheme();

  @override
  String get id => federation2399ThemeId;

  @override
  String get themeId => id;

  @override
  ClinicalCalendarColors get semanticColors => federation2399SemanticColors;

  @override
  ThemeData createThemeData({bool enhancedAccessibility = false}) =>
      buildFederation2399Theme(enhancedAccessibility: enhancedAccessibility);
}

final class CoastalLightVisualTheme implements ClinicalCalendarVisualTheme {
  const CoastalLightVisualTheme();

  @override
  String get id => coastalCalmThemeId;

  @override
  String get themeId => id;

  @override
  ClinicalCalendarColors get semanticColors => coastalLightSemanticColors;

  @override
  ThemeData createThemeData({bool enhancedAccessibility = false}) =>
      buildCoastalLightTheme(enhancedAccessibility: enhancedAccessibility);
}

final class BotanicalStudyVisualTheme implements ClinicalCalendarVisualTheme {
  const BotanicalStudyVisualTheme();

  @override
  String get id => botanicalStudyThemeId;

  @override
  String get themeId => id;

  @override
  ClinicalCalendarColors get semanticColors => botanicalStudySemanticColors;

  @override
  ThemeData createThemeData({bool enhancedAccessibility = false}) =>
      buildBotanicalStudyTheme(enhancedAccessibility: enhancedAccessibility);
}

abstract interface class ClinicalCalendarShellRenderer
    implements ThemeOwnedComponent {
  String get rendererId;

  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  });

  Widget buildFrame({required Widget child});

  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  });
}

final class VariantFShellRenderer implements ClinicalCalendarShellRenderer {
  const VariantFShellRenderer();

  @override
  String get themeId => variantFThemeId;

  @override
  String get rendererId => 'variant-f-existing-responsive-shell';

  @override
  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  }) => ResponsiveApplicationShell(
    key: key,
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
  );

  @override
  Widget buildFrame({required Widget child}) => VariantFTacticalFrame(
    padding: const EdgeInsets.all(8),
    chamfer: 14,
    statusLight: true,
    child: child,
  );

  @override
  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  }) => DestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    child: child,
  );
}

final class GraphiteShellRenderer implements ClinicalCalendarShellRenderer {
  const GraphiteShellRenderer();

  @override
  String get themeId => graphiteThemeId;

  @override
  String get rendererId => 'graphite-owned-responsive-instrument-v2';

  @override
  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  }) => GraphiteApplicationShell(
    key: key,
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
  );

  @override
  Widget buildFrame({required Widget child}) => GraphiteNineSliceFrame(
    chromeInsets: graphiteStatusSafeInsets,
    contentPadding: const EdgeInsets.all(8),
    child: AdditiveThemePanelInterior(child: child),
  );

  @override
  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  }) => GraphiteDestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    child: child,
  );
}

final class FederationClassicShellRenderer
    implements ClinicalCalendarShellRenderer {
  const FederationClassicShellRenderer();

  @override
  String get themeId => federationClassicThemeId;

  @override
  String get rendererId => 'federation-classic-owned-responsive-console-v2';

  @override
  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  }) => FederationClassicApplicationShell(
    key: key,
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
  );

  @override
  Widget buildFrame({required Widget child}) => FederationClassicNineSliceFrame(
    chromeInsets: federationClassicStatusSafeInsets,
    contentPadding: const EdgeInsets.all(8),
    child: AdditiveThemePanelInterior(child: child),
  );

  @override
  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  }) => FederationClassicDestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    child: child,
  );
}

final class Federation2399ShellRenderer
    implements ClinicalCalendarShellRenderer {
  const Federation2399ShellRenderer();

  @override
  String get themeId => federation2399ThemeId;

  @override
  String get rendererId => 'federation-2399-owned-responsive-console-v4';

  @override
  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  }) => Federation2399ApplicationShell(
    key: key,
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
  );

  @override
  Widget buildFrame({required Widget child}) => Federation2399NineSliceFrame(
    chromeInsets: federation2399StatusSafeInsets,
    contentPadding: const EdgeInsets.all(8),
    child: AdditiveThemePanelInterior(child: child),
  );

  @override
  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  }) => Federation2399DestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    child: child,
  );
}

final class CoastalLightShellRenderer implements ClinicalCalendarShellRenderer {
  const CoastalLightShellRenderer();

  @override
  String get themeId => coastalCalmThemeId;

  @override
  String get rendererId => 'coastal-light-owned-responsive-observatory-v1';

  @override
  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  }) => CoastalLightApplicationShell(
    key: key,
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
  );

  @override
  Widget buildFrame({required Widget child}) => CoastalLightNineSliceFrame(
    chromeInsets: coastalLightStatusSafeInsets,
    contentPadding: const EdgeInsets.all(8),
    child: AdditiveThemePanelInterior(child: child),
  );

  @override
  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  }) => CoastalLightDestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    child: child,
  );
}

final class BotanicalStudyShellRenderer
    implements ClinicalCalendarShellRenderer {
  const BotanicalStudyShellRenderer();

  @override
  String get themeId => botanicalStudyThemeId;

  @override
  String get rendererId => 'botanical-study-owned-research-desk-v1';

  @override
  Widget build({
    required ResponsiveShellSlots slots,
    required String environmentName,
    required VoidCallback onOpenMenu,
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
    required VoidCallback onAddSchedule,
    int mobileIndex = 1,
    Key? key,
  }) => BotanicalStudyApplicationShell(
    key: key,
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
  );

  @override
  Widget buildFrame({required Widget child}) => BotanicalStudyNineSliceFrame(
    chromeInsets: botanicalStudyStatusSafeInsets,
    contentPadding: const EdgeInsets.all(8),
    child: AdditiveThemePanelInterior(child: child),
  );

  @override
  Widget buildDestination({
    required ClinicalCalendarDestination destination,
    required DestinationEntry entry,
    required VoidCallback onExit,
    required Widget child,
  }) => BotanicalStudyDestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    child: child,
  );
}

enum ThemeFrameRegion { calendar, placements, planning, status }

@immutable
final class ThemeFrameDescriptor implements ThemeOwnedComponent {
  const ThemeFrameDescriptor({
    required this.themeId,
    required this.assetPackage,
    required this.primaryAsset,
    required this.assetPaths,
    required this.sourceSize,
    required this.sourceCuts,
    required this.safeInsets,
  });

  @override
  final String themeId;
  final String assetPackage;
  final String primaryAsset;
  final List<String> assetPaths;
  final Size sourceSize;
  final EdgeInsets sourceCuts;
  final Map<ThemeFrameRegion, EdgeInsets> safeInsets;
}

enum ThemeGallerySwatchRole {
  canvas,
  structure,
  clinicalSession,
  workShift,
  urgent,
}

@immutable
final class ThemeGallerySwatch {
  const ThemeGallerySwatch({
    required this.role,
    required this.label,
    required this.colorName,
    required this.color,
  });

  final ThemeGallerySwatchRole role;
  final String label;
  final String colorName;
  final Color color;
}

@immutable
final class ThemeGalleryData implements ThemeOwnedComponent {
  const ThemeGalleryData({
    required this.themeId,
    required this.rendererId,
    required this.thumbnailFixtureId,
    required this.thumbnailViewport,
    required this.swatches,
  });

  @override
  final String themeId;
  final String rendererId;
  final String thumbnailFixtureId;
  final Size thumbnailViewport;
  final List<ThemeGallerySwatch> swatches;
}

enum ThemeSemanticRole {
  clinicalSession,
  workShift,
  protectedDay,
  scheduledProgress,
  completedSession,
  cancelledSession,
  missedSession,
  today,
  urgent,
}

@immutable
final class ThemeSemanticMark {
  const ThemeSemanticMark({
    required this.role,
    required this.markId,
    required this.icon,
    required this.description,
  });

  final ThemeSemanticRole role;
  final String markId;
  final IconData icon;
  final String description;
}

@immutable
final class ClinicalCalendarSemanticMarks implements ThemeOwnedComponent {
  const ClinicalCalendarSemanticMarks({
    required this.themeId,
    required this.marks,
  });

  @override
  final String themeId;
  final List<ThemeSemanticMark> marks;

  ThemeSemanticMark forRole(ThemeSemanticRole role) =>
      marks.singleWhere((mark) => mark.role == role);
}

final class ClinicalCalendarSemanticMarkScope extends InheritedWidget {
  const ClinicalCalendarSemanticMarkScope({
    required this.marks,
    required super.child,
    super.key,
  });

  final ClinicalCalendarSemanticMarks marks;

  static ClinicalCalendarSemanticMarks? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ClinicalCalendarSemanticMarkScope>()
      ?.marks;

  @override
  bool updateShouldNotify(ClinicalCalendarSemanticMarkScope oldWidget) =>
      oldWidget.marks != marks;
}

final class ThemeSemanticMarkIcon extends StatelessWidget {
  const ThemeSemanticMarkIcon({
    required this.role,
    this.size,
    this.color,
    super.key,
  });

  final ThemeSemanticRole role;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final mark = ClinicalCalendarSemanticMarkScope.maybeOf(
      context,
    )?.forRole(role);
    return Icon(
      mark?.icon ?? _defaultMarkIcon(role),
      key: Key('theme-mark-${role.name}'),
      size: size,
      color: color,
      semanticLabel: mark?.description,
    );
  }
}

IconData _defaultMarkIcon(ThemeSemanticRole role) => switch (role) {
  ThemeSemanticRole.clinicalSession => Icons.medical_services_outlined,
  ThemeSemanticRole.workShift => Icons.work_outline,
  ThemeSemanticRole.protectedDay => Icons.shield_outlined,
  ThemeSemanticRole.scheduledProgress => Icons.schedule_outlined,
  ThemeSemanticRole.completedSession => Icons.check_circle_outline,
  ThemeSemanticRole.cancelledSession => Icons.block_outlined,
  ThemeSemanticRole.missedSession => Icons.highlight_off_outlined,
  ThemeSemanticRole.today => Icons.today_outlined,
  ThemeSemanticRole.urgent => Icons.warning_amber_outlined,
};

/// One theme-specific calendar-state explanation used by Help.
@immutable
final class CalendarStateGuide {
  const CalendarStateGuide({
    required this.role,
    required this.label,
    required this.description,
    required this.color,
    required this.nonColorCue,
    required this.enhancedBehavior,
  });

  final ThemeSemanticRole role;
  final String label;
  final String description;
  final Color color;
  final String nonColorCue;
  final String enhancedBehavior;
}

abstract interface class ThemeHelpGuide implements ThemeOwnedComponent {
  String get title;

  List<CalendarStateGuide> get calendarStates;
}

final class VariantFHelpGuide implements ThemeHelpGuide {
  const VariantFHelpGuide();

  @override
  String get themeId => variantFThemeId;

  @override
  String get title => 'Containment Drone 47-Alpha calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      role: ThemeSemanticRole.clinicalSession,
      label: 'Clinical Session',
      description: 'Collective green identifies clinical activity.',
      color: VariantFColors.primary,
      nonColorCue: 'Outlined medical-services icon.',
      enhancedBehavior: 'The icon and label receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.workShift,
      label: 'Work Shift',
      description: 'Gunmetal and green-steel identify work activity.',
      color: VariantFColors.workMachinery,
      nonColorCue: 'Outlined work icon.',
      enhancedBehavior:
          'The icon, label, and outline receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.protectedDay,
      label: 'Protected Day',
      description: 'Dormant graphite and silver identify protected time.',
      color: VariantFColors.protectedDayAccent,
      nonColorCue: 'Shield mark.',
      enhancedBehavior: 'The shield and label receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.scheduledProgress,
      label: 'Scheduled progress',
      description: 'Industrial ochre identifies hours already scheduled.',
      color: VariantFColors.scheduled,
      nonColorCue: 'Scheduled label and progress segment.',
      enhancedBehavior:
          'The label and progress boundary become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.today,
      label: 'Today or urgent',
      description: 'Optic red is reserved for Today and urgent attention.',
      color: VariantFColors.urgent,
      nonColorCue: 'Outlined date border with explicit status text.',
      enhancedBehavior: 'The border and status text receive stronger emphasis.',
    ),
  ];
}

final class GraphiteHelpGuide implements ThemeHelpGuide {
  const GraphiteHelpGuide();

  @override
  String get themeId => graphiteThemeId;

  @override
  String get title => 'Graphite calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      role: ThemeSemanticRole.clinicalSession,
      label: 'Clinical Session',
      description:
          'Cobalt and a medical-services mark identify clinical activity.',
      color: GraphiteColors.clinical,
      nonColorCue: 'Medical-services icon and Clinical Session label.',
      enhancedBehavior: 'The icon, label, and boundary become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.workShift,
      label: 'Work Shift',
      description: 'Violet and a work mark identify employment activity.',
      color: GraphiteColors.workAccent,
      nonColorCue: 'Briefcase mark and diagonal rail.',
      enhancedBehavior:
          'The briefcase, rail, and label receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.protectedDay,
      label: 'Protected Day',
      description: 'Brass and a shield mark identify protected time.',
      color: GraphiteColors.protectedDayAccent,
      nonColorCue: 'Shield mark and dotted rail.',
      enhancedBehavior:
          'The shield, rail, and label receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.scheduledProgress,
      label: 'Scheduled progress',
      description: 'Cobalt identifies hours already scheduled.',
      color: GraphiteColors.scheduled,
      nonColorCue: 'Clock mark and forward diagonal hatch.',
      enhancedBehavior:
          'The clock, hatch, and progress boundary become prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.today,
      label: 'Today or urgent',
      description:
          'Teal identifies Today; coral with status text identifies urgent attention.',
      color: GraphiteColors.primary,
      nonColorCue: 'Today dot or explicit urgent status outline.',
      enhancedBehavior:
          'The dot, outline, and status text become more prominent.',
    ),
  ];
}

final class FederationClassicHelpGuide implements ThemeHelpGuide {
  const FederationClassicHelpGuide();

  @override
  String get themeId => federationClassicThemeId;

  @override
  String get title => 'Federation Classic calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      role: ThemeSemanticRole.clinicalSession,
      label: 'Clinical Session',
      description:
          'Salmon and a solid leading rail identify clinical activity.',
      color: FederationClassicColors.clinical,
      nonColorCue: 'Medical-services icon, CLINICAL label, and solid rail.',
      enhancedBehavior: 'The icon, label, and rail receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.workShift,
      label: 'Work Shift',
      description: 'Lilac and paired rail marks identify work activity.',
      color: FederationClassicColors.workAccent,
      nonColorCue: 'Briefcase icon, WORK label, and two short rail marks.',
      enhancedBehavior:
          'The icon, label, and paired rails receive stronger emphasis.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.protectedDay,
      label: 'Protected Day',
      description: 'Warm cream outlines identify protected time.',
      color: FederationClassicColors.protectedDayAccent,
      nonColorCue: 'Shield icon, PROTECTED label, and dot-grid corner mark.',
      enhancedBehavior:
          'The shield, label, dot grid, and outline become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.scheduledProgress,
      label: 'Scheduled progress',
      description: 'Warm amber identifies hours already scheduled.',
      color: FederationClassicColors.scheduled,
      nonColorCue: 'Clock icon and forward diagonal hatch.',
      enhancedBehavior:
          'The clock, hatch, label, and progress boundary become prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.today,
      label: 'Today or urgent',
      description:
          'Cool blue marks Today; coral with status text marks urgency.',
      color: FederationClassicColors.today,
      nonColorCue: 'TODAY top rule or explicit urgent warning status.',
      enhancedBehavior:
          'The rule, warning outline, and status text become more prominent.',
    ),
  ];
}

final class Federation2399HelpGuide implements ThemeHelpGuide {
  const Federation2399HelpGuide();

  @override
  String get themeId => federation2399ThemeId;

  @override
  String get title => 'Federation 2399 calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      role: ThemeSemanticRole.clinicalSession,
      label: 'Clinical Session',
      description:
          'Restrained plum and a continuous fine rail identify clinical activity.',
      color: Federation2399Colors.clinical,
      nonColorCue:
          'Medical-services icon, CLINICAL label, and continuous rail.',
      enhancedBehavior: 'The icon, label, and rail become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.workShift,
      label: 'Work Shift',
      description:
          'Cool instrument light and split rails identify work activity.',
      color: Federation2399Colors.workMachinery,
      nonColorCue:
          'Briefcase icon, WORK label, and two separated rail segments.',
      enhancedBehavior:
          'The icon, label, and split rails become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.protectedDay,
      label: 'Protected Day',
      description: 'Cool ivory outlines identify protected time.',
      color: Federation2399Colors.protectedDayAccent,
      nonColorCue: 'Shield icon, PROTECTED label, and dot-grid corner marker.',
      enhancedBehavior:
          'The shield, label, dot grid, and outline are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.scheduledProgress,
      label: 'Scheduled progress',
      description: 'Aged amber identifies hours already scheduled.',
      color: Federation2399Colors.scheduled,
      nonColorCue: 'Clock icon and forward diagonal hatch.',
      enhancedBehavior:
          'The clock, hatch, label, and boundary are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.today,
      label: 'Today or urgent',
      description:
          'Cool blue marks Today; coral with status text marks urgent attention.',
      color: Federation2399Colors.today,
      nonColorCue: 'TODAY top rule or explicit urgent warning status.',
      enhancedBehavior:
          'The rule, warning outline, and status text are strengthened.',
    ),
  ];
}

final class CoastalLightHelpGuide implements ThemeHelpGuide {
  const CoastalLightHelpGuide();

  @override
  String get themeId => coastalCalmThemeId;

  @override
  String get title => 'Coastal Light calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      role: ThemeSemanticRole.clinicalSession,
      label: 'Clinical Session',
      description:
          'Sea-glass teal and a continuous rail identify clinical activity.',
      color: CoastalLightColors.clinical,
      nonColorCue:
          'Medical-services icon, CLINICAL label, and continuous rail.',
      enhancedBehavior: 'The icon, label, and rail become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.workShift,
      label: 'Work Shift',
      description: 'Clear blue and split rails identify work activity.',
      color: CoastalLightColors.workMachinery,
      nonColorCue:
          'Briefcase icon, WORK label, and two separated rail segments.',
      enhancedBehavior:
          'The icon, label, and split rails become more prominent.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.protectedDay,
      label: 'Protected Day',
      description: 'Warm mineral inlays identify protected time.',
      color: CoastalLightColors.protectedDayAccent,
      nonColorCue: 'Shield icon, PROTECTED label, and dot-grid corner marker.',
      enhancedBehavior:
          'The shield, label, dot grid, and outline are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.scheduledProgress,
      label: 'Scheduled progress',
      description: 'Warm mineral amber identifies hours already scheduled.',
      color: CoastalLightColors.scheduled,
      nonColorCue: 'Clock icon and forward diagonal hatch.',
      enhancedBehavior:
          'The clock, hatch, label, and boundary are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.today,
      label: 'Today or urgent',
      description:
          'Cool blue marks Today; coral with status text marks urgent attention.',
      color: CoastalLightColors.today,
      nonColorCue: 'TODAY top rule or explicit urgent warning status.',
      enhancedBehavior:
          'The rule, warning outline, and status text are strengthened.',
    ),
  ];
}

final class BotanicalStudyHelpGuide implements ThemeHelpGuide {
  const BotanicalStudyHelpGuide();

  @override
  String get themeId => botanicalStudyThemeId;

  @override
  String get title => 'Botanical Study calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      role: ThemeSemanticRole.clinicalSession,
      label: 'Clinical Session',
      description: 'Eucalyptus green identifies clinical activity.',
      color: BotanicalStudyColors.clinical,
      nonColorCue: 'Medical-services icon, CLINICAL label, and solid rail.',
      enhancedBehavior: 'The icon, label, and solid rail are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.workShift,
      label: 'Work Shift',
      description: 'Dusty rose identifies employment commitments.',
      color: BotanicalStudyColors.workAccent,
      nonColorCue: 'Briefcase icon, WORK label, and split rail.',
      enhancedBehavior: 'The icon, label, and split rail are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.protectedDay,
      label: 'Protected Day',
      description: 'Pale orchid and aubergine identify protected time.',
      color: BotanicalStudyColors.protectedDayAccent,
      nonColorCue: 'Shield icon, PROTECTED label, and full-cell outline.',
      enhancedBehavior: 'The shield, label, and outline are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.scheduledProgress,
      label: 'Scheduled progress',
      description: 'Warm ochre identifies hours already scheduled.',
      color: BotanicalStudyColors.scheduled,
      nonColorCue: 'Clock icon and diagonal hatch.',
      enhancedBehavior:
          'The clock, hatch, label, and boundary are strengthened.',
    ),
    CalendarStateGuide(
      role: ThemeSemanticRole.today,
      label: 'Today or urgent',
      description: 'A deep red inset rule marks Today and urgent attention.',
      color: BotanicalStudyColors.today,
      nonColorCue: 'TODAY label or warning icon with explicit status text.',
      enhancedBehavior:
          'Rules, warning outlines, and status text are strengthened.',
    ),
  ];
}

abstract interface class ClinicalCalendarThemeBundle {
  String get id;
  ThemeBundleOrigin get origin;
  ThemeCatalogMetadata get metadata;
  ClinicalCalendarStandardPresentation get standardPresentation;
  ClinicalCalendarShellRenderer get shellRenderer;
  ThemeFrameDescriptor get frame;
  ThemeGalleryData get gallery;
  ClinicalCalendarSemanticMarks get marks;
  ThemeHelpGuide get helpGuide;
}

final class VariantFThemeBundle implements ClinicalCalendarThemeBundle {
  const VariantFThemeBundle();

  @override
  String get id => variantFThemeId;

  @override
  ThemeBundleOrigin get origin => ThemeBundleOrigin.compiled;

  @override
  ThemeCatalogMetadata get metadata => const ThemeCatalogMetadata(
    themeId: variantFThemeId,
    displayName: 'Containment Drone 47-Alpha',
    personality:
        'The accepted gunmetal tactical identity, preserved unchanged.',
  );

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      const VariantFVisualTheme();

  @override
  ClinicalCalendarShellRenderer get shellRenderer =>
      const VariantFShellRenderer();

  @override
  ThemeFrameDescriptor get frame => const ThemeFrameDescriptor(
    themeId: variantFThemeId,
    assetPackage: 'clinical_calendar_presentation',
    primaryAsset: 'assets/variant_f_raster/panel-nine-slice-v2.png',
    assetPaths: [
      'assets/variant_f_raster/panel-nine-slice-v2.png',
      'assets/variant_f_raster/hardware-atlas.png',
      'assets/variant_f_raster/panel-atlas.png',
      'assets/variant_f_raster/rail-atlas.png',
    ],
    sourceSize: Size(1536, 1024),
    sourceCuts: EdgeInsets.fromLTRB(120, 145, 120, 170),
    safeInsets: {
      ThemeFrameRegion.calendar: EdgeInsets.fromLTRB(38, 46, 38, 46),
      ThemeFrameRegion.placements: EdgeInsets.fromLTRB(30, 44, 30, 44),
      ThemeFrameRegion.planning: EdgeInsets.fromLTRB(34, 46, 34, 42),
      ThemeFrameRegion.status: EdgeInsets.fromLTRB(30, 44, 34, 44),
    },
  );

  @override
  ThemeGalleryData get gallery => const ThemeGalleryData(
    themeId: variantFThemeId,
    rendererId: 'variant-f-existing-responsive-shell',
    thumbnailFixtureId: themeGalleryFixtureId,
    thumbnailViewport: themeGalleryViewport,
    swatches: [
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.canvas,
        label: 'Canvas',
        colorName: 'near-black graphite',
        color: VariantFColors.background,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.structure,
        label: 'Structure',
        colorName: 'gunmetal green',
        color: VariantFColors.surface,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.clinicalSession,
        label: 'Clinical Session',
        colorName: 'collective green',
        color: VariantFColors.primary,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.workShift,
        label: 'Work Shift',
        colorName: 'green steel',
        color: VariantFColors.workMachinery,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.urgent,
        label: 'Urgent',
        colorName: 'optic red',
        color: VariantFColors.urgent,
      ),
    ],
  );

  @override
  ClinicalCalendarSemanticMarks get marks =>
      const ClinicalCalendarSemanticMarks(
        themeId: variantFThemeId,
        marks: [
          ThemeSemanticMark(
            role: ThemeSemanticRole.clinicalSession,
            markId: 'medical-services-outline',
            icon: Icons.medical_services_outlined,
            description: 'Outlined medical-services icon',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.workShift,
            markId: 'work-outline',
            icon: Icons.work_outline,
            description: 'Outlined work icon',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.protectedDay,
            markId: 'protected-shield',
            icon: Icons.shield_outlined,
            description: 'Shield mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.scheduledProgress,
            markId: 'labelled-progress-segment',
            icon: Icons.schedule_outlined,
            description: 'Scheduled label and progress segment',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.completedSession,
            markId: 'completed-check-ring',
            icon: Icons.check_circle_outline,
            description: 'Completed check-circle mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.cancelledSession,
            markId: 'cancelled-slash-ring',
            icon: Icons.block_outlined,
            description: 'Cancelled slash-circle mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.missedSession,
            markId: 'missed-cross-ring',
            icon: Icons.highlight_off_outlined,
            description: 'Missed cross-circle mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.today,
            markId: 'outlined-date-border',
            icon: Icons.today_outlined,
            description: 'Today date-border mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.urgent,
            markId: 'urgent-warning-triangle',
            icon: Icons.warning_amber_outlined,
            description: 'Urgent warning-triangle mark',
          ),
        ],
      );

  @override
  ThemeHelpGuide get helpGuide => const VariantFHelpGuide();
}

final class GraphiteThemeBundle implements ClinicalCalendarThemeBundle {
  const GraphiteThemeBundle();

  @override
  String get id => graphiteThemeId;

  @override
  ThemeBundleOrigin get origin => ThemeBundleOrigin.compiled;

  @override
  ThemeCatalogMetadata get metadata => const ThemeCatalogMetadata(
    themeId: graphiteThemeId,
    displayName: 'Graphite',
    personality:
        'Neutral precision slate with cool silver and restrained emerald signals.',
  );

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      const GraphiteVisualTheme();

  @override
  ClinicalCalendarShellRenderer get shellRenderer =>
      const GraphiteShellRenderer();

  @override
  ThemeFrameDescriptor get frame => const ThemeFrameDescriptor(
    themeId: graphiteThemeId,
    assetPackage: 'clinical_calendar_presentation',
    primaryAsset: 'assets/graphite_raster/panel-nine-slice-v1.png',
    assetPaths: ['assets/graphite_raster/panel-nine-slice-v1.png'],
    sourceSize: Size(1536, 1024),
    sourceCuts: EdgeInsets.fromLTRB(120, 145, 120, 170),
    safeInsets: {
      ThemeFrameRegion.calendar: graphiteCalendarSafeInsets,
      ThemeFrameRegion.placements: graphitePlacementsSafeInsets,
      ThemeFrameRegion.planning: graphitePlanningSafeInsets,
      ThemeFrameRegion.status: graphiteStatusSafeInsets,
    },
  );

  @override
  ThemeGalleryData get gallery => const ThemeGalleryData(
    themeId: graphiteThemeId,
    rendererId: 'graphite-owned-responsive-instrument-v2',
    thumbnailFixtureId: themeGalleryFixtureId,
    thumbnailViewport: themeGalleryViewport,
    swatches: [
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.canvas,
        label: 'Canvas',
        colorName: 'near-black graphite',
        color: GraphiteColors.canvas,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.structure,
        label: 'Structure',
        colorName: 'layered charcoal',
        color: GraphiteColors.surfaceRaised,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.clinicalSession,
        label: 'Clinical Session',
        colorName: 'clear cobalt',
        color: GraphiteColors.clinical,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.workShift,
        label: 'Work Shift',
        colorName: 'cool violet',
        color: GraphiteColors.workAccent,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.urgent,
        label: 'Urgent',
        colorName: 'signal coral',
        color: GraphiteColors.urgent,
      ),
    ],
  );

  @override
  ClinicalCalendarSemanticMarks get marks =>
      const ClinicalCalendarSemanticMarks(
        themeId: graphiteThemeId,
        marks: [
          ThemeSemanticMark(
            role: ThemeSemanticRole.clinicalSession,
            markId: 'medical-services-outline',
            icon: Icons.medical_services_outlined,
            description: 'Medical cross and visible Clinical Session label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.workShift,
            markId: 'briefcase-diagonal-rail',
            icon: Icons.work_outline,
            description: 'Briefcase mark and diagonal rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.protectedDay,
            markId: 'shield-dot-rail',
            icon: Icons.shield_outlined,
            description: 'Shield mark and dotted rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.scheduledProgress,
            markId: 'clock-forward-hatch',
            icon: Icons.schedule_outlined,
            description: 'Clock mark and forward diagonal hatch',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.completedSession,
            markId: 'completed-check-ring',
            icon: Icons.check_circle_outline,
            description: 'Completed check-circle mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.cancelledSession,
            markId: 'cancelled-slash-ring',
            icon: Icons.block_outlined,
            description: 'Cancelled slash-circle mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.missedSession,
            markId: 'missed-cross-ring',
            icon: Icons.highlight_off_outlined,
            description: 'Missed cross-circle mark',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.today,
            markId: 'today-dot-outline',
            icon: Icons.today_outlined,
            description: 'Today dot and date outline',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.urgent,
            markId: 'urgent-warning-triangle',
            icon: Icons.warning_amber_outlined,
            description: 'Urgent warning-triangle mark',
          ),
        ],
      );

  @override
  ThemeHelpGuide get helpGuide => const GraphiteHelpGuide();
}

final class FederationClassicThemeBundle
    implements ClinicalCalendarThemeBundle {
  const FederationClassicThemeBundle();

  @override
  String get id => federationClassicThemeId;

  @override
  ThemeBundleOrigin get origin => ThemeBundleOrigin.compiled;

  @override
  ThemeCatalogMetadata get metadata => const ThemeCatalogMetadata(
    themeId: federationClassicThemeId,
    displayName: 'Federation Classic',
    personality:
        'Warm amber and lilac structure around calm, high-contrast content bays.',
  );

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      const FederationClassicVisualTheme();

  @override
  ClinicalCalendarShellRenderer get shellRenderer =>
      const FederationClassicShellRenderer();

  @override
  ThemeFrameDescriptor get frame => const ThemeFrameDescriptor(
    themeId: federationClassicThemeId,
    assetPackage: 'clinical_calendar_presentation',
    primaryAsset: federationClassicFrameAsset,
    assetPaths: [
      federationClassicFrameAsset,
      federationClassicLandscapeChassisAsset,
    ],
    sourceSize: Size(1536, 1024),
    sourceCuts: EdgeInsets.fromLTRB(120, 145, 120, 170),
    safeInsets: {
      ThemeFrameRegion.calendar: federationClassicCalendarSafeInsets,
      ThemeFrameRegion.placements: federationClassicPlacementsSafeInsets,
      ThemeFrameRegion.planning: federationClassicPlanningSafeInsets,
      ThemeFrameRegion.status: federationClassicStatusSafeInsets,
    },
  );

  @override
  ThemeGalleryData get gallery => const ThemeGalleryData(
    themeId: federationClassicThemeId,
    rendererId: 'federation-classic-owned-responsive-console-v2',
    thumbnailFixtureId: themeGalleryFixtureId,
    thumbnailViewport: themeGalleryViewport,
    swatches: [
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.canvas,
        label: 'Canvas',
        colorName: 'near-black plum',
        color: FederationClassicColors.canvas,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.structure,
        label: 'Structure',
        colorName: 'raised plum',
        color: FederationClassicColors.surfaceRaised,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.clinicalSession,
        label: 'Clinical Session',
        colorName: 'warm salmon',
        color: FederationClassicColors.clinical,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.workShift,
        label: 'Work Shift',
        colorName: 'soft lilac',
        color: FederationClassicColors.workAccent,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.urgent,
        label: 'Urgent',
        colorName: 'signal coral',
        color: FederationClassicColors.urgent,
      ),
    ],
  );

  @override
  ClinicalCalendarSemanticMarks get marks =>
      const ClinicalCalendarSemanticMarks(
        themeId: federationClassicThemeId,
        marks: [
          ThemeSemanticMark(
            role: ThemeSemanticRole.clinicalSession,
            markId: 'clinical-solid-leading-rail',
            icon: Icons.medical_services_outlined,
            description:
                'Medical-services icon, CLINICAL label, and solid rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.workShift,
            markId: 'work-paired-leading-rails',
            icon: Icons.work_outline,
            description: 'Briefcase icon, WORK label, and paired rail marks',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.protectedDay,
            markId: 'protected-dot-grid-corner',
            icon: Icons.shield_outlined,
            description: 'Shield icon, PROTECTED label, and dot-grid marker',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.scheduledProgress,
            markId: 'scheduled-forward-hatch',
            icon: Icons.schedule_outlined,
            description: 'Clock icon and forward diagonal hatch',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.completedSession,
            markId: 'completed-check-ring',
            icon: Icons.check_circle_outline,
            description: 'Completed check-circle mark and COMPLETED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.cancelledSession,
            markId: 'cancelled-diagonal-slash',
            icon: Icons.block_outlined,
            description: 'Diagonal slash mark and CANCELLED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.missedSession,
            markId: 'missed-cross-ring',
            icon: Icons.highlight_off_outlined,
            description: 'Cross mark and MISSED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.today,
            markId: 'today-top-rule',
            icon: Icons.today_outlined,
            description: 'Top rule and visible TODAY label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.urgent,
            markId: 'urgent-warning-status',
            icon: Icons.warning_amber_outlined,
            description: 'Warning icon, outline, and explicit urgent status',
          ),
        ],
      );

  @override
  ThemeHelpGuide get helpGuide => const FederationClassicHelpGuide();
}

final class Federation2399ThemeBundle implements ClinicalCalendarThemeBundle {
  const Federation2399ThemeBundle();

  @override
  String get id => federation2399ThemeId;

  @override
  ThemeBundleOrigin get origin => ThemeBundleOrigin.compiled;

  @override
  ThemeCatalogMetadata get metadata => const ThemeCatalogMetadata(
    themeId: federation2399ThemeId,
    displayName: 'Federation 2399',
    personality:
        'Layered burgundy structure, cool instrument light, and restrained aged amber.',
  );

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      const Federation2399VisualTheme();

  @override
  ClinicalCalendarShellRenderer get shellRenderer =>
      const Federation2399ShellRenderer();

  @override
  ThemeFrameDescriptor get frame => const ThemeFrameDescriptor(
    themeId: federation2399ThemeId,
    assetPackage: 'clinical_calendar_presentation',
    primaryAsset: federation2399FrameAsset,
    assetPaths: [
      federation2399FrameAsset,
      federation2399LandscapeChassisAsset,
      federation2399DeltaAsset,
    ],
    sourceSize: Size(1536, 1024),
    sourceCuts: EdgeInsets.fromLTRB(120, 145, 120, 170),
    safeInsets: {
      ThemeFrameRegion.calendar: federation2399CalendarSafeInsets,
      ThemeFrameRegion.placements: federation2399PlacementsSafeInsets,
      ThemeFrameRegion.planning: federation2399PlanningSafeInsets,
      ThemeFrameRegion.status: federation2399StatusSafeInsets,
    },
  );

  @override
  ThemeGalleryData get gallery => const ThemeGalleryData(
    themeId: federation2399ThemeId,
    rendererId: 'federation-2399-owned-responsive-console-v4',
    thumbnailFixtureId: themeGalleryFixtureId,
    thumbnailViewport: themeGalleryViewport,
    swatches: [
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.canvas,
        label: 'Canvas',
        colorName: 'charcoal black',
        color: Federation2399Colors.canvas,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.structure,
        label: 'Structure',
        colorName: 'layered charcoal',
        color: Federation2399Colors.surface,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.clinicalSession,
        label: 'Clinical Session',
        colorName: 'restrained plum',
        color: Federation2399Colors.clinical,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.workShift,
        label: 'Work Shift',
        colorName: 'cool instrument blue',
        color: Federation2399Colors.workMachinery,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.urgent,
        label: 'Urgent',
        colorName: 'signal coral',
        color: Federation2399Colors.urgent,
      ),
    ],
  );

  @override
  ClinicalCalendarSemanticMarks get marks =>
      const ClinicalCalendarSemanticMarks(
        themeId: federation2399ThemeId,
        marks: [
          ThemeSemanticMark(
            role: ThemeSemanticRole.clinicalSession,
            markId: 'clinical-continuous-leading-rail',
            icon: Icons.medical_services_outlined,
            description:
                'Medical-services icon, CLINICAL label, and continuous rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.workShift,
            markId: 'work-separated-leading-rails',
            icon: Icons.work_outline,
            description:
                'Briefcase icon, WORK label, and separated rail segments',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.protectedDay,
            markId: 'protected-dot-grid-corner',
            icon: Icons.shield_outlined,
            description: 'Shield icon, PROTECTED label, and dot-grid marker',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.scheduledProgress,
            markId: 'scheduled-forward-hatch',
            icon: Icons.schedule_outlined,
            description: 'Clock icon and forward diagonal hatch',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.completedSession,
            markId: 'completed-check-ring',
            icon: Icons.check_circle_outline,
            description: 'Check-circle mark and COMPLETED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.cancelledSession,
            markId: 'cancelled-diagonal-slash',
            icon: Icons.block_outlined,
            description: 'Diagonal slash mark and CANCELLED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.missedSession,
            markId: 'missed-cross-ring',
            icon: Icons.highlight_off_outlined,
            description: 'Cross mark and MISSED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.today,
            markId: 'today-top-rule',
            icon: Icons.today_outlined,
            description: 'Top rule and visible TODAY label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.urgent,
            markId: 'urgent-warning-status',
            icon: Icons.warning_amber_outlined,
            description: 'Warning icon, outline, and explicit urgent status',
          ),
        ],
      );

  @override
  ThemeHelpGuide get helpGuide => const Federation2399HelpGuide();
}

final class CoastalLightThemeBundle implements ClinicalCalendarThemeBundle {
  const CoastalLightThemeBundle();

  @override
  String get id => coastalCalmThemeId;

  @override
  ThemeBundleOrigin get origin => ThemeBundleOrigin.compiled;

  @override
  ThemeCatalogMetadata get metadata => const ThemeCatalogMetadata(
    themeId: coastalCalmThemeId,
    displayName: 'Coastal Light',
    personality:
        'Shell-white calm, sea-glass structure, clear-blue rules, and warm mineral depth.',
  );

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      const CoastalLightVisualTheme();

  @override
  ClinicalCalendarShellRenderer get shellRenderer =>
      const CoastalLightShellRenderer();

  @override
  ThemeFrameDescriptor get frame => const ThemeFrameDescriptor(
    themeId: coastalCalmThemeId,
    assetPackage: 'clinical_calendar_presentation',
    primaryAsset: coastalLightFrameAsset,
    assetPaths: [coastalLightFrameAsset, coastalLightLandscapeChassisAsset],
    sourceSize: Size(1536, 1024),
    sourceCuts: EdgeInsets.fromLTRB(120, 145, 120, 170),
    safeInsets: {
      ThemeFrameRegion.calendar: coastalLightCalendarSafeInsets,
      ThemeFrameRegion.placements: coastalLightPlacementsSafeInsets,
      ThemeFrameRegion.planning: coastalLightPlanningSafeInsets,
      ThemeFrameRegion.status: coastalLightStatusSafeInsets,
    },
  );

  @override
  ThemeGalleryData get gallery => const ThemeGalleryData(
    themeId: coastalCalmThemeId,
    rendererId: 'coastal-light-owned-responsive-observatory-v1',
    thumbnailFixtureId: themeGalleryFixtureId,
    thumbnailViewport: themeGalleryViewport,
    swatches: [
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.canvas,
        label: 'Canvas',
        colorName: 'mist field',
        color: CoastalLightColors.canvas,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.structure,
        label: 'Structure',
        colorName: 'shell white',
        color: CoastalLightColors.surface,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.clinicalSession,
        label: 'Clinical Session',
        colorName: 'sea-glass teal',
        color: CoastalLightColors.clinical,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.workShift,
        label: 'Work Shift',
        colorName: 'clear blue',
        color: CoastalLightColors.workMachinery,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.urgent,
        label: 'Urgent',
        colorName: 'controlled coral',
        color: CoastalLightColors.urgent,
      ),
    ],
  );

  @override
  ClinicalCalendarSemanticMarks get marks =>
      const ClinicalCalendarSemanticMarks(
        themeId: coastalCalmThemeId,
        marks: [
          ThemeSemanticMark(
            role: ThemeSemanticRole.clinicalSession,
            markId: 'clinical-continuous-leading-rail',
            icon: Icons.medical_services_outlined,
            description:
                'Medical-services icon, CLINICAL label, and continuous rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.workShift,
            markId: 'work-separated-leading-rails',
            icon: Icons.work_outline,
            description:
                'Briefcase icon, WORK label, and separated rail segments',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.protectedDay,
            markId: 'protected-dot-grid-corner',
            icon: Icons.shield_outlined,
            description: 'Shield icon, PROTECTED label, and dot-grid marker',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.scheduledProgress,
            markId: 'scheduled-forward-hatch',
            icon: Icons.schedule_outlined,
            description: 'Clock icon and forward diagonal hatch',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.completedSession,
            markId: 'completed-check-ring',
            icon: Icons.check_circle_outline,
            description: 'Check-circle mark and COMPLETED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.cancelledSession,
            markId: 'cancelled-diagonal-slash',
            icon: Icons.block_outlined,
            description: 'Diagonal slash mark and CANCELLED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.missedSession,
            markId: 'missed-cross-ring',
            icon: Icons.highlight_off_outlined,
            description: 'Cross mark and MISSED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.today,
            markId: 'today-top-rule',
            icon: Icons.today_outlined,
            description: 'Top rule and visible TODAY label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.urgent,
            markId: 'urgent-warning-status',
            icon: Icons.warning_amber_outlined,
            description: 'Warning icon, outline, and explicit urgent status',
          ),
        ],
      );

  @override
  ThemeHelpGuide get helpGuide => const CoastalLightHelpGuide();
}

final class BotanicalStudyThemeBundle implements ClinicalCalendarThemeBundle {
  const BotanicalStudyThemeBundle();

  @override
  String get id => botanicalStudyThemeId;

  @override
  ThemeBundleOrigin get origin => ThemeBundleOrigin.compiled;

  @override
  ThemeCatalogMetadata get metadata => const ThemeCatalogMetadata(
    themeId: botanicalStudyThemeId,
    displayName: 'Botanical Study',
    personality:
        'Warm ivory, sage structure, and restrained scientific botanical detail.',
  );

  @override
  ClinicalCalendarStandardPresentation get standardPresentation =>
      const BotanicalStudyVisualTheme();

  @override
  ClinicalCalendarShellRenderer get shellRenderer =>
      const BotanicalStudyShellRenderer();

  @override
  ThemeFrameDescriptor get frame => const ThemeFrameDescriptor(
    themeId: botanicalStudyThemeId,
    assetPackage: 'clinical_calendar_presentation',
    primaryAsset: botanicalStudyFrameAsset,
    assetPaths: [botanicalStudyFrameAsset, botanicalStudyLandscapeChassisAsset],
    sourceSize: Size(1536, 1024),
    sourceCuts: EdgeInsets.fromLTRB(120, 145, 120, 170),
    safeInsets: {
      ThemeFrameRegion.calendar: botanicalStudyCalendarSafeInsets,
      ThemeFrameRegion.placements: botanicalStudyPlacementsSafeInsets,
      ThemeFrameRegion.planning: botanicalStudyPlanningSafeInsets,
      ThemeFrameRegion.status: botanicalStudyStatusSafeInsets,
    },
  );

  @override
  ThemeGalleryData get gallery => const ThemeGalleryData(
    themeId: botanicalStudyThemeId,
    rendererId: 'botanical-study-owned-research-desk-v1',
    thumbnailFixtureId: themeGalleryFixtureId,
    thumbnailViewport: themeGalleryViewport,
    swatches: [
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.canvas,
        label: 'Canvas',
        colorName: 'warm ivory',
        color: BotanicalStudyColors.canvas,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.structure,
        label: 'Structure',
        colorName: 'pale sage',
        color: BotanicalStudyColors.housing,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.clinicalSession,
        label: 'Clinical Session',
        colorName: 'eucalyptus',
        color: BotanicalStudyColors.clinical,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.workShift,
        label: 'Work Shift',
        colorName: 'dusty rose',
        color: BotanicalStudyColors.workAccent,
      ),
      ThemeGallerySwatch(
        role: ThemeGallerySwatchRole.urgent,
        label: 'Urgent',
        colorName: 'deep red',
        color: BotanicalStudyColors.urgent,
      ),
    ],
  );

  @override
  ClinicalCalendarSemanticMarks get marks =>
      const ClinicalCalendarSemanticMarks(
        themeId: botanicalStudyThemeId,
        marks: [
          ThemeSemanticMark(
            role: ThemeSemanticRole.clinicalSession,
            markId: 'clinical-solid-specimen-rail',
            icon: Icons.medical_services_outlined,
            description:
                'Medical-services icon, CLINICAL label, and solid rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.workShift,
            markId: 'work-split-mounting-rail',
            icon: Icons.work_outline,
            description: 'Briefcase icon, WORK label, and split mounting rail',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.protectedDay,
            markId: 'protected-orchid-outline',
            icon: Icons.shield_outlined,
            description: 'Shield icon, PROTECTED label, and full outline',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.scheduledProgress,
            markId: 'scheduled-diagonal-hatch',
            icon: Icons.schedule_outlined,
            description: 'Clock icon and diagonal hatch',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.completedSession,
            markId: 'completed-check-ring',
            icon: Icons.check_circle_outline,
            description: 'Check-circle mark and COMPLETED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.cancelledSession,
            markId: 'cancelled-diagonal-slash',
            icon: Icons.block_outlined,
            description: 'Diagonal slash mark and CANCELLED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.missedSession,
            markId: 'missed-cross-ring',
            icon: Icons.highlight_off_outlined,
            description: 'Cross mark and MISSED label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.today,
            markId: 'today-red-inset-rule',
            icon: Icons.today_outlined,
            description: 'Deep red inset rule and visible TODAY label',
          ),
          ThemeSemanticMark(
            role: ThemeSemanticRole.urgent,
            markId: 'urgent-warning-status',
            icon: Icons.warning_amber_outlined,
            description: 'Warning icon, outline, and explicit urgent status',
          ),
        ],
      );

  @override
  ThemeHelpGuide get helpGuide => const BotanicalStudyHelpGuide();
}

final class InvalidThemeBundle implements Exception {
  const InvalidThemeBundle(this.message);

  final String message;

  @override
  String toString() => 'InvalidThemeBundle: $message';
}

abstract final class ClinicalCalendarThemeBundleValidator {
  static void validate(Iterable<ClinicalCalendarThemeBundle> bundles) {
    final seen = <String>{};
    for (final bundle in bundles) {
      final id = bundle.id.trim();
      if (id.isEmpty) {
        throw const InvalidThemeBundle('Theme identifiers cannot be empty.');
      }
      if (!seen.add(id)) {
        throw InvalidThemeBundle('Duplicate theme identifier: $id.');
      }
      if (bundle.origin != ThemeBundleOrigin.compiled) {
        throw InvalidThemeBundle(
          'Theme $id is not a compile-time local bundle.',
        );
      }

      final owned = <ThemeOwnedComponent>[
        bundle.metadata,
        bundle.standardPresentation,
        bundle.shellRenderer,
        bundle.frame,
        bundle.gallery,
        bundle.marks,
        bundle.helpGuide,
      ];
      for (final component in owned) {
        if (component.themeId != id) {
          throw InvalidThemeBundle(
            'Theme $id borrows a component owned by ${component.themeId}.',
          );
        }
      }

      if (bundle.metadata.displayName.trim().isEmpty ||
          bundle.metadata.personality.trim().isEmpty ||
          bundle.frame.assetPackage.trim().isEmpty ||
          bundle.frame.primaryAsset.trim().isEmpty ||
          bundle.frame.assetPaths.isEmpty ||
          !bundle.frame.assetPaths.contains(bundle.frame.primaryAsset) ||
          bundle.frame.sourceSize.isEmpty ||
          bundle.frame.safeInsets.length != ThemeFrameRegion.values.length ||
          bundle.gallery.thumbnailFixtureId.trim().isEmpty ||
          bundle.gallery.thumbnailViewport.isEmpty ||
          bundle.gallery.swatches.length !=
              ThemeGallerySwatchRole.values.length ||
          bundle.marks.marks.length != ThemeSemanticRole.values.length ||
          bundle.helpGuide.title.trim().isEmpty ||
          bundle.helpGuide.calendarStates.length != 5) {
        throw InvalidThemeBundle('Theme $id is incomplete.');
      }
      if (bundle.gallery.rendererId != bundle.shellRenderer.rendererId) {
        throw InvalidThemeBundle(
          'Theme $id gallery is not generated by its shell renderer.',
        );
      }
      if ({for (final swatch in bundle.gallery.swatches) swatch.role}.length !=
              ThemeGallerySwatchRole.values.length ||
          {for (final mark in bundle.marks.marks) mark.role}.length !=
              ThemeSemanticRole.values.length) {
        throw InvalidThemeBundle('Theme $id has incomplete semantic roles.');
      }
      if (bundle.marks.marks.any(
            (mark) =>
                mark.markId.trim().isEmpty || mark.description.trim().isEmpty,
          ) ||
          bundle.helpGuide.calendarStates.any(
            (state) =>
                state.label.trim().isEmpty ||
                state.description.trim().isEmpty ||
                state.nonColorCue.trim().isEmpty ||
                state.enhancedBehavior.trim().isEmpty,
          )) {
        throw InvalidThemeBundle('Theme $id has incomplete accessible cues.');
      }
    }
  }
}

/// Closed root resolver. It has no registration API and exposes no selectable
/// catalog until the ratified seven complete bundles exist together.
final class ClinicalCalendarThemeBundleRegistry {
  ClinicalCalendarThemeBundleRegistry._(this._bundles) {
    ClinicalCalendarThemeBundleValidator.validate(_bundles.values);
  }

  static final standard = ClinicalCalendarThemeBundleRegistry._({
    variantFThemeId: const VariantFThemeBundle(),
    graphiteThemeId: const GraphiteThemeBundle(),
    federationClassicThemeId: const FederationClassicThemeBundle(),
    federation2399ThemeId: const Federation2399ThemeBundle(),
    coastalCalmThemeId: const CoastalLightThemeBundle(),
    botanicalStudyThemeId: const BotanicalStudyThemeBundle(),
  });

  final Map<String, ClinicalCalendarThemeBundle> _bundles;

  bool get isSelectableCatalogComplete => false;

  List<ClinicalCalendarThemeBundle> get selectableBundles => const [];

  /// Complete bundles that may be inspected before catalog activation.
  /// Inspection does not make a bundle selectable or applied.
  List<ClinicalCalendarThemeBundle> get galleryBundles =>
      List.unmodifiable(_bundles.values);

  /// Fixed account-independent presentation for every unauthenticated state.
  ClinicalCalendarThemeBundle resolveSignedOut() => _bundles[graphiteThemeId]!;

  ClinicalCalendarThemeBundle resolveRoot(String id) {
    final bundle = _bundles[id];
    if (bundle == null) {
      throw InvalidThemeBundle(
        'Theme $id is unavailable before the complete catalog ships.',
      );
    }
    return bundle;
  }

  AppliedThemeResolution resolveApplied(String storedId) {
    if (storedId == variantFThemeId) {
      return AppliedThemeResolution(
        storedId: storedId,
        bundle: _bundles[variantFThemeId]!,
        isFallback: false,
      );
    }
    return AppliedThemeResolution(
      storedId: storedId,
      bundle: _bundles[graphiteThemeId]!,
      isFallback: true,
    );
  }

  Future<CandidateThemePreflightResult> preflightCandidate({
    required AppliedThemeResolution applied,
    required String candidateId,
    required Future<void> Function(ClinicalCalendarThemeBundle candidate)
    preflight,
  }) async {
    final candidate = _bundles[candidateId];
    if (candidate == null) {
      return CandidateThemePreflightResult.unavailable(applied: applied);
    }
    try {
      await preflight(candidate);
      return CandidateThemePreflightResult.available(
        applied: applied,
        candidate: candidate,
      );
    } on Object {
      return CandidateThemePreflightResult.unavailable(applied: applied);
    }
  }
}

@immutable
final class AppliedThemeResolution {
  const AppliedThemeResolution({
    required this.storedId,
    required this.bundle,
    required this.isFallback,
  });

  final String storedId;
  final ClinicalCalendarThemeBundle bundle;
  final bool isFallback;
}

@immutable
final class CandidateThemePreflightResult {
  const CandidateThemePreflightResult._({
    required this.applied,
    required this.candidate,
    required this.previewUnavailable,
  });

  const CandidateThemePreflightResult.available({
    required AppliedThemeResolution applied,
    required ClinicalCalendarThemeBundle candidate,
  }) : this._(
         applied: applied,
         candidate: candidate,
         previewUnavailable: false,
       );

  const CandidateThemePreflightResult.unavailable({
    required AppliedThemeResolution applied,
  }) : this._(applied: applied, candidate: null, previewUnavailable: true);

  final AppliedThemeResolution applied;
  final ClinicalCalendarThemeBundle? candidate;
  final bool previewUnavailable;

  ClinicalCalendarThemeBundle get effectiveBundle =>
      candidate ?? applied.bundle;
}
