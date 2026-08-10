import 'package:flutter/material.dart';

import 'responsive_shell.dart';
import 'variant_f_raster_assets.dart';
import 'variant_f_theme.dart';

/// Stable behavior model for the five primary shell navigation actions.
///
/// Theme-owned shells may render these actions differently, but routing stays
/// centralized here so a visual theme cannot fork application behavior.
enum ClinicalCalendarPrimaryNavigation {
  today('TODAY', Icons.today_outlined),
  calendar('CALENDAR', Icons.calendar_month_outlined),
  placements('PLACEMENTS', Icons.track_changes_outlined),
  attention('ATTENTION', Icons.notifications_outlined),
  settings('SETTINGS', Icons.settings_outlined);

  const ClinicalCalendarPrimaryNavigation(this.label, this.icon);

  final String label;
  final IconData icon;

  void activate({
    required ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    required VoidCallback onOpenAttention,
  }) {
    switch (this) {
      case ClinicalCalendarPrimaryNavigation.today:
      case ClinicalCalendarPrimaryNavigation.calendar:
        onOpenDestination(ClinicalCalendarDestination.calendar);
      case ClinicalCalendarPrimaryNavigation.placements:
        onOpenDestination(ClinicalCalendarDestination.clinicalPlacements);
      case ClinicalCalendarPrimaryNavigation.attention:
        onOpenAttention();
      case ClinicalCalendarPrimaryNavigation.settings:
        onOpenDestination(ClinicalCalendarDestination.settings);
    }
  }
}

typedef AdditiveThemeFrameBuilder =
    Widget Function(
      Widget child,
      EdgeInsets chromeInsets,
      EdgeInsets contentPadding,
    );

