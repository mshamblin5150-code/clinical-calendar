import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'federation_2399_frame.dart';
import 'responsive_shell.dart';

const federation2399CompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildFederation2399Frame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => Federation2399NineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class Federation2399DestinationSurface extends StatelessWidget {
  const Federation2399DestinationSurface({
    required this.destination,
    required this.entry,
    required this.onExit,
    required this.child,
    super.key,
  });

  final ClinicalCalendarDestination destination;
  final DestinationEntry entry;
  final VoidCallback onExit;
  final Widget child;

  @override
  Widget build(BuildContext context) => AdditiveThemeDestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    frameBuilder: _buildFederation2399Frame,
    statusSafeInsets: federation2399StatusSafeInsets,
    compactDestinationInsets: federation2399CompactDestinationInsets,
    child: child,
  );
}

final class Federation2399ApplicationShell extends StatelessWidget {
  const Federation2399ApplicationShell({
    required this.slots,
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenDestination,
    required this.onOpenAttention,
    required this.onAddSchedule,
    this.mobileIndex = 1,
    super.key,
  });

  final ResponsiveShellSlots slots;
  final String environmentName;
  final VoidCallback onOpenMenu;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;
  final VoidCallback onAddSchedule;
  final int mobileIndex;

  @override
  Widget build(BuildContext context) => AdditiveThemeApplicationShell(
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildFederation2399Frame,
    calendarSafeInsets: federation2399CalendarSafeInsets,
    placementsSafeInsets: federation2399PlacementsSafeInsets,
    planningSafeInsets: federation2399PlanningSafeInsets,
    statusSafeInsets: federation2399StatusSafeInsets,
  );
}
