import 'dart:async';

import 'package:flutter/material.dart';

import 'data/encrypted_schedule_store.dart';
import 'data/session_repository.dart';
import 'domain/scheduling.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await EncryptedScheduleStore.open();
    runApp(ClinicalCalendarSlice(repository: store, store: store));
  } catch (error, stackTrace) {
    runApp(BootstrapFailure(error: error, stackTrace: stackTrace));
  }
}

class ClinicalCalendarSlice extends StatelessWidget {
  const ClinicalCalendarSlice({
    super.key,
    required this.repository,
    this.store,
  });

  final SessionRepository repository;
  final EncryptedScheduleStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinical Calendar — Vertical Slice',
      debugShowCheckedModeBanner: false,
      theme: _variantFTheme(),
      home: WeekSlicePage(repository: repository, store: store),
    );
  }
}

class BootstrapFailure extends StatelessWidget {
  const BootstrapFailure({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _variantFTheme(),
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Encrypted storage could not start.\n\n$error\n\n$stackTrace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WeekSlicePage extends StatefulWidget {
  const WeekSlicePage({super.key, required this.repository, this.store});

  final SessionRepository repository;
  final EncryptedScheduleStore? store;

  @override
  State<WeekSlicePage> createState() => _WeekSlicePageState();
}

class _WeekSlicePageState extends State<WeekSlicePage> {
  static final _weekStart = DateTime(2026, 8, 3);
  static final _protectedDay = DateTime(2026, 8, 6);
  static const _validator = ScheduleValidator();

  List<ScheduleCommitment> _sessions = const [];
  bool _loading = true;
  String _message = 'Loading encrypted local schedule…';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final sessions = await widget.repository.loadAll();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
      _message = sessions.isEmpty
          ? 'Offline store ready. Add the first Clinical Session.'
          : '${sessions.length} Clinical Session(s) restored from encrypted SQLite.';
    });
  }

  Future<void> _attemptSession(DateTime date) async {
    final candidate = ScheduleCommitment(
      id: 'session-${DateTime.now().microsecondsSinceEpoch}',
      date: date,
      startMinutes: 7 * 60,
      endMinutes: 19 * 60,
      timeZone: 'America/New_York',
    );
    final validation = _validator.validate(
      candidate: candidate,
      existing: _sessions,
      protectedDays: {_protectedDay},
    );
    if (!validation.isValid) {
      final reason = validation.rejections
          .map(
            (rejection) => switch (rejection) {
              ScheduleRejection.overlap => 'Schedule Conflict',
              ScheduleRejection.protectedDay => 'Protected Day',
            },
          )
          .join(' and ');
      setState(() => _message = 'Rejected: $reason. No local data changed.');
      return;
    }

    await widget.repository.save(candidate);
    final sessions = await widget.repository.loadAll();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _message = 'Saved locally. Restart offline to verify persistence.';
    });
  }

  @override
  void dispose() {
    unawaited(widget.repository.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CLINICAL CALENDAR'),
            Text('FLUTTER VERTICAL SLICE', style: TextStyle(fontSize: 11)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: _StatusChip()),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 800;
            final calendar = _WeekPanel(
              sessions: _sessions,
              protectedDay: _protectedDay,
            );
            final evidence = _EvidencePanel(
              loading: _loading,
              message: _message,
              sessionCount: _sessions.length,
              store: widget.store,
              onValid: () => _attemptSession(DateTime(2026, 8, 4)),
              onConflict: () => _attemptSession(DateTime(2026, 8, 4)),
              onProtected: () => _attemptSession(_protectedDay),
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calendar,
                            const SizedBox(height: 16),
                            evidence,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: calendar),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: evidence),
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
}

class _WeekPanel extends StatelessWidget {
  const _WeekPanel({required this.sessions, required this.protectedDay});

  final List<ScheduleCommitment> sessions;
  final DateTime protectedDay;

