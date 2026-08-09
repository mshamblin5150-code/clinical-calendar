import 'dart:math' as math;

import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import '../additive_semantic_colors.dart';
import '../date_input.dart';
import '../theme_contract.dart';
import '../variant_f_theme.dart';
import 'calendar_data_source.dart';
import 'calendar_models.dart';

/// Opt-in sizing policy for calendar hosts that intentionally constrain the
/// month grid to a bounded dashboard bay.
final class CalendarPeriodViewportPolicy extends InheritedWidget {
  const CalendarPeriodViewportPolicy({
    required this.useBoundedMonthGrid,
    this.scaleDayNumberWithText = false,
    this.useInstrumentChrome = false,
    required super.child,
    super.key,
  });

  final bool useBoundedMonthGrid;
  final bool scaleDayNumberWithText;
  final bool useInstrumentChrome;

  static bool usesBoundedMonthGrid(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarPeriodViewportPolicy>()
          ?.useBoundedMonthGrid ??
      false;

  static bool scalesDayNumberWithText(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarPeriodViewportPolicy>()
          ?.scaleDayNumberWithText ??
      false;

  static bool usesInstrumentChrome(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarPeriodViewportPolicy>()
          ?.useInstrumentChrome ??
      false;

  @override
  bool updateShouldNotify(CalendarPeriodViewportPolicy oldWidget) =>
      useBoundedMonthGrid != oldWidget.useBoundedMonthGrid ||
      scaleDayNumberWithText != oldWidget.scaleDayNumberWithText ||
      useInstrumentChrome != oldWidget.useInstrumentChrome;
}

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
      return LayoutBuilder(
        builder: (context, outerConstraints) {
          final useBoundedMonthGrid =
              CalendarPeriodViewportPolicy.usesBoundedMonthGrid(context);
          final periodView = LayoutBuilder(
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
                  useBoundedGrid: useBoundedMonthGrid,
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
          );
          return DecoratedBox(
            decoration: BoxDecoration(
              color: context.clinicalColors.structure,
              border: Border.all(color: context.clinicalColors.insetBorder),
              borderRadius: BorderRadius.circular(
                context.clinicalMetrics.cornerRadius,
              ),
            ),
            child:
                context.accessibilityTokens.persistentExpandedLegend &&
                    outerConstraints.hasBoundedHeight &&
                    outerConstraints.maxWidth < 600 &&
                    MediaQuery.textScalerOf(context).scale(1) > 1
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CalendarToolbar(
                          period: _period,
                          title: _periodTitle(
                            _anchor,
                            _period,
                            widget.weekStartsOn,
                          ),
                          onPrevious: () => _navigate(-1),
                          onNext: () => _navigate(1),
                          onPeriod: _changePeriod,
                        ),
                        const _EnhancedCalendarLegend(),
                        SizedBox(
                          height: math.max(
                            outerConstraints.maxHeight * .7,
                            420,
                          ),
                          child: periodView,
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CalendarToolbar(
                        period: _period,
                        title: _periodTitle(
                          _anchor,
                          _period,
                          widget.weekStartsOn,
                        ),
                        onPrevious: () => _navigate(-1),
                        onNext: () => _navigate(1),
                        onPeriod: _changePeriod,
                      ),
                      if (context.accessibilityTokens.persistentExpandedLegend)
                        const _EnhancedCalendarLegend(),
                      if (((_period == CalendarPeriod.week ||
                                  _period == CalendarPeriod.agenda) ||
                              useBoundedMonthGrid) &&
                          outerConstraints.hasBoundedHeight)
                        Expanded(child: periodView)
                      else
                        periodView,
                      if (_period == CalendarPeriod.month &&
                          CalendarPeriodViewportPolicy.usesInstrumentChrome(
                            context,
                          ))
                        const _InstrumentCalendarLegend(),
                    ],
                  ),
          );
        },
      );
    },
  );
}

final class _InstrumentCalendarLegend extends StatelessWidget {
  const _InstrumentCalendarLegend();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _InstrumentLegendItem(
            role: ThemeSemanticRole.clinicalSession,
            label: 'CLINICAL',
            color: context.clinicalColors.clinical,
          ),
          const SizedBox(width: 28),
          _InstrumentLegendItem(
            role: ThemeSemanticRole.workShift,
            label: 'WORK',
            color: context.clinicalColors.workMachinery,
          ),
          const SizedBox(width: 28),
          _InstrumentLegendItem(
            role: ThemeSemanticRole.protectedDay,
            label: 'PROTECTED',
            color: context.clinicalColors.protectedDayAccent,
          ),
        ],
      ),
    ),
  );
}

