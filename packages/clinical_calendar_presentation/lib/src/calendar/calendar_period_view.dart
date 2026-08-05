import 'dart:math' as math;

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../date_input.dart';
import '../variant_f_theme.dart';
import 'calendar_data_source.dart';
import 'calendar_models.dart';

final class CalendarPeriodView extends StatefulWidget {
  const CalendarPeriodView({
    required this.dataSource,
    required this.studentId,
    required this.today,
    this.initialAnchor,
    this.initialPeriod = CalendarPeriod.month,
    this.weekStartsOn = DateTime.sunday,
    this.initialSelectedDates = const <LocalDate>{},
    this.twelveHourTime = false,
    this.onSelectionChanged,
    this.onOpenItem,
    this.onPeriodChanged,
    super.key,
  }) : assert(
         weekStartsOn >= DateTime.monday && weekStartsOn <= DateTime.sunday,
         'weekStartsOn must be a valid weekday.',
       );

  final CalendarDataSource dataSource;
  final String studentId;
  final LocalDate today;
  final LocalDate? initialAnchor;
  final CalendarPeriod initialPeriod;
  final int weekStartsOn;
  final Set<LocalDate> initialSelectedDates;
  final bool twelveHourTime;
  final ValueChanged<Set<LocalDate>>? onSelectionChanged;
  final ValueChanged<CalendarItemReference>? onOpenItem;
  final void Function(CalendarPeriod period, LocalDate anchor)? onPeriodChanged;

  @override
  State<CalendarPeriodView> createState() => _CalendarPeriodViewState();
}

final class _CalendarPeriodViewState extends State<CalendarPeriodView> {
  late LocalDate _anchor;
  late CalendarPeriod _period;
  late Set<LocalDate> _selectedDates;
  late Future<CalendarSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _anchor = widget.initialAnchor ?? widget.today;
    _period = widget.initialPeriod;
    _selectedDates = {...widget.initialSelectedDates};
    _snapshot = _loadSnapshot();
  }

  @override
  void didUpdateWidget(CalendarPeriodView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource ||
        oldWidget.studentId != widget.studentId ||
        oldWidget.weekStartsOn != widget.weekStartsOn) {
      _snapshot = _loadSnapshot();
    }
    if (oldWidget.initialSelectedDates != widget.initialSelectedDates) {
      _selectedDates = {...widget.initialSelectedDates};
    }
  }

  Future<void> reload() async {
    setState(() => _snapshot = _loadSnapshot());
    await _snapshot;
  }

  void _changePeriod(CalendarPeriod period) {
    setState(() {
      _period = period;
      _snapshot = _loadSnapshot();
    });
    widget.onPeriodChanged?.call(_period, _anchor);
  }

  void _navigate(int direction) {
    setState(() {
      _anchor = switch (_period) {
        CalendarPeriod.week => _anchor.addDays(7 * direction),
        CalendarPeriod.month ||
        CalendarPeriod.agenda => _addMonths(_anchor, direction),
      };
      _snapshot = _loadSnapshot();
    });
    widget.onPeriodChanged?.call(_period, _anchor);
  }

  Future<CalendarSnapshot> _loadSnapshot() {
    final bounds = _periodBounds(_anchor, _period, widget.weekStartsOn);
    return widget.dataSource.load(
      studentId: widget.studentId,
      firstDate: bounds.first,
      lastDate: bounds.last,
    );
  }

  void _activateDate(
    LocalDate date,
    List<CalendarEntry> entries, {
    CalendarEntry? preferredEntry,
  }) {
    if (_selectedDates.remove(date)) {
      setState(() {});
      widget.onSelectionChanged?.call(Set.unmodifiable(_selectedDates));
      return;
    }
    final entry = preferredEntry ?? (entries.isEmpty ? null : entries.first);
    if (entry != null) {
      widget.onOpenItem?.call(
        CalendarItemReference(kind: entry.kind, id: entry.id, date: date),
      );
      return;
    }
    setState(() => _selectedDates.add(date));
    widget.onSelectionChanged?.call(Set.unmodifiable(_selectedDates));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CalendarSnapshot>(
    future: _snapshot,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _CalendarLoadFailure(onRetry: reload);
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          key: Key('calendar-loading'),
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final calendar = snapshot.requireData;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: context.clinicalColors.structure,
          border: Border.all(color: context.clinicalColors.insetBorder),
          borderRadius: BorderRadius.circular(
            context.clinicalMetrics.cornerRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarToolbar(
              period: _period,
              title: _periodTitle(_anchor, _period, widget.weekStartsOn),
              onPrevious: () => _navigate(-1),
              onNext: () => _navigate(1),
              onPeriod: _changePeriod,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                return switch (_period) {
                  CalendarPeriod.month => _MonthView(
                    anchor: _anchor,
                    today: widget.today,
                    snapshot: calendar,
                    selectedDates: _selectedDates,
                    weekStartsOn: widget.weekStartsOn,
                    compact: compact,
                    twelveHourTime: widget.twelveHourTime,
                    onActivate: _activateDate,
                  ),
                  CalendarPeriod.week => _WeekView(
                    anchor: _anchor,
                    today: widget.today,
                    snapshot: calendar,
                    selectedDates: _selectedDates,
                    weekStartsOn: widget.weekStartsOn,
                    compact: compact,
                    twelveHourTime: widget.twelveHourTime,
                    onActivate: _activateDate,
                  ),
                  CalendarPeriod.agenda => _AgendaView(
                    anchor: _anchor,
                    today: widget.today,
                    snapshot: calendar,
                    selectedDates: _selectedDates,
                    compact: compact,
                    twelveHourTime: widget.twelveHourTime,
                    onActivate: _activateDate,
                  ),
                };
              },
            ),
          ],
        ),
      );
    },
  );
}

