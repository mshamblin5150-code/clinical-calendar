import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

import 'responsive_shell.dart';
import 'theme_contract.dart';
import 'variant_f_theme.dart';

final class ClinicalCalendarApp extends StatelessWidget {
  const ClinicalCalendarApp({
    required this.dependencies,
    required this.environmentName,
    this.visualTheme = const VariantFVisualTheme(),
    this.helpGuides,
    super.key,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;
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
      themeId: visualTheme.id,
      helpGuides: helpGuides ?? ThemeHelpGuideRegistry.standard(),
    ),
  );
}

final class _ApplicationHost extends StatefulWidget {
  const _ApplicationHost({
    required this.dependencies,
    required this.environmentName,
    required this.themeId,
    required this.helpGuides,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;
  final String themeId;
  final ThemeHelpGuideRegistry helpGuides;

  @override
  State<_ApplicationHost> createState() => _ApplicationHostState();
}

final class _ApplicationHostState extends State<_ApplicationHost> {
  ClinicalCalendarDestination? _destination;
  DestinationEntry _entry = DestinationEntry.direct;

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
        child: _DestinationBody(
          destination: destination,
          themeGuide: widget.helpGuides.resolve(widget.themeId),
        ),
      );
    }

    return ResponsiveApplicationShell(
      environmentName: widget.environmentName,
      onOpenMenu: _showMenu,
      onOpenDestination: _openDirect,
      slots: ResponsiveShellSlots(
        placementDock: const _PlacementDock(),
        centralContent: _FoundationContent(dependencies: widget.dependencies),
        insightRail: const _InsightRail(),
        mobilePlacementSummary: const _MobilePlacementSummary(),
        planningRegion: const _PlanningRegion(),
      ),
    );
  }
}

final class _FoundationContent extends StatelessWidget {
  const _FoundationContent({required this.dependencies});

  final ApplicationDependencies dependencies;

  static const modules = <String>[
    'DOMAIN',
    'APPLICATION',
    'LOCAL DATA',
    'SYNCHRONIZATION',
    'PRESENTATION',
    'PLATFORM ADAPTERS',
  ];

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Production foundation',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Package boundaries and dependency ports are ready for domain '
          'implementation. No prototype records are loaded.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 520
                ? (constraints.maxWidth - 8) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final module in modules)
                  SizedBox(
                    width: cardWidth,
                    child: _BoundaryCard(label: module),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          'CLOCK · ${dependencies.clock.runtimeType}\n'
          'REPOSITORIES · ${dependencies.repositories.runtimeType}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: .5,
          ),
        ),
      ],
    ),
  );
}

final class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 44),
    decoration: BoxDecoration(
      color: context.clinicalColors.structureRaised,
      border: Border.all(color: context.clinicalColors.insetBorder),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: context.clinicalColors.clinical,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    ),
  );
}

final class _PlacementDock extends StatelessWidget {
  const _PlacementDock();

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Clinical Placement',
    accent: context.clinicalColors.clinical,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('No active Clinical Placement'),
        SizedBox(height: 8),
        Text('Placement controls arrive with the progress surfaces.'),
      ],
    ),
  );
}

final class _InsightRail extends StatelessWidget {
  const _InsightRail();

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Progress & attention',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TOTAL PROGRESS'),
        SizedBox(height: 8),
        Text('No progress data'),
        Divider(height: 24),
        Text('ATTENTION'),
        SizedBox(height: 8),
        Text('No items need attention'),
      ],
    ),
  );
}

final class _MobilePlacementSummary extends StatelessWidget {
  const _MobilePlacementSummary();

  @override
  Widget build(BuildContext context) => ShellPanel(
    label: 'Clinical Placement',
    child: const Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(value: 0),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text('No active Clinical Placement\nTotal Progress · 0%'),
        ),
      ],
    ),
  );
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

final class _DestinationBody extends StatelessWidget {
  const _DestinationBody({required this.destination, required this.themeGuide});

  final ClinicalCalendarDestination destination;
  final ThemeHelpGuide themeGuide;

  @override
  Widget build(BuildContext context) {
    if (destination == ClinicalCalendarDestination.help) {
      return _HelpBody(themeGuide: themeGuide);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ShellPanel(
        label: destination.label,
        child: Text(
          '${destination.label} workflows are supplied by their dedicated '
          'presentation ticket. This shell owns navigation only.',
        ),
      ),
    );
  }
}

final class _HelpBody extends StatelessWidget {
  const _HelpBody({required this.themeGuide});

  final ThemeHelpGuide themeGuide;

  static const sharedGuidance = <String>[
    'Batch scheduling',
    'Completion and Protected Days',
    'Progress and Preceptors',
    'Evaluation Plans and attention',
    'Settings and Student Profile',
    'Storage limitations',
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ShellPanel(
        label: 'Workflow guide',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final topic in sharedGuidance) Text('• $topic')],
        ),
      ),
      const SizedBox(height: 12),
      ShellPanel(
        label: themeGuide.title,
        child: Column(
          children: [
            for (final state in themeGuide.calendarStates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width: 20, height: 20, color: state.color),
                title: Text(state.label),
                subtitle: Text(state.description),
              ),
          ],
        ),
      ),
    ],
  );
}
