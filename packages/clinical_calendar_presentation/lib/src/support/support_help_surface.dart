import 'package:flutter/material.dart';

import '../responsive_shell.dart';
import '../theme_contract.dart';
import '../variant_f_theme.dart';

final class SupportHelpSurface extends StatelessWidget {
  const SupportHelpSurface({required this.themeGuide, super.key});

  final ThemeHelpGuide themeGuide;

  static const workflowSections = <({String title, String body})>[
    (
      title: 'Calendar states',
      body:
          'Month, Week, and Agenda show labeled Work Shifts, Clinical Sessions, '
          'Protected Days, and Today. Visual treatments reinforce the labels but '
          'never replace them.',
    ),
    (
      title: 'Batch scheduling',
      body:
          'Select one or more dates, choose a commitment or Protected Day, apply '
          'a Schedule Template or exact times, choose Clinical Placement and '
          'Preceptor defaults when needed, then resolve every conflict before '
          'the all-or-nothing batch is saved.',
    ),
    (
      title: 'Completion',
      body:
          'A past Clinical Session remains Awaiting Confirmation until you mark '
          'it Completed, Cancelled, or Missed. Completed Hours use the exact '
          'confirmed actual start and end times.',
    ),
    (
      title: 'Protected Days',
      body:
          'Choose one Protected Day for each configured calendar week. Work and '
          'clinical activity cannot touch it, including overnight activity.',
    ),
    (
      title: 'Progress',
      body:
          'Clinical Placement progress separates Completed, Scheduled, Remaining, '
          'Unscheduled, and Over-Target Hours. Total Progress combines every '
          'Clinical Placement without rounding stored minutes.',
    ),
    (
      title: 'Preceptors',
      body:
          'A Clinical Placement may use multiple Preceptors and has exactly one '
          'Primary Preceptor. Progress remains placement-wide with a '
          'per-Preceptor and Unattributed breakdown.',
    ),
    (
      title: 'Evaluation Plans',
      body:
          'Open Clinical Placements, select a placement, then choose Open Reviews '
          '& Evaluations. In Evaluation Plan configuration, set the Interim '
          'Review cadence using Completed Hours and switch the Initial '
          'Self-Assessment, Final Self-Assessment, and Final Placement Review '
          'between Required and Not required. Choose Preview Evaluation Plan '
          'changes to review the impact before saving. Each Interim threshold '
          'keeps the Student Reviews Primary Preceptor and Primary Preceptor '
          'Reviews Student as separate requirements. Documenting a requirement '
          'records evidence; it does not upload the evaluation.',
    ),
    (
      title: 'Attention and notifications',
      body:
          'Attention stays visible for unresolved confirmation, planning, '
          'evaluation, deadline, and synchronization states. Disabling a system '
          'notification never hides its unresolved in-app indicator.',
    ),
    (
      title: 'Settings, profile, storage, and synchronization',
      body:
          'Settings control week start, time display, theme, synchronization, '
          'notifications, and Schedule Templates. Student Profile initials come '
          'from the first two display-name parts; an optional image replaces '
          'them until removed. Encrypted SQLite on this device is the offline '
          'source of truth. Each local change and its synchronization intent are '
          'committed together and survive restart. A change is not Synced until '
          'a server acknowledges it; while the synchronization client is '
          'unavailable, delivery remains deferred and offline work stays queued. '
          'Never enter patient information.',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('support-help-surface'),
    padding: const EdgeInsets.all(16),
    children: [
      ShellPanel(
        label: 'Workflow Guide',
        accent: context.clinicalColors.clinical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final section in workflowSections) ...[
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(section.body),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      ShellPanel(
        label: themeGuide.title,
        accent: context.clinicalColors.scheduled,
        child: Column(
          children: [
            for (final state in themeGuide.calendarStates)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Semantics(
                    label: '${state.label} visual sample',
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: state.color,
                        border: Border.all(
                          color: context.clinicalColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                  title: Text(state.label),
                  subtitle: Text(state.description),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