typedef _ActivateDate =
    void Function(
      LocalDate date,
      List<CalendarEntry> entries, {
      CalendarEntry? preferredEntry,
    });

final class _CalendarToolbar extends StatelessWidget {
  const _CalendarToolbar({
    required this.period,
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriod,
  });

  final CalendarPeriod period;
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<CalendarPeriod> onPeriod;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final navigation = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('calendar-previous'),
              tooltip: 'Previous period',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              key: const Key('calendar-next'),
              tooltip: 'Next period',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        );
        final switcher = SegmentedButton<CalendarPeriod>(
          key: const Key('calendar-period-switcher'),
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: CalendarPeriod.month, label: Text('Month')),
            ButtonSegment(value: CalendarPeriod.week, label: Text('Week')),
            ButtonSegment(value: CalendarPeriod.agenda, label: Text('Agenda')),
          ],
          selected: {period},
          onSelectionChanged: (selection) => onPeriod(selection.single),
        );
        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('calendar-previous-compact'),
                    tooltip: 'Previous period',
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      key: const Key('calendar-period-title'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const Key('calendar-next-compact'),
                    tooltip: 'Next period',
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(child: switcher),
            ],
          );
        }
        return Row(
          children: [
            navigation,
            Expanded(
              child: Text(
                title,
                key: const Key('calendar-period-title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            switcher,
          ],
        );
      },
    ),
  );
}

final class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.anchor,
    required this.today,
    required this.snapshot,
    required this.selectedDates,
    required this.weekStartsOn,
    required this.compact,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate anchor;
  final LocalDate today;
  final CalendarSnapshot snapshot;
  final Set<LocalDate> selectedDates;
  final int weekStartsOn;
  final bool compact;
  final bool twelveHourTime;
  final _ActivateDate onActivate;

  @override
  Widget build(BuildContext context) {
    final dates = _monthDates(anchor, weekStartsOn);
    final weekdayLabels = _weekdayLabels(weekStartsOn, compact: compact);
    return Column(
      key: const Key('month-view'),
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dates.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: compact ? 58 : 112,
          ),
          itemBuilder: (context, index) {
            final date = dates[index];
            return _MonthDayCell(
              date: date,
              outside: date.month != anchor.month,
              today: date == today,
              selected: selectedDates.contains(date),
              entries: snapshot.entriesOn(date),
              compact: compact,
              twelveHourTime: twelveHourTime,
              onActivate: onActivate,
            );
          },
        ),
      ],
    );
  }
}

