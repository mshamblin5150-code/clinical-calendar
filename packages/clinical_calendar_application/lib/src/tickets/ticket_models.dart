enum TicketKind {
  problem("Something's wrong", 'problem'),
  idea('An idea', 'idea'),
  question('A question', 'question');

  const TicketKind(this.label, this.databaseValue);

  final String label;
  final String databaseValue;

  static TicketKind fromDatabase(String value) => values.firstWhere(
    (kind) => kind.databaseValue == value,
    orElse: () => throw FormatException('Unknown Ticket kind: $value'),
  );
}

enum TicketStatus {
  sent('Sent', 'sent'),
  seen('Seen', 'seen'),
  waitingOnYou('Waiting on you', 'waiting_on_sender'),
  done('Done', 'done'),
  wontDo("Won't do", 'wont_do');

  const TicketStatus(this.label, this.databaseValue);

  final String label;
  final String databaseValue;

  static TicketStatus fromDatabase(String value) => values.firstWhere(
    (status) => status.databaseValue == value,
    orElse: () => throw FormatException('Unknown Ticket status: $value'),
  );
}

final class TicketContext {
  const TicketContext({
    required this.screen,
    required this.build,
    required this.device,
    required this.platform,
    required this.capturedAtUtc,
  });

  final String screen;
  final String build;
  final String device;
  final String platform;
  final DateTime capturedAtUtc;
}

final class TicketClientContext {
  const TicketClientContext({
    required this.build,
    required this.device,
    required this.platform,
  });

  final String build;
  final String device;
  final String platform;

  TicketContext capture({
    required String screen,
    required DateTime capturedAtUtc,
  }) => TicketContext(
    screen: screen,
    build: build,
    device: device,
    platform: platform,
    capturedAtUtc: capturedAtUtc,
  );
}

final class Ticket {
  const Ticket({
    required this.id,
    required this.senderId,
    required this.kind,
    required this.text,
    required this.status,
    required this.context,
    required this.createdAtUtc,
    this.seenAtUtc,
  });

  final String id;
  final String senderId;
  final TicketKind kind;
  final String text;
  final TicketStatus status;
  final TicketContext context;
  final DateTime createdAtUtc;
  final DateTime? seenAtUtc;

  String get firstLine => text.split(RegExp(r'\r?\n')).first;

  Ticket copyWith({TicketStatus? status, DateTime? seenAtUtc}) => Ticket(
    id: id,
    senderId: senderId,
    kind: kind,
    text: text,
    status: status ?? this.status,
    context: context,
    createdAtUtc: createdAtUtc,
    seenAtUtc: seenAtUtc ?? this.seenAtUtc,
  );
}

enum TicketSubmissionRefusal { textInvalid, contextIncomplete, rateLimited }

final class TicketSubmissionRejected implements Exception {
  const TicketSubmissionRejected(this.reason);

  final TicketSubmissionRefusal reason;
}

final class TicketAccessRejected implements Exception {
  const TicketAccessRejected();
}

final class TicketUnavailable implements Exception {
  const TicketUnavailable();
}

abstract interface class TicketGateway {
  Future<void> putIn({
    required TicketKind kind,
    required String text,
    required TicketContext context,
  });

  Future<bool> hasMaintainerGrant();
  Future<List<Ticket>> readMine();
  Future<List<Ticket>> readForMaintainer();
  Future<Ticket> openForMaintainer(String ticketId);
}
