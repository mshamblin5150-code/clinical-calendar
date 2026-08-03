import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

final class ClinicalCalendarApp extends StatelessWidget {
  const ClinicalCalendarApp({
    required this.dependencies,
    required this.environmentName,
    super.key,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clinical Calendar',
    theme: buildVariantFTheme(),
    home: _FoundationScreen(
      dependencies: dependencies,
      environmentName: environmentName,
    ),
  );
}

final class _FoundationScreen extends StatelessWidget {
  const _FoundationScreen({
    required this.dependencies,
    required this.environmentName,
  });

  final ApplicationDependencies dependencies;
  final String environmentName;

  static const modules = <String>[
    'DOMAIN',
    'APPLICATION',
    'LOCAL DATA',
    'SYNCHRONIZATION',
    'PRESENTATION',
    'PLATFORM ADAPTERS',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 20 : 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(environmentName: environmentName),
                    const SizedBox(height: 28),
                    Text(
                      'PRODUCTION FOUNDATION',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Package boundaries and dependency ports are ready for '
                      'domain implementation. No prototype records are loaded.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: compact ? 1 : 2,
                      childAspectRatio: compact ? 4.4 : 4.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final module in modules)
                          _BoundaryCard(label: module),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CLOCK · ${dependencies.clock.runtimeType}\n'
                      'REPOSITORIES · ${dependencies.repositories.runtimeType}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: VariantFColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

final class _Header extends StatelessWidget {
  const _Header({required this.environmentName});

  final String environmentName;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: VariantFColors.border)),
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'CLINICAL CALENDAR',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Text(
            environmentName.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: VariantFColors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _BoundaryCard extends StatelessWidget {
  const _BoundaryCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: VariantFColors.surface,
      border: Border.all(color: VariantFColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: VariantFColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    ),
  );
}