final class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.outside,
    required this.today,
    required this.selected,
    required this.entries,
    required this.compact,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate date;
  final bool outside;
  final bool today;
  final bool selected;
  final List<CalendarEntry> entries;
  final bool compact;
  final bool twelveHourTime;
  final _ActivateDate onActivate;

  @override
  Widget build(BuildContext context) {
    final protected = entries.any(
      (entry) => entry.kind == CalendarEntryKind.protectedDay,
    );
    final work = entries.any(
      (entry) => entry.kind == CalendarEntryKind.workShift,
    );
    final semanticLabel = _dateSemanticLabel(
      date,
      today: today,
      selected: selected,
      entries: entries,
      twelveHourTime: twelveHourTime,
    );
    return Semantics(
      key: Key('calendar-day-$date'),
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: () => onActivate(date, entries),
      child: CustomPaint(
        painter: _DayCellPainter(
          colors: context.clinicalColors,
          protected: protected,
          work: work,
          today: today,
          selected: selected,
          outside: outside,
        ),
        child: InkWell(
          onTap: () => onActivate(date, entries),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DayNumber(date: date, today: today, selected: selected),
                const SizedBox(height: 3),
                if (compact)
                  _CompactMarkers(entries: entries)
                else
                  Expanded(
                    child: ClipRect(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in entries.take(1))
                            _MonthEventCard(
                              entry: entry,
                              date: date,
                              twelveHourTime: twelveHourTime,
                              onTap: () => onActivate(
                                date,
                                entries,
                                preferredEntry: entry,
                              ),
                            ),
                          if (entries.length > 1)
                            Text(
                              '+${entries.length - 1} more',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.date,
    required this.today,
    required this.selected,
  });

  final LocalDate date;
  final bool today;
  final bool selected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: today ? const Color(0xFF321512) : Colors.transparent,
          border: today
              ? Border.all(color: context.clinicalColors.urgent)
              : null,
          shape: today ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: SizedBox(
          width: 23,
          height: 23,
          child: Center(
            child: Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: today ? const Color(0xFFFFD8D2) : null,
                fontWeight: today ? FontWeight.w700 : null,
              ),
            ),
          ),
        ),
      ),
      const Spacer(),
      if (selected)
        Icon(
          Icons.check_circle,
          size: 17,
          color: context.clinicalColors.clinical,
        ),
    ],
  );
}

final class _CompactMarkers extends StatelessWidget {
  const _CompactMarkers({required this.entries});

  final List<CalendarEntry> entries;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 3,
    runSpacing: 3,
    children: [
      for (final entry in entries.take(6))
        Container(
          key: Key('compact-${entry.kind.name}-${entry.id}'),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: _entryAccent(context, entry),
            shape: entry.kind == CalendarEntryKind.protectedDay
                ? BoxShape.rectangle
                : BoxShape.circle,
          ),
        ),
    ],
  );
}

final class _MonthEventCard extends StatelessWidget {
  const _MonthEventCard({
    required this.entry,
    required this.date,
    required this.twelveHourTime,
    required this.onTap,
  });

  final CalendarEntry entry;
  final LocalDate date;
  final bool twelveHourTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final continuation = entry.isContinuationOn(date);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        key: Key('month-entry-${entry.id}-$date'),
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: _entryDecoration(context, entry),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              continuation
                  ? '${entry.title} continues'
                  : entry.timeLabel(twelveHour: twelveHourTime),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
            Text(
              entry.assignment ?? entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.anchor,
    required this.today,
    required this.snapshot,
    required this.selectedDates,
    required this.weekStartsOn,
    required this.compact,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate anchor;
  final LocalDate today;
  final CalendarSnapshot snapshot;
  final Set<LocalDate> selectedDates;
  final int weekStartsOn;
  final bool compact;
  final bool twelveHourTime;
  final _ActivateDate onActivate;

  @override
  Widget build(BuildContext context) {
    final dates = _weekDates(anchor, weekStartsOn);
    final children = [
      for (final date in dates)
        _WeekDay(
          date: date,
          today: date == today,
          selected: selectedDates.contains(date),
          entries: snapshot.entriesOn(date),
          twelveHourTime: twelveHourTime,
          onActivate: onActivate,
        ),
    ];
    return Padding(
      key: const Key('week-view'),
      padding: const EdgeInsets.all(6),
      child: compact
          ? Column(children: children)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final child in children) Expanded(child: child)],
            ),
    );
  }
}

