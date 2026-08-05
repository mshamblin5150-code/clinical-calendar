import 'package:flutter/material.dart';

import 'tactical_frame.dart';
import 'variant_f_theme.dart';

enum ClinicalCalendarDestination {
  calendar('Calendar', Icons.calendar_month_outlined),
  planning('Planning', Icons.add_box_outlined),
  clinicalPlacements('Clinical Placements', Icons.track_changes_outlined),
  studentProfile('Student Profile', Icons.person_outline),
  connectedDevices('Connected Devices', Icons.devices_other_outlined),
  trashRecovery('Trash & Recovery', Icons.restore_from_trash_outlined),
  backupRestore('Backup & Restore', Icons.backup_outlined),
  exports('Exports', Icons.ios_share_outlined),
  synchronization('Synchronization', Icons.sync_outlined),
  settings('Settings', Icons.settings_outlined),
  notifications('Notifications', Icons.notifications_outlined),
  help('Help', Icons.help_outline);

  const ClinicalCalendarDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

const applicationMenuDestinations = <ClinicalCalendarDestination>[
  ClinicalCalendarDestination.clinicalPlacements,
  ClinicalCalendarDestination.studentProfile,
  ClinicalCalendarDestination.connectedDevices,
  ClinicalCalendarDestination.trashRecovery,
  ClinicalCalendarDestination.backupRestore,
  ClinicalCalendarDestination.exports,
  ClinicalCalendarDestination.synchronization,
  ClinicalCalendarDestination.settings,
  ClinicalCalendarDestination.notifications,
  ClinicalCalendarDestination.help,
];

enum DestinationEntry { applicationMenu, direct }

@immutable
final class ResponsiveShellSlots {
  const ResponsiveShellSlots({
    required this.centralContent,
    required this.planningRegion,
    required this.placementDock,
    required this.insightRail,
    required this.mobilePlacementSummary,
    required this.mobileAttention,
    required this.profileAvatar,
  });

  final Widget centralContent;
  final Widget planningRegion;
  final Widget placementDock;
  final Widget insightRail;
  final Widget mobilePlacementSummary;
  final Widget mobileAttention;
  final Widget profileAvatar;
}

/// Responsive composition only. It has no scheduling or progress rules.
final class ResponsiveApplicationShell extends StatelessWidget {
  const ResponsiveApplicationShell({
    required this.slots,
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenDestination,
    required this.onAddSchedule,
    this.mobileIndex = 1,
    super.key,
  });

  static const desktopMinimumWidth = 960.0;
  static const desktopMinimumHeight = 600.0;