final class _InstrumentLegendItem extends StatelessWidget {
  const _InstrumentLegendItem({
    required this.role,
    required this.label,
    required this.color,
  });

  final ThemeSemanticRole role;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ThemeSemanticMarkIcon(role: role, size: 17, color: color),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          letterSpacing: .5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
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
    padding: CalendarPeriodViewportPolicy.usesInstrumentChrome(context)
        ? const EdgeInsets.fromLTRB(22, 8, 22, 8)
        : const EdgeInsets.fromLTRB(6, 6, 6, 8),
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
        if (CalendarPeriodViewportPolicy.usesInstrumentChrome(context)) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  key: const Key('calendar-period-title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
              SizedBox(width: 340, child: switcher),
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
    required this.useBoundedGrid,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate anchor;
  final LocalDate today;
  final CalendarSnapshot snapshot;
  final Set<LocalDate> selectedDates;
  final int weekStartsOn;
  final bool compact;
  final bool useBoundedGrid;
  final bool twelveHourTime;
  final _ActivateDate onActivate;

  @override
  Widget build(BuildContext context) {
    final dates = _monthDates(anchor, weekStartsOn);
    final weekdayLabels = _weekdayLabels(weekStartsOn, compact: compact);
    if (!useBoundedGrid) {
      return _buildMonthGrid(context, dates, weekdayLabels, null);
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
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
          _monthGrid(context, dates, constraints.maxHeight),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    List<LocalDate> dates,
    List<String> weekdayLabels,
    double? boundedHeight,
  ) => Column(
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
      _monthGrid(context, dates, boundedHeight),
    ],
  );

  Widget _monthGrid(
    BuildContext context,
    List<LocalDate> dates,
    double? boundedHeight,
  ) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: dates.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      mainAxisExtent: boundedHeight != null
          ? math.max(44, (boundedHeight - 32) / 6)
          : compact
          ? 58
          : 112,
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
        dense: boundedHeight != null && (boundedHeight - 32) / 6 < 88,
        twelveHourTime: twelveHourTime,
        onActivate: onActivate,
      );
    },
  );
}