final class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.date,
    required this.today,
    required this.selected,
    required this.entries,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate date;
  final bool today;
  final bool selected;
  final List<CalendarEntry> entries;
  final bool twelveHourTime;
  final _ActivateDate onActivate;

  @override
  Widget build(BuildContext context) => Semantics(
    key: Key('week-day-$date'),
    button: true,
    selected: selected,
    label: _dateSemanticLabel(
      date,
      today: today,
      selected: selected,
      entries: entries,
      twelveHourTime: twelveHourTime,
    ),
    excludeSemantics: true,
    child: Container(
      margin: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: selected
            ? context.clinicalColors.structureRaised
            : context.clinicalColors.structure,
        border: Border.all(
          color: today
              ? context.clinicalColors.urgent
              : selected
              ? context.clinicalColors.clinical
              : context.clinicalColors.insetBorder,
          width: today ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onActivate(date, entries),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_weekdayName(date.asUtcCalendarDate.weekday)}, '
                '${_monthAbbreviation(date.month)} ${date.day}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: today ? context.clinicalColors.urgent : null,
                ),
              ),
              const SizedBox(height: 6),
              if (entries.isEmpty)
                Text('Open day', style: Theme.of(context).textTheme.bodySmall),
              for (final entry in entries)
                _PeriodEntryRow(
                  entry: entry,
                  date: date,
                  twelveHourTime: twelveHourTime,
                  onTap: () => onActivate(date, entries, preferredEntry: entry),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _AgendaView extends StatelessWidget {
  const _AgendaView({
    required this.anchor,
    required this.today,
    required this.snapshot,
    required this.selectedDates,
    required this.compact,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate anchor;
  final LocalDate today;
  final CalendarSnapshot snapshot;
  final Set<LocalDate> selectedDates;
  final bool compact;
  final bool twelveHourTime;
  final _ActivateDate onActivate;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime.utc(anchor.year, anchor.month + 1, 0).day;
    final rows = <({LocalDate date, CalendarEntry entry})>[
      for (var day = 1; day <= daysInMonth; day++)
        for (final entry in snapshot.entriesOn(
          LocalDate(anchor.year, anchor.month, day),
        ))
          if (entry.startDate == LocalDate(anchor.year, anchor.month, day) ||
              entry.endDate == LocalDate(anchor.year, anchor.month, day))
            (date: LocalDate(anchor.year, anchor.month, day), entry: entry),
    ];
    if (rows.isEmpty) {
      return const SizedBox(
        key: Key('agenda-view'),
        height: 160,
        child: Center(child: Text('No commitments in this month.')),
      );
    }
    return Column(
      key: const Key('agenda-view'),
      children: [
        for (final row in rows)
          _AgendaRow(
            date: row.date,
            entry: row.entry,
            today: row.date == today,
            selected: selectedDates.contains(row.date),
            compact: compact,
            twelveHourTime: twelveHourTime,
            onTap: () => onActivate(
              row.date,
              snapshot.entriesOn(row.date),
              preferredEntry: row.entry,
            ),
          ),
      ],
    );
  }
}

final class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.date,
    required this.entry,
    required this.today,
    required this.selected,
    required this.compact,
    required this.twelveHourTime,
    required this.onTap,
  });

  final LocalDate date;
  final CalendarEntry entry;
  final bool today;
  final bool selected;
  final bool compact;
  final bool twelveHourTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    key: Key('agenda-${entry.id}-$date'),
    button: true,
    selected: selected,
    label: _dateSemanticLabel(
      date,
      today: today,
      selected: selected,
      entries: [entry],
      twelveHourTime: twelveHourTime,
    ),
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      child: CustomPaint(
        painter: _AgendaBackgroundPainter(
          colors: context.clinicalColors,
          kind: entry.kind,
        ),
        child: Container(
          key: Key('agenda-row-${entry.kind.name}-${entry.id}-$date'),
          constraints: const BoxConstraints(minHeight: 58),
          decoration: _agendaDecoration(context, entry, selected: selected),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AgendaDateAndTime(
                      date: date,
                      entry: entry,
                      today: today,
                      twelveHourTime: twelveHourTime,
                    ),
                    const SizedBox(height: 4),
                    _AgendaAssignment(entry: entry),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        '${_weekdayName(date.asUtcCalendarDate.weekday)}, '
                        '${_monthAbbreviation(date.month)} ${date.day}',
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        entry.isContinuationOn(date)
                            ? 'Continues from prior day'
                            : entry.timeLabel(twelveHour: twelveHourTime),
                      ),
                    ),
                    Expanded(child: _AgendaAssignment(entry: entry)),
                  ],
                ),
        ),
      ),
    ),
  );
}

