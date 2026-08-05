import 'package:flutter/material.dart';

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
                            child: slots.centralContent,
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
                    child: slots.centralContent,
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
    bottomNavigationBar: NavigationBar(
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
    body: SafeArea(child: child),
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
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _TacticalFramePainter(
      color: accent ?? context.clinicalColors.insetBorder,
      insetColor: context.clinicalColors.insetBorder,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.clinicalColors.structure,
        border: Border.all(
          color: accent ?? context.clinicalColors.insetBorder,
          width: context.clinicalMetrics.borderWidth,
        ),
        borderRadius: BorderRadius.circular(
          context.clinicalMetrics.cornerRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: VariantFColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        .withValues(alpha: .65),
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    ),
  );
}

final class _TacticalFramePainter extends CustomPainter {
  const _TacticalFramePainter({required this.color, required this.insetColor});

  final Color color;
  final Color insetColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 28 || size.height < 28) return;
    final insetPaint = Paint()
      ..color = insetColor.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(4.5, 4.5, size.width - 9, size.height - 9),
      insetPaint,
    );

    final cornerPaint = Paint()
      ..color = color.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const notch = 9.0;
    const run = 20.0;
    final path = Path()
      ..moveTo(0, notch)
      ..lineTo(notch, 0)
      ..lineTo(run, 0)
      ..moveTo(size.width - run, 0)
      ..lineTo(size.width - notch, 0)
      ..lineTo(size.width, notch)
      ..moveTo(size.width, size.height - notch)
      ..lineTo(size.width - notch, size.height)
      ..lineTo(size.width - run, size.height)
      ..moveTo(run, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height - notch);
    canvas.drawPath(path, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalFramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.insetColor != insetColor;
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
  Widget build(BuildContext context) => Container(
    key: const Key('compact-header'),
    constraints: const BoxConstraints(minHeight: 56),
    decoration: BoxDecoration(
      color: context.clinicalColors.structure,
      border: Border(
        bottom: BorderSide(color: context.clinicalColors.insetBorder),
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
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
  );
}
