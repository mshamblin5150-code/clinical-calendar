import 'package:flutter/material.dart';

import 'graphite_frame.dart';
import 'responsive_shell.dart';

/// Shared workflow slots rendered through Graphite-owned chrome and assets.
final class GraphiteApplicationShell extends StatelessWidget {
  const GraphiteApplicationShell({
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
          _GraphiteHeader(
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
                    child: _panel(
                      slots.placementDock,
                      graphitePlacementsSafeInsets,
                    ),
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
                              graphiteCalendarSafeInsets,
                            ),
                          ),
                          const SizedBox(height: 12),
                          KeyedSubtree(
                            key: const Key('planning-region'),
                            child: _panel(
                              slots.planningRegion,
                              graphitePlanningSafeInsets,
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
                    child: _panel(slots.insightRail, graphiteStatusSafeInsets),
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
              child: _panel(slots.centralContent, graphiteCalendarSafeInsets),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('mobile-placement-summary'),
              child: _panel(
                slots.mobilePlacementSummary,
                graphitePlacementsSafeInsets,
              ),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('mobile-attention'),
              child: _panel(slots.mobileAttention, graphiteStatusSafeInsets),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('planning-region'),
              child: _panel(slots.planningRegion, graphitePlanningSafeInsets),
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

  Widget _panel(Widget child, EdgeInsets safeInsets) => GraphiteNineSliceFrame(
    chromeInsets: safeInsets,
    contentPadding: const EdgeInsets.all(8),
    child: ClinicalCalendarPanelInterior(child: child),
  );
}

final class _GraphiteHeader extends StatelessWidget {
  const _GraphiteHeader({
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