final class _AgendaDateAndTime extends StatelessWidget {
  const _AgendaDateAndTime({
    required this.date,
    required this.entry,
    required this.today,
    required this.twelveHourTime,
  });

  final LocalDate date;
  final CalendarEntry entry;
  final bool today;
  final bool twelveHourTime;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '${_weekdayName(date.asUtcCalendarDate.weekday)}, '
          '${_monthAbbreviation(date.month)} ${date.day}${today ? ' · Today' : ''}',
        ),
      ),
      const SizedBox(width: 8),
      Text(
        entry.isContinuationOn(date)
            ? 'Continues'
            : entry.timeLabel(twelveHour: twelveHourTime),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

final class _AgendaAssignment extends StatelessWidget {
  const _AgendaAssignment({required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        _entryIcon(entry.kind),
        size: 17,
        color: _entryAccent(context, entry),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          '${entry.title}${entry.assignment == null ? '' : ' · ${entry.assignment}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 6),
      Text(entry.statusLabel, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

final class _PeriodEntryRow extends StatelessWidget {
  const _PeriodEntryRow({
    required this.entry,
    required this.date,
    required this.twelveHourTime,
    required this.onTap,
  });

  final CalendarEntry entry;
  final LocalDate date;
  final bool twelveHourTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(7),
      decoration: _entryDecoration(context, entry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.isContinuationOn(date)
                ? 'Continues from ${formatUsDate(entry.startDate)}'
                : entry.timeLabel(twelveHour: twelveHourTime),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(entry.title, style: Theme.of(context).textTheme.labelLarge),
          if (entry.assignment != null)
            Text(
              entry.assignment!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(entry.statusLabel, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

final class _CalendarLoadFailure extends StatelessWidget {
  const _CalendarLoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('calendar-load-failure'),
    height: 240,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Calendar data could not be loaded.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

final class _DayCellPainter extends CustomPainter {
  const _DayCellPainter({
    required this.colors,
    required this.protected,
    required this.work,
    required this.today,
    required this.selected,
    required this.outside,
  });

  final ClinicalCalendarColors colors;
  final bool protected;
  final bool work;
  final bool today;
  final bool selected;
  final bool outside;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..color = outside
          ? colors.canvas.withValues(alpha: .62)
          : protected
          ? colors.protectedDay
          : work
          ? colors.work
          : colors.structure;
    canvas.drawRect(rect, background);
    if (protected) {
      final stripe = Paint()
        ..color = colors.protectedDayAccent.withValues(alpha: .16)
        ..strokeWidth = 2;
      for (double offset = -size.height; offset < size.width; offset += 10) {
        canvas.drawLine(
          Offset(offset, size.height),
          Offset(offset + size.height, 0),
          stripe,
        );
      }
    }
    if (work) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 3, size.height),
        Paint()..color = colors.workMachinery,
      );
    }
    canvas.drawRect(
      rect.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = today ? 2 : 1
        ..color = today ? colors.urgent : colors.insetBorder,
    );
    if (selected) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colors.clinical;
      final selectedRect = rect.deflate(3);
      const dash = 5.0;
      const gap = 3.0;
      for (
        double x = selectedRect.left;
        x < selectedRect.right;
        x += dash + gap
      ) {
        canvas.drawLine(
          Offset(x, selectedRect.top),
          Offset(math.min(x + dash, selectedRect.right), selectedRect.top),
          paint,
        );
        canvas.drawLine(
          Offset(x, selectedRect.bottom),
          Offset(math.min(x + dash, selectedRect.right), selectedRect.bottom),
          paint,
        );
      }
      for (
        double y = selectedRect.top;
        y < selectedRect.bottom;
        y += dash + gap
      ) {
        canvas.drawLine(
          Offset(selectedRect.left, y),
          Offset(selectedRect.left, math.min(y + dash, selectedRect.bottom)),
          paint,
        );
        canvas.drawLine(
          Offset(selectedRect.right, y),
          Offset(selectedRect.right, math.min(y + dash, selectedRect.bottom)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DayCellPainter oldDelegate) =>
      colors != oldDelegate.colors ||
      protected != oldDelegate.protected ||
      work != oldDelegate.work ||
      today != oldDelegate.today ||
      selected != oldDelegate.selected ||
      outside != oldDelegate.outside;
}

final class _AgendaBackgroundPainter extends CustomPainter {
  const _AgendaBackgroundPainter({required this.colors, required this.kind});

  final ClinicalCalendarColors colors;
  final CalendarEntryKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = switch (kind) {
      CalendarEntryKind.workShift => colors.work,
      CalendarEntryKind.clinicalSession => colors.structure,
      CalendarEntryKind.protectedDay => colors.protectedDay,
    };
    canvas.drawRect(rect, Paint()..color = background);
    final accent = switch (kind) {
      CalendarEntryKind.workShift => colors.workMachinery,
      CalendarEntryKind.clinicalSession => colors.clinical,
      CalendarEntryKind.protectedDay => colors.protectedDayAccent,
    };
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 3, size.height),
      Paint()..color = accent,
    );
    if (kind == CalendarEntryKind.protectedDay) {
      final stripe = Paint()
        ..color = colors.protectedDayAccent.withValues(alpha: .12)
        ..strokeWidth = 2;
      for (double offset = -size.height; offset < size.width; offset += 11) {
        canvas.drawLine(
          Offset(offset, size.height),
          Offset(offset + size.height, 0),
          stripe,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AgendaBackgroundPainter oldDelegate) =>
      colors != oldDelegate.colors || kind != oldDelegate.kind;
}

BoxDecoration _entryDecoration(BuildContext context, CalendarEntry entry) =>
    BoxDecoration(
      color: switch (entry.kind) {
        CalendarEntryKind.workShift => context.clinicalColors.work,
        CalendarEntryKind.clinicalSession =>
          entry.statusLabel == 'Completed'
              ? context.clinicalColors.clinical.withValues(alpha: .18)
              : context.clinicalColors.structureRaised,
        CalendarEntryKind.protectedDay => context.clinicalColors.protectedDay,
      },
      border: Border.all(color: _entryAccent(context, entry)),
      borderRadius: BorderRadius.circular(context.clinicalMetrics.cornerRadius),
    );

BoxDecoration _agendaDecoration(
  BuildContext context,
  CalendarEntry entry, {
  required bool selected,
}) => BoxDecoration(
  border: Border(
    left: BorderSide(color: _entryAccent(context, entry), width: 3),
    bottom: BorderSide(color: context.clinicalColors.insetBorder),
    top: selected
        ? BorderSide(color: context.clinicalColors.clinical)
        : BorderSide.none,
    right: selected
        ? BorderSide(color: context.clinicalColors.clinical)
        : BorderSide.none,
  ),
);

Color _entryAccent(BuildContext context, CalendarEntry entry) =>
    switch (entry.kind) {
      CalendarEntryKind.workShift => context.clinicalColors.workMachinery,
      CalendarEntryKind.clinicalSession =>
        entry.statusLabel == 'Awaiting Confirmation'
            ? context.clinicalColors.scheduled
            : context.clinicalColors.clinical,
      CalendarEntryKind.protectedDay =>
        context.clinicalColors.protectedDayAccent,
    };

IconData _entryIcon(CalendarEntryKind kind) => switch (kind) {
  CalendarEntryKind.workShift => Icons.work_outline,
  CalendarEntryKind.clinicalSession => Icons.medical_services_outlined,
  CalendarEntryKind.protectedDay => Icons.shield_outlined,
};

String _dateSemanticLabel(
  LocalDate date, {
  required bool today,
  required bool selected,
  required List<CalendarEntry> entries,
  required bool twelveHourTime,
}) {
  final parts = <String>[
    '${_weekdayName(date.asUtcCalendarDate.weekday)}, '
        '${_monthName(date.month)} ${date.day}, ${date.year}',
    if (today) 'Today',
    for (final entry in entries) ...[
      entry.title,
      if (entry.assignment != null) entry.assignment!,
      entry.isContinuationOn(date)
          ? 'continues from ${formatUsDate(entry.startDate)}'
          : entry.timeLabel(twelveHour: twelveHourTime),
      entry.statusLabel,
    ],
    if (selected)
      'Selected; tap to deselect'
    else if (entries.isNotEmpty)
      'Tap to open ${entries.first.title}'
    else
      'Tap to select',
  ];
  return parts.join(', ');
}

List<LocalDate> _monthDates(LocalDate anchor, int weekStartsOn) {
  final first = LocalDate(anchor.year, anchor.month, 1);
  final leading = (first.asUtcCalendarDate.weekday - weekStartsOn + 7) % 7;
  final start = first.addDays(-leading);
  return List.generate(42, start.addDays, growable: false);
}

List<LocalDate> _weekDates(LocalDate anchor, int weekStartsOn) {
  final leading = (anchor.asUtcCalendarDate.weekday - weekStartsOn + 7) % 7;
  final start = anchor.addDays(-leading);
  return List.generate(7, start.addDays, growable: false);
}

({LocalDate first, LocalDate last}) _periodBounds(
  LocalDate anchor,
  CalendarPeriod period,
  int weekStartsOn,
) => switch (period) {
  CalendarPeriod.month => (
    first: _monthDates(anchor, weekStartsOn).first,
    last: _monthDates(anchor, weekStartsOn).last,
  ),
  CalendarPeriod.week => (
    first: _weekDates(anchor, weekStartsOn).first,
    last: _weekDates(anchor, weekStartsOn).last,
  ),
  CalendarPeriod.agenda => (
    first: LocalDate(anchor.year, anchor.month, 1),
    last: LocalDate(
      anchor.year,
      anchor.month,
      DateTime.utc(anchor.year, anchor.month + 1, 0).day,
    ),
  ),
};

LocalDate _addMonths(LocalDate date, int delta) {
  final target = DateTime.utc(date.year, date.month + delta, 1);
  final lastDay = DateTime.utc(target.year, target.month + 1, 0).day;
  return LocalDate(target.year, target.month, math.min(date.day, lastDay));
}

String _periodTitle(LocalDate anchor, CalendarPeriod period, int weekStartsOn) {
  if (period != CalendarPeriod.week) {
    return '${_monthName(anchor.month)} ${anchor.year}';
  }
  final dates = _weekDates(anchor, weekStartsOn);
  final first = dates.first;
  final last = dates.last;
  if (first.month == last.month) {
    return '${_monthAbbreviation(first.month)} ${first.day}–${last.day}, '
        '${last.year}';
  }
  return '${_monthAbbreviation(first.month)} ${first.day} – '
      '${_monthAbbreviation(last.month)} ${last.day}, ${last.year}';
}

List<String> _weekdayLabels(int weekStartsOn, {required bool compact}) => [
  for (var offset = 0; offset < 7; offset++)
    compact
        ? _weekdayName(((weekStartsOn - 1 + offset) % 7) + 1).substring(0, 1)
        : _weekdayName(((weekStartsOn - 1 + offset) % 7) + 1),
];

String _weekdayName(int weekday) => const {
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
  DateTime.sunday: 'Sunday',
}[weekday]!;

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

String _monthAbbreviation(int month) => _monthName(month).substring(0, 3);
