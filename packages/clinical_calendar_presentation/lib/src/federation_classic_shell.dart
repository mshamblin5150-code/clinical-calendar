import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'federation_classic_frame.dart';
import 'responsive_shell.dart';

const federationClassicCompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildFederationClassicFrame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => FederationClassicNineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class FederationClassicDestinationSurface extends StatelessWidget {
  const FederationClassicDestinationSurface({
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
    frameBuilder: _buildFederationClassicFrame,
    statusSafeInsets: federationClassicStatusSafeInsets,
    compactDestinationInsets: federationClassicCompactDestinationInsets,
    child: child,
  );
}

final class FederationClassicApplicationShell extends StatelessWidget {
  const FederationClassicApplicationShell({
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
    frameBuilder: _buildFederationClassicFrame,
    calendarSafeInsets: federationClassicCalendarSafeInsets,
    placementsSafeInsets: federationClassicPlacementsSafeInsets,
    planningSafeInsets: federationClassicPlanningSafeInsets,
    statusSafeInsets: federationClassicStatusSafeInsets,
  );
}
