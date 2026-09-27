import '../domain_validation.dart';

enum WorkScheduleFeedNotImportedReason { allDay, skipWord }

final class WorkScheduleFeedNotImportedEvent {
  WorkScheduleFeedNotImportedEvent({
    required String sourceEventUid,
    required String title,
    required this.reason,
  }) : sourceEventUid = requireIdentifier(
         sourceEventUid,
         'Source event UID',
         maximumLength: 1024,
       ),
       title = requireIdentifier(title, 'Event title');

  final String sourceEventUid;
  final String title;
  final WorkScheduleFeedNotImportedReason reason;
}

/// A private employer calendar subscription owned by one Student.
final class WorkScheduleFeed {
  WorkScheduleFeed({
    required String id,
    required String name,
    required Uri url,
    Iterable<String> skipWords = defaultSkipWords,
    required DateTime lastCheckedAtUtc,
    required DateTime lastSuccessfulUpdateAtUtc,
    Iterable<WorkScheduleFeedNotImportedEvent> notImported = const [],
    this.heldReason,
  }) : id = requireIdentifier(id, 'Work Schedule Feed id'),
       name = requireIdentifier(name, 'Work Schedule Feed name'),
       url = _requireFeedUrl(url),
       skipWords = List.unmodifiable(_normalizeSkipWords(skipWords)),
       lastCheckedAtUtc = _requireUtc(lastCheckedAtUtc, 'Last checked time'),
       lastSuccessfulUpdateAtUtc = _requireUtc(
         lastSuccessfulUpdateAtUtc,
         'Last successful update time',
       ),
       notImported = List.unmodifiable(notImported) {
    if (lastSuccessfulUpdateAtUtc.isAfter(lastCheckedAtUtc)) {
      throw const DomainValidationException(
        'A successful feed update cannot be after its last check.',
      );
    }
  }

  static const defaultSkipWords = <String>[
    'PTO',
    'Vacation',
    'Off',
    'Holiday',
    'Request',
  ];

  final String id;
  final String name;

  /// Credential-bearing URL. Do not include it in exports, diagnostics, logs,
  /// Tickets, or display it without [maskedUrl].
  final Uri url;
  final List<String> skipWords;
  final DateTime lastCheckedAtUtc;
  final DateTime lastSuccessfulUpdateAtUtc;
  final List<WorkScheduleFeedNotImportedEvent> notImported;
  final String? heldReason;

  String get maskedUrl {
    final port = url.hasPort ? ':${url.port}' : '';
    return '${url.scheme}://${url.host}$port/…';
  }

  WorkScheduleFeed copyWith({
    Iterable<String>? skipWords,
    DateTime? lastCheckedAtUtc,
    DateTime? lastSuccessfulUpdateAtUtc,
    Iterable<WorkScheduleFeedNotImportedEvent>? notImported,
    String? heldReason,
    bool clearHeldReason = false,
  }) => WorkScheduleFeed(
    id: id,
    name: name,
    url: url,
    skipWords: skipWords ?? this.skipWords,
    lastCheckedAtUtc: lastCheckedAtUtc ?? this.lastCheckedAtUtc,
    lastSuccessfulUpdateAtUtc:
        lastSuccessfulUpdateAtUtc ?? this.lastSuccessfulUpdateAtUtc,
    notImported: notImported ?? this.notImported,
    heldReason: clearHeldReason ? null : heldReason ?? this.heldReason,
  );
}

Uri _requireFeedUrl(Uri value) {
  if ((value.scheme != 'https' && value.scheme != 'webcal') ||
      value.host.isEmpty ||
      value.userInfo.isNotEmpty) {
    throw const DomainValidationException(
      'A Work Schedule Feed URL must be an HTTPS or webcal URL without embedded credentials.',
    );
  }
  return value;
}

List<String> _normalizeSkipWords(Iterable<String> values) {
  final result = <String>[];
  final observed = <String>{};
  for (final value in values) {
    final normalized = requireIdentifier(value, 'Skip word');
    if (observed.add(normalized.toLowerCase())) result.add(normalized);
  }
  return result;
}

DateTime _requireUtc(DateTime value, String fieldName) {
  if (!value.isUtc) {
    throw DomainValidationException('$fieldName must be UTC.');
  }
  return value;
}