final class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.outside,
    required this.today,
    required this.selected,
    required this.entries,
    required this.compact,
    required this.dense,
    required this.twelveHourTime,
    required this.onActivate,
  });

  final LocalDate date;
  final bool outside;
  final bool today;
  final bool selected;
  final List<CalendarEntry> entries;
  final bool compact;
  final bool dense;
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
    final instrumentChrome = CalendarPeriodViewportPolicy.usesInstrumentChrome(
      context,
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
          todayAccent: _todayAccent(context),
          protected: protected,
          work: work,
          today: today,
          selected: selected,
          outside: outside,
          selectionWidth: context.accessibilityTokens.selectionWidth,
          decorationOpacity: context.accessibilityTokens.decorationOpacity,
          instrumentChrome: instrumentChrome,
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
                else if (dense)
                  _DenseMonthMarker(
                    entries: entries,
                    instrumentChrome: instrumentChrome,
                  )
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

final class _DenseMonthMarker extends StatelessWidget {
  const _DenseMonthMarker({
    required this.entries,
    required this.instrumentChrome,
  });

  final List<CalendarEntry> entries;
  final bool instrumentChrome;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final entry = entries.first;
    final label = switch (entry.kind) {
      CalendarEntryKind.workShift => 'WORK',
      CalendarEntryKind.clinicalSession => 'CLINICAL',
      CalendarEntryKind.protectedDay => 'PROTECTED',
    };
    final additionalCount = entries.length - 1;
    final marker = Row(
      children: [
        Container(
          width: 3,
          height: instrumentChrome ? 19 : 16,
          color: _entryAccent(context, entry),
        ),
        const SizedBox(width: 4),
        if (_usesAdditiveMarks(context)) ...[
          ThemeSemanticMarkIcon(
            role: _entryRole(entry.kind),
            size: instrumentChrome ? 13 : 10,
            color: _entryAccent(context, entry),
          ),
          const SizedBox(width: 3),
        ] else if (instrumentChrome) ...[
          Icon(
            _variantEntryIcon(entry.kind),
            size: 13,
            color: _entryAccent(context, entry),
          ),
          const SizedBox(width: 3),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: instrumentChrome ? 10 : 9,
              color: _entryAccent(context, entry),
              letterSpacing: .4,
            ),
          ),
        ),
        if (additionalCount > 0)
          Text(
            '+$additionalCount',
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
    if (!instrumentChrome) return marker;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: context.clinicalColors.canvas.withValues(alpha: .72),
        border: Border.all(color: _entryAccent(context, entry)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: marker,
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
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final scalesDayNumber =
        CalendarPeriodViewportPolicy.scalesDayNumberWithText(context);
    final dayNumberWidth = scalesDayNumber
        ? 23.0 * textScale.clamp(1.0, 2.0)
        : 23.0;
    final dayNumberHeight = scalesDayNumber
        ? 23.0 + 8.0 * (textScale - 1).clamp(0.0, 1.0)
        : 23.0;
    final usesThemeTodayMark =
        _usesAdditiveMarks(context) || context.accessibilityTokens.enhanced;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: today ? _todayBackground(context) : Colors.transparent,
            border: today
                ? Border.all(
                    color: _todayAccent(context),
                    width: context.accessibilityTokens.selectionWidth,
                  )
                : null,
            shape: today && !scalesDayNumber
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: today && scalesDayNumber
                ? BorderRadius.circular(dayNumberHeight / 2)
                : null,
          ),
          child: SizedBox(
            width: dayNumberWidth,
            height: dayNumberHeight,
            child: Center(
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: today ? _todayForeground(context) : null,
                  fontWeight: today ? FontWeight.w700 : null,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: usesThemeTodayMark && today
                ? ThemeSemanticMarkIcon(
                    role: ThemeSemanticRole.today,
                    size: 15,
                    color: _todayAccent(context),
                  )
                : selected
                ? Icon(
                    Icons.check_circle,
                    size: 17,
                    color: context.clinicalColors.clinical,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

final class _CompactMarkers extends StatelessWidget {
  const _CompactMarkers({required this.entries});

  final List<CalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final usesAdditiveMarks = _usesAdditiveMarks(context);
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: [
        for (final entry in entries.take(6))
          if (usesAdditiveMarks)
            ThemeSemanticMarkIcon(
              key: Key('compact-${entry.kind.name}-${entry.id}'),
              role: _entryRole(entry.kind),
              size: 11,
              color: _entryAccent(context, entry),
            )
          else
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
            Row(
              children: [
                if (_usesAdditiveMarks(context)) ...[
                  ThemeSemanticMarkIcon(
                    role: _entryRole(entry.kind),
                    size: 11,
                    color: _entryAccent(context, entry),
                  ),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    entry.assignment ?? entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
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
          ? SingleChildScrollView(
              key: const Key('week-scroll'),
              child: Column(children: children),
            )
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
              ? _todayAccent(context)
              : selected
              ? context.clinicalColors.clinical
              : context.clinicalColors.insetBorder,
          width: today
              ? math.max(2, context.accessibilityTokens.selectionWidth)
              : selected
              ? context.accessibilityTokens.selectionWidth
              : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onActivate(date, entries),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (today &&
                      (_usesAdditiveMarks(context) ||
                          context.accessibilityTokens.enhanced)) ...[
                    ThemeSemanticMarkIcon(
                      role: ThemeSemanticRole.today,
                      size: 16,
                      color: _todayAccent(context),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      '${_weekdayName(date.asUtcCalendarDate.weekday)}, '
                      '${_monthAbbreviation(date.month)} ${date.day}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: today ? _todayAccent(context) : null,
                      ),
                    ),
                  ),
                ],
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
    return SingleChildScrollView(
      key: const Key('agenda-view'),
      child: rows.isEmpty
          ? const SizedBox(
              height: 160,
              child: Center(child: Text('No commitments in this month.')),
            )
          : Column(
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
            ),
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
          visuals: Theme.of(context).extension<ClinicalCalendarEntryVisuals>(),
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
      if (_usesAdditiveMarks(context))
        ThemeSemanticMarkIcon(
          role: _entryRole(entry.kind),
          size: 17,
          color: _entryAccent(context, entry),
        )
      else
        Icon(
          _variantEntryIcon(entry.kind),
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
      _CalendarStatusLabel(entry: entry),
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
          Row(
            children: [
              if (_usesAdditiveMarks(context)) ...[
                ThemeSemanticMarkIcon(
                  role: _entryRole(entry.kind),
                  size: 16,
                  color: _entryAccent(context, entry),
                ),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
          if (entry.assignment != null)
            Text(
              entry.assignment!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          _CalendarStatusLabel(entry: entry),
        ],
      ),
    ),
  );
}

final class _EnhancedCalendarLegend extends StatelessWidget {
  const _EnhancedCalendarLegend();

  static const _items = <_EnhancedLegendItem>[
    _EnhancedLegendItem(ThemeSemanticRole.clinicalSession, 'Clinical Session'),
    _EnhancedLegendItem(ThemeSemanticRole.workShift, 'Work Shift'),
    _EnhancedLegendItem(ThemeSemanticRole.protectedDay, 'Protected Day'),
    _EnhancedLegendItem(ThemeSemanticRole.today, 'Today'),
    _EnhancedLegendItem(ThemeSemanticRole.urgent, 'Urgent'),
    _EnhancedLegendItem(ThemeSemanticRole.scheduledProgress, 'Scheduled'),
    _EnhancedLegendItem(ThemeSemanticRole.completedSession, 'Completed'),
    _EnhancedLegendItem(ThemeSemanticRole.cancelledSession, 'Cancelled'),
    _EnhancedLegendItem(ThemeSemanticRole.missedSession, 'Missed'),
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    key: const Key('enhanced-calendar-legend'),
    container: true,
    label:
        'Enhanced accessibility legend. ${_items.map((item) => item.label).join(', ')}.',
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth < 600
                ? constraints.maxWidth
                : 210.0;
            return Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final item in _items)
                  SizedBox(
                    width: itemWidth,
                    child: Row(
                      children: [
                        ThemeSemanticMarkIcon(role: item.role, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

final class _EnhancedLegendItem {
  const _EnhancedLegendItem(this.role, this.label);

  final ThemeSemanticRole role;
  final String label;
}

final class _CalendarStatusLabel extends StatelessWidget {
  const _CalendarStatusLabel({required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    final role = _statusRole(entry.statusLabel);
    if (!context.accessibilityTokens.enhanced || role == null) {
      return Text(
        entry.statusLabel,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ThemeSemanticMarkIcon(role: role, size: 15),
        const SizedBox(width: 4),
        Text(entry.statusLabel, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

ThemeSemanticRole? _statusRole(String statusLabel) => switch (statusLabel) {
  'Scheduled' || 'Awaiting Confirmation' => ThemeSemanticRole.scheduledProgress,
  'Completed' => ThemeSemanticRole.completedSession,
  'Cancelled' => ThemeSemanticRole.cancelledSession,
  'Missed' => ThemeSemanticRole.missedSession,
  _ => null,
};

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
    required this.todayAccent,
    required this.protected,
    required this.work,
    required this.today,
    required this.selected,
    required this.outside,
    required this.selectionWidth,
    required this.decorationOpacity,
    required this.instrumentChrome,
  });

  final ClinicalCalendarColors colors;
  final Color todayAccent;
  final bool protected;
  final bool work;
  final bool today;
  final bool selected;
  final bool outside;
  final double selectionWidth;
  final double decorationOpacity;
  final bool instrumentChrome;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..color = outside
          ? colors.canvas.withValues(alpha: .62)
          : !instrumentChrome && protected
          ? colors.protectedDay
          : !instrumentChrome && work
          ? colors.work
          : colors.structure;
    canvas.drawRect(rect, background);
    if (protected && !instrumentChrome) {
      final stripe = Paint()
        ..color = colors.protectedDayAccent.withValues(
          alpha: .16 * decorationOpacity,
        )
        ..strokeWidth = 2;
      for (double offset = -size.height; offset < size.width; offset += 10) {
        canvas.drawLine(
          Offset(offset, size.height),
          Offset(offset + size.height, 0),
          stripe,
        );
      }
    }
    if (work && !instrumentChrome) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 3, size.height),
        Paint()..color = colors.workMachinery,
      );
    }
    canvas.drawRect(
      rect.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = today ? math.max(2, selectionWidth) : 1
        ..color = today ? todayAccent : colors.insetBorder,
    );
    if (selected) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selectionWidth
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
      todayAccent != oldDelegate.todayAccent ||
      protected != oldDelegate.protected ||
      work != oldDelegate.work ||
      today != oldDelegate.today ||
      selected != oldDelegate.selected ||
      outside != oldDelegate.outside ||
      selectionWidth != oldDelegate.selectionWidth ||
      decorationOpacity != oldDelegate.decorationOpacity ||
      instrumentChrome != oldDelegate.instrumentChrome;
}

final class _AgendaBackgroundPainter extends CustomPainter {
  const _AgendaBackgroundPainter({
    required this.colors,
    required this.visuals,
    required this.kind,
  });

  final ClinicalCalendarColors colors;
  final ClinicalCalendarEntryVisuals? visuals;
  final CalendarEntryKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = switch (kind) {
      CalendarEntryKind.workShift => colors.work,
      CalendarEntryKind.clinicalSession =>
        visuals?.clinicalFill ?? colors.structure,
      CalendarEntryKind.protectedDay => colors.protectedDay,
    };
    canvas.drawRect(rect, Paint()..color = background);
    final accent = switch (kind) {
      CalendarEntryKind.workShift => colors.workMachinery,
      CalendarEntryKind.clinicalSession => colors.clinical,
      CalendarEntryKind.protectedDay => colors.protectedDayAccent,
    };
    final entryVisuals = visuals;
    if (entryVisuals == null) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, 3, size.height),
        Paint()..color = accent,
      );
    } else if (kind == CalendarEntryKind.workShift &&
        entryVisuals.segmentWorkRail) {
      final segmentHeight = (size.height - 12) / 2;
      final railPaint = Paint()..color = accent;
      canvas.drawRect(
        Rect.fromLTWH(0, 4, entryVisuals.leadingRailWidth, segmentHeight),
        railPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          8 + segmentHeight,
          entryVisuals.leadingRailWidth,
          segmentHeight,
        ),
        railPaint,
      );
    } else if (kind == CalendarEntryKind.protectedDay &&
        entryVisuals.protectedDotGridCorner) {
      canvas.drawRect(
        rect.deflate(1),
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final dotPaint = Paint()..color = accent;
      for (var row = 0; row < 3; row++) {
        for (var column = 0; column < 3; column++) {
          canvas.drawCircle(
            Offset(size.width - 14 + column * 4, 6 + row * 4),
            1,
            dotPaint,
          );
        }
      }
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, entryVisuals.leadingRailWidth, size.height),
        Paint()..color = accent,
      );
    }
    if (entryVisuals == null && kind == CalendarEntryKind.protectedDay) {
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
      colors != oldDelegate.colors ||
      visuals != oldDelegate.visuals ||
      kind != oldDelegate.kind;
}

BoxDecoration _entryDecoration(BuildContext context, CalendarEntry entry) =>
    BoxDecoration(
      color: switch (entry.kind) {
        CalendarEntryKind.workShift => context.clinicalColors.work,
        CalendarEntryKind.clinicalSession =>
          entry.statusLabel == 'Completed'
              ? context.clinicalColors.clinical.withValues(alpha: .18)
              : Theme.of(
                      context,
                    ).extension<ClinicalCalendarEntryVisuals>()?.clinicalFill ??
                    context.clinicalColors.structureRaised,
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
    left: Theme.of(context).extension<ClinicalCalendarEntryVisuals>() == null
        ? BorderSide(color: _entryAccent(context, entry), width: 3)
        : BorderSide.none,
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

ThemeSemanticRole _entryRole(CalendarEntryKind kind) => switch (kind) {
  CalendarEntryKind.workShift => ThemeSemanticRole.workShift,
  CalendarEntryKind.clinicalSession => ThemeSemanticRole.clinicalSession,
  CalendarEntryKind.protectedDay => ThemeSemanticRole.protectedDay,
};

IconData _variantEntryIcon(CalendarEntryKind kind) => switch (kind) {
  CalendarEntryKind.workShift => Icons.work_outline,
  CalendarEntryKind.clinicalSession => Icons.medical_services_outlined,
  CalendarEntryKind.protectedDay => Icons.shield_outlined,
};

bool _usesAdditiveMarks(BuildContext context) {
  final themeId = ClinicalCalendarSemanticMarkScope.maybeOf(context)?.themeId;
  return themeId != null && themeId != variantFThemeId;
}

Color _todayAccent(BuildContext context) {
  final additive = Theme.of(
    context,
  ).extension<ClinicalCalendarAdditiveColors>();
  if (additive != null) return additive.today;
  if (context.accessibilityTokens.enhanced) {
    return context.accessibilityTokens.focusOuterColor;
  }
  return _usesAdditiveMarks(context)
      ? Theme.of(context).colorScheme.primary
      : context.clinicalColors.urgent;
}

Color _todayBackground(BuildContext context) => _usesAdditiveMarks(context)
    ? Theme.of(context).colorScheme.primaryContainer
    : const Color(0xFF321512);

Color _todayForeground(BuildContext context) => _usesAdditiveMarks(context)
    ? Theme.of(context).colorScheme.onPrimaryContainer
    : const Color(0xFFFFD8D2);

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
