import 'package:flutter/material.dart';

import 'graphite_frame.dart';
import 'graphite_shell.dart';
import 'graphite_theme.dart';
import 'responsive_shell.dart';
import 'tactical_frame.dart';
import 'variant_f_theme.dart';

const variantFThemeId = 'variant-f';
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
  String get rendererId => 'graphite-additive-responsive-shell-v1';

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
    child: GraphitePanelInterior(child: child),
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
    rendererId: 'graphite-additive-responsive-shell-v1',
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
  });

  final Map<String, ClinicalCalendarThemeBundle> _bundles;

  bool get isSelectableCatalogComplete => false;

  List<ClinicalCalendarThemeBundle> get selectableBundles => const [];

  /// Complete bundles that may be inspected before catalog activation.
  /// Inspection does not make a bundle selectable or applied.
  List<ClinicalCalendarThemeBundle> get galleryBundles =>
      List.unmodifiable(_bundles.values);

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