  @override
  Widget build(BuildContext context) {
    return _TacticalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('WEEK OF AUGUST 3, 2026', style: _sectionStyle),
          const SizedBox(height: 12),
          ...List.generate(7, (index) {
            final day = _WeekSlicePageState._weekStart.add(
              Duration(days: index),
            );
            final daySessions = sessions.where(
              (item) => _sameDay(item.date, day),
            );
            final protected = _sameDay(day, protectedDay);
            return _DayRow(
              day: day,
              protected: protected,
              sessions: daySessions.toList(growable: false),
            );
          }),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.protected,
    required this.sessions,
  });

  final DateTime day;
  final bool protected;
  final List<ScheduleCommitment> sessions;

  @override
  Widget build(BuildContext context) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final background = protected
        ? const Color(0xff252a27)
        : sessions.isNotEmpty
        ? const Color(0xff1c2c1b)
        : const Color(0xff0b100d);
    return Semantics(
      label:
          '${names[day.weekday - 1]}, August ${day.day}'
          '${protected ? ', Protected Day' : ''}'
          '${sessions.isNotEmpty ? ', Clinical Session' : ''}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: protected
                ? const Color(0xffa5aaa4)
                : sessions.isNotEmpty
                ? const Color(0xff7eaa50)
                : const Color(0xff343b35),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                '${names[day.weekday - 1]}  ${day.day}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: protected
                  ? const Text('PROTECTED DAY · REST AND PREPARATION')
                  : sessions.isEmpty
                  ? const Text(
                      'AVAILABLE',
                      style: TextStyle(color: Color(0xff7c817a)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sessions
                          .map(
                            (session) => Text(
                              '${formatMinutes(session.startMinutes)}–'
                              '${formatMinutes(session.endMinutes)} · '
                              '${session.durationMinutes ~/ 60} hr · Clinical Session',
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidencePanel extends StatelessWidget {
  const _EvidencePanel({
    required this.loading,
    required this.message,
    required this.sessionCount,
    required this.store,
    required this.onValid,
    required this.onConflict,
    required this.onProtected,
  });

  final bool loading;
  final String message;
  final int sessionCount;
  final EncryptedScheduleStore? store;
  final VoidCallback onValid;
  final VoidCallback onConflict;
  final VoidCallback onProtected;

  @override
  Widget build(BuildContext context) {
    return _TacticalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('VERTICAL-SLICE EVIDENCE', style: _sectionStyle),
          const SizedBox(height: 14),
          _EvidenceRow(label: 'Responsive Flutter', value: 'ACTIVE'),
          _EvidenceRow(
            label: 'SQLCipher',
            value: store?.cipherVersion ?? 'TEST REPOSITORY',
          ),
          _EvidenceRow(label: 'Persisted Sessions', value: '$sessionCount'),
          const _EvidenceRow(
            label: 'Local time zone',
            value: 'America/New_York',
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('status-message'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff101712),
              border: Border.all(color: const Color(0xff4b594b)),
            ),
            child: Text(loading ? 'Loading…' : message),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: loading ? null : onValid,
            child: const Text('SAVE TUE 07:00–19:00'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: loading ? null : onConflict,
            child: const Text('TRY SAME-TIME CONFLICT'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: loading ? null : onProtected,
            child: const Text('TRY THU PROTECTED DAY'),
          ),
          const SizedBox(height: 12),
          const Text(
            'The first action persists. Repeating it must be rejected as a '
            'Schedule Conflict. Thursday must be rejected as a Protected Day.',
            style: TextStyle(color: Color(0xffa3a79e), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xffa3a79e)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xff99c665),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalPanel extends StatelessWidget {
  const _TacticalPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff0d120f),
        border: Border.all(color: const Color(0xff475047)),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.offline_bolt_outlined, color: Color(0xff99c665), size: 18),
        SizedBox(width: 6),
        Text('LOCAL FIRST', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

ThemeData _variantFTheme() {
  const background = Color(0xff070b09);
  const surface = Color(0xff0d120f);
  const bone = Color(0xffddd9c9);
  const green = Color(0xff92be59);
  final scheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: Brightness.dark,
    surface: surface,
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff080d0a),
      foregroundColor: bone,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: Color(0xff354035))),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: bone,
      displayColor: bone,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: const Color(0xff354b2b),
        foregroundColor: bone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: green,
        side: const BorderSide(color: Color(0xff667463)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    ),
  );
}

const _sectionStyle = TextStyle(
  color: Color(0xffa9cf79),
  fontWeight: FontWeight.w800,
  letterSpacing: 1.2,
);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