/// Uses the frozen renderer's existing no-nested-frame protocol. This marker
/// paints no Variant F pixels and contributes no theme-owned presentation.
final class AdditiveThemePanelInterior extends StatelessWidget {
  const AdditiveThemePanelInterior({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      VariantFRasterPanelInterior(child: child);
}

final class AdditiveThemeDestinationSurface extends StatelessWidget {
  const AdditiveThemeDestinationSurface({
    required this.destination,
    required this.entry,
    required this.onExit,
    required this.child,
    required this.frameBuilder,
    required this.statusSafeInsets,
    required this.compactDestinationInsets,
    super.key,
  });

  final ClinicalCalendarDestination destination;
  final DestinationEntry entry;
  final VoidCallback onExit;
  final Widget child;
  final AdditiveThemeFrameBuilder frameBuilder;
  final EdgeInsets statusSafeInsets;
  final EdgeInsets compactDestinationInsets;

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clinicalColors.structure,
        leadingWidth: enlargedText
            ? 144
            : entry == DestinationEntry.applicationMenu
            ? 88
            : 96,
        toolbarHeight: enlargedText ? 72 : null,
        leading: TextButton.icon(
          key: Key(
            entry == DestinationEntry.applicationMenu
                ? 'back-action'
                : 'close-action',
          ),
          onPressed: onExit,
          icon: Icon(
            entry == DestinationEntry.applicationMenu
                ? Icons.arrow_back
                : Icons.close,
            size: 18,
          ),
          label: Text(
            entry == DestinationEntry.applicationMenu ? 'Back' : 'Close',
          ),
        ),
        title: Text(destination.label),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) => frameBuilder(
              AdditiveThemePanelInterior(child: child),
              constraints.maxWidth < 600
                  ? compactDestinationInsets
                  : statusSafeInsets,
              const EdgeInsets.all(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// One shared additive shell with theme-owned framing injected at its edge.
final class AdditiveThemeApplicationShell extends StatelessWidget {
  const AdditiveThemeApplicationShell({
    required this.slots,
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenDestination,
    required this.onOpenAttention,
    required this.onAddSchedule,
    required this.frameBuilder,
    required this.calendarSafeInsets,
    required this.placementsSafeInsets,
    required this.planningSafeInsets,
    required this.statusSafeInsets,
    this.mobileIndex = 1,
    super.key,
  });

  final ResponsiveShellSlots slots;
  final String environmentName;
  final VoidCallback onOpenMenu;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;
  final VoidCallback onAddSchedule;
  final AdditiveThemeFrameBuilder frameBuilder;
  final EdgeInsets calendarSafeInsets;
  final EdgeInsets placementsSafeInsets;
  final EdgeInsets planningSafeInsets;
  final EdgeInsets statusSafeInsets;
  final int mobileIndex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop =
          constraints.maxWidth >= 960 &&
          constraints.maxHeight >= 600 &&
          constraints.maxWidth > constraints.maxHeight;
      return desktop ? _desktop() : _mobile();
    },
  );

  Widget _desktop() => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          _AdditiveThemeHeader(
            environmentName: environmentName,
            onOpenMenu: onOpenMenu,
            onAddSchedule: onAddSchedule,
            onOpenDestination: onOpenDestination,
            profileAvatar: slots.profileAvatar,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    key: const Key('placement-dock'),
                    width: 216,
                    child: _panel(slots.placementDock, placementsSafeInsets),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const Key('desktop-content-scroll'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          KeyedSubtree(
                            key: const Key('central-content'),
                            child: _panel(
                              slots.centralContent,
                              calendarSafeInsets,
                            ),
                          ),
                          const SizedBox(height: 12),
                          KeyedSubtree(
                            key: const Key('planning-region'),
                            child: _panel(
                              slots.planningRegion,
                              planningSafeInsets,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const Key('insight-rail'),
                    width: 232,
                    child: _panel(slots.insightRail, statusSafeInsets),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _mobile() => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        key: const Key('application-menu-action'),
        tooltip: 'Open menu',
        onPressed: onOpenMenu,
        icon: const Icon(Icons.menu),
      ),
      title: const Text('Clinical Calendar'),
      actions: [
        IconButton(
          tooltip: 'Add schedule',
          onPressed: onAddSchedule,
          icon: const Icon(Icons.add_box_outlined),
        ),
        slots.profileAvatar,
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const Key('mobile-content-scroll'),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: const Key('central-content'),
              child: _panel(slots.centralContent, calendarSafeInsets),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('mobile-placement-summary'),
              child: _panel(slots.mobilePlacementSummary, placementsSafeInsets),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('mobile-attention'),
              child: _panel(slots.mobileAttention, statusSafeInsets),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('planning-region'),
              child: _panel(slots.planningRegion, planningSafeInsets),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      key: const Key('bottom-navigation'),
      selectedIndex: mobileIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
          case 1:
            onOpenDestination(ClinicalCalendarDestination.calendar);
            return;
          case 2:
            onOpenDestination(ClinicalCalendarDestination.clinicalPlacements);
            return;
          case 3:
            onOpenAttention();
            return;
          case 4:
            onOpenDestination(ClinicalCalendarDestination.settings);
            return;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.track_changes_outlined),
          label: 'Placements',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          label: 'Attention',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    ),
  );

  Widget _panel(Widget child, EdgeInsets safeInsets) => frameBuilder(
    AdditiveThemePanelInterior(child: child),
    safeInsets,
    const EdgeInsets.all(8),
  );
}

final class _AdditiveThemeHeader extends StatelessWidget {
  const _AdditiveThemeHeader({
    required this.environmentName,
    required this.onOpenMenu,
    required this.onAddSchedule,
    required this.onOpenDestination,
    required this.profileAvatar,
  });

  final String environmentName;
  final VoidCallback onOpenMenu;
  final VoidCallback onAddSchedule;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final Widget profileAvatar;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: Row(
      children: [
        const SizedBox(width: 12),
        IconButton(
          key: const Key('application-menu-action'),
          tooltip: 'Open menu',
          onPressed: onOpenMenu,
          icon: const Icon(Icons.grid_view_outlined),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.calendar_month_outlined),
        const SizedBox(width: 10),
        const Text('CLINICAL CALENDAR'),
        if (environmentName.trim().isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(environmentName, style: Theme.of(context).textTheme.labelSmall),
        ],
        const Spacer(),
        IconButton(
          tooltip: 'Add schedule',
          onPressed: onAddSchedule,
          icon: const Icon(Icons.add_box_outlined),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () =>
              onOpenDestination(ClinicalCalendarDestination.notifications),
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          tooltip: 'Help',
          onPressed: () => onOpenDestination(ClinicalCalendarDestination.help),
          icon: const Icon(Icons.help_outline),
        ),
        profileAvatar,
        const SizedBox(width: 12),
      ],
    ),
  );
}