  final ResponsiveShellSlots slots;
  final String environmentName;
  final VoidCallback onOpenMenu;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onAddSchedule;
  final int mobileIndex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop =
          constraints.maxWidth >= desktopMinimumWidth &&
          constraints.maxHeight >= desktopMinimumHeight &&
          constraints.maxWidth > constraints.maxHeight;
      return desktop ? _desktop(context) : _mobile(context);
    },
  );

  Widget _desktop(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          _CommandBar(
            environmentName: environmentName,
            onOpenMenu: onOpenMenu,
            onOpenHelp: () =>
                onOpenDestination(ClinicalCalendarDestination.help),
            onAddSchedule: onAddSchedule,
            onOpenNotifications: () =>
                onOpenDestination(ClinicalCalendarDestination.notifications),
            onOpenSynchronization: () =>
                onOpenDestination(ClinicalCalendarDestination.synchronization),
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
                    child: slots.placementDock,
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
                            child: VariantFTacticalFrame(
                              padding: const EdgeInsets.all(7),
                              chamfer: 14,
                              statusLight: true,
                              child: slots.centralContent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          KeyedSubtree(
                            key: const Key('planning-region'),
                            child: slots.planningRegion,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const Key('insight-rail'),
                    width: 232,
                    child: slots.insightRail,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _mobile(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _CompactHeader(
            onOpenMenu: onOpenMenu,
            onAddSchedule: onAddSchedule,
            profileAvatar: slots.profileAvatar,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('mobile-content-scroll'),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(
                    key: const Key('central-content'),
                    child: VariantFTacticalFrame(
                      padding: const EdgeInsets.all(7),
                      chamfer: 14,
                      statusLight: true,
                      child: slots.centralContent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final placement = KeyedSubtree(
                        key: const Key('mobile-placement-summary'),
                        child: slots.mobilePlacementSummary,
                      );
                      final attention = KeyedSubtree(
                        key: const Key('mobile-attention'),
                        child: slots.mobileAttention,
                      );
                      if (constraints.maxWidth >= 720) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: placement),
                            const SizedBox(width: 12),
                            Expanded(child: attention),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          placement,
                          const SizedBox(height: 12),
                          attention,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: const Key('planning-region'),
                    child: slots.planningRegion,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: VariantFTacticalFrame(
      key: const Key('bottom-navigation-frame'),
      padding: EdgeInsets.zero,
      chamfer: 10,
      recessed: false,
      child: NavigationBar(
        key: const Key('bottom-navigation'),
        selectedIndex: mobileIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              onOpenDestination(ClinicalCalendarDestination.calendar);
              return;
            case 1:
              onOpenDestination(ClinicalCalendarDestination.calendar);
              return;
            case 2:
              onOpenDestination(ClinicalCalendarDestination.clinicalPlacements);
              return;
            case 3:
              onOpenDestination(ClinicalCalendarDestination.notifications);
              return;
            case 4:
              onOpenDestination(ClinicalCalendarDestination.settings);
              return;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            label: 'Today',
          ),
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
    ),
  );
}

final class ApplicationMenu extends StatelessWidget {
  const ApplicationMenu({required this.onSelected, super.key});

  final ValueChanged<ClinicalCalendarDestination> onSelected;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('application-menu'),
    padding: const EdgeInsets.all(12),
    shrinkWrap: true,
    children: [
      Text('APPLICATION MENU', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final destination in applicationMenuDestinations)
        ListTile(
          minTileHeight: context.clinicalMetrics.minimumTouchTarget,
          leading: Icon(destination.icon),
          title: Text(destination.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelected(destination),
        ),
    ],
  );
}

final class DestinationSurface extends StatelessWidget {
  const DestinationSurface({
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: context.clinicalColors.structure,
      leadingWidth: entry == DestinationEntry.applicationMenu ? 88 : 96,
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
        child: VariantFTacticalFrame(
          padding: const EdgeInsets.all(8),
          chamfer: 14,
          statusLight: true,
          child: child,
        ),
      ),
    ),
  );
}

final class ShellPanel extends StatelessWidget {
  const ShellPanel({
    required this.label,
    required this.child,
    this.accent,
    super.key,
  });

  final String label;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) => VariantFTacticalFrame(
    accent: accent,
    chamfer: 13,
    statusLight: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Divider(
                color: (accent ?? context.clinicalColors.insetBorder)
                    .withValues(alpha: .75),
                height: 1,
                thickness: 1,
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

final class _CommandBar extends StatelessWidget {
  const _CommandBar({
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenHelp,
    required this.onAddSchedule,
    required this.onOpenNotifications,
    required this.onOpenSynchronization,
    required this.profileAvatar,
  });

  final String environmentName;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenHelp;
  final VoidCallback onAddSchedule;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSynchronization;
  final Widget profileAvatar;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('command-bar'),
    height: 64,
    decoration: BoxDecoration(
      color: context.clinicalColors.structure,
      border: Border(
        bottom: BorderSide(color: context.clinicalColors.insetBorder),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        IconButton(
          key: const Key('desktop-menu-action'),
          tooltip: 'Application menu',
          onPressed: onOpenMenu,
          icon: const Icon(Icons.menu),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Clinical Calendar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        FilledButton.icon(
          key: const Key('command-add-schedule'),
          onPressed: onAddSchedule,
          icon: const Icon(Icons.add),
          label: const Text('Add schedule'),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('command-notifications'),
          tooltip: 'Needs attention',
          onPressed: onOpenNotifications,
          icon: const Icon(Icons.notifications_outlined),
        ),
        TextButton.icon(
          key: const Key('command-sync-status'),
          onPressed: onOpenSynchronization,
          icon: const Icon(Icons.sync_outlined),
          label: const Text('Sync status'),
        ),
        Text(
          environmentName.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('desktop-help-action'),
          tooltip: 'Help',
          onPressed: onOpenHelp,
          icon: const Icon(Icons.help_outline),
        ),
        profileAvatar,
      ],
    ),
  );
}

final class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.onOpenMenu,
    required this.onAddSchedule,
    required this.profileAvatar,
  });

  final VoidCallback onOpenMenu;
  final VoidCallback onAddSchedule;
  final Widget profileAvatar;

  @override
  Widget build(BuildContext context) => VariantFTacticalFrame(
    key: const Key('compact-header'),
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 7),
    chamfer: 11,
    recessed: false,
    statusLight: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('mobile-menu-action'),
              tooltip: 'Application menu',
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Clinical Calendar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('compact-add-schedule'),
              tooltip: 'Add schedule',
              onPressed: onAddSchedule,
              icon: const Icon(Icons.add),
            ),
            profileAvatar,
          ],
        ),
        const SizedBox(height: 2),
        const _CompactStatusRail(),
      ],
    ),
  );
}

final class _CompactStatusRail extends StatelessWidget {
  const _CompactStatusRail();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Operational status rail',
    child: SizedBox(
      height: 34,
      child: Row(
        children: const [
          _StatusRailCell(
            icon: Icons.warning_amber_rounded,
            color: VariantFColors.urgent,
          ),
          _StatusRailCell(
            icon: Icons.schedule_outlined,
            color: VariantFColors.muted,
          ),
          _StatusRailCell(
            icon: Icons.description_outlined,
            color: VariantFColors.muted,
          ),
          _StatusRailCell(
            icon: Icons.check_circle_outline,
            color: VariantFColors.primary,
          ),
        ],
      ),
    ),
  );
}

final class _StatusRailCell extends StatelessWidget {
  const _StatusRailCell({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: VariantFColors.control,
        border: Border.all(color: context.clinicalColors.insetBorder),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    ),
  );
}
