import 'ticket_diagnostic.dart';

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

  bool get isClosed => this == done || this == wontDo;
}

final class TicketContext {
  const TicketContext({
    required this.screen,
    required this.build,
    required this.device,
    required this.platform,
    required this.capturedAtUtc,
    this.recentActions = const [],
    this.refusalCode,
  });

  final String screen;
  final String build;
  final String device;
  final String platform;
  final DateTime capturedAtUtc;
  final List<String> recentActions;
  final String? refusalCode;
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
    List<String> recentActions = const [],
    String? refusalCode,
  }) => TicketContext(
    screen: screen,
    build: build,
    device: device,
    platform: platform,
    capturedAtUtc: capturedAtUtc,
    recentActions: List.unmodifiable(recentActions),
    refusalCode: refusalCode,
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
    this.questionCount = 0,
    this.seenAtUtc,
    this.closeReason,
    this.closedAtUtc,
    this.reopenedAtUtc,
    this.reopenNote,
    this.canReopen = false,
    this.reopenUntilUtc,
  });

  final String id;
  final String senderId;
  final TicketKind kind;
  final String text;
  final TicketStatus status;
  final TicketContext context;
  final DateTime createdAtUtc;
  final int questionCount;
  final DateTime? seenAtUtc;
  final String? closeReason;
  final DateTime? closedAtUtc;
  final DateTime? reopenedAtUtc;
  final String? reopenNote;
  final bool canReopen;
  final DateTime? reopenUntilUtc;

  String get firstLine => text.split(RegExp(r'\r?\n')).first;

  Ticket copyWith({
    TicketStatus? status,
    int? questionCount,
    DateTime? seenAtUtc,
    String? closeReason,
    DateTime? closedAtUtc,
    DateTime? reopenedAtUtc,
    String? reopenNote,
    bool? canReopen,
    DateTime? reopenUntilUtc,
  }) => Ticket(
    id: id,
    senderId: senderId,
    kind: kind,
    text: text,
    status: status ?? this.status,
    context: context,
    createdAtUtc: createdAtUtc,
    questionCount: questionCount ?? this.questionCount,
    seenAtUtc: seenAtUtc ?? this.seenAtUtc,
    closeReason: closeReason ?? this.closeReason,
    closedAtUtc: closedAtUtc ?? this.closedAtUtc,
    reopenedAtUtc: reopenedAtUtc ?? this.reopenedAtUtc,
    reopenNote: reopenNote ?? this.reopenNote,
    canReopen: canReopen ?? this.canReopen,
    reopenUntilUtc: reopenUntilUtc ?? this.reopenUntilUtc,
  );
}

enum TicketThreadAuthor { maintainer, sender }

enum TicketThreadEntryKind {
  question('question'),
  answer('answer'),
  diagnosticRequest('diagnostic_request'),
  diagnosticAttached('diagnostic_attached'),
  diagnosticDeclined('diagnostic_declined');

  const TicketThreadEntryKind(this.databaseValue);

  final String databaseValue;

  static TicketThreadEntryKind fromDatabase(String value) => values.firstWhere(
    (kind) => kind.databaseValue == value,
    orElse: () => throw FormatException('Unknown Ticket thread kind: $value'),
  );
}

final class TicketThreadEntry {
  const TicketThreadEntry({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.kind,
    required this.createdAtUtc,
    this.text,
    this.replyToId,
    this.diagnostic,
  });

  final String id;
  final String ticketId;
  final TicketThreadAuthor author;
  final TicketThreadEntryKind kind;
  final String? text;
  final String? replyToId;
  final TicketDiagnosticSnapshot? diagnostic;
  final DateTime createdAtUtc;
}

enum TicketThreadRefusal {
  questionInvalid,
  ticketNotReady,
  answerInvalid,
  responseNotWaiting,
  questionLimitReached,
  diagnosticInvalid,
}

final class TicketThreadRejected implements Exception {
  const TicketThreadRejected(this.reason);

  final TicketThreadRefusal reason;
}

enum TicketSubmissionRefusal { textInvalid, contextIncomplete, rateLimited }

final class TicketSubmissionRejected implements Exception {
  const TicketSubmissionRejected(this.reason);

  final TicketSubmissionRefusal reason;
}

final class TicketAccessRejected implements Exception {
  const TicketAccessRejected();
}

enum TicketMutationRefusal {
  closingReasonRequired,
  cannotClose,
  reopeningNoteRequired,
  cannotReopen,
  reopenExpired,
}

final class TicketMutationRejected implements Exception {
  const TicketMutationRejected(this.reason);

  final TicketMutationRefusal reason;
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
  Future<Ticket> openForSender(String ticketId);
  Future<Ticket> close(
    String ticketId, {
    required TicketStatus outcome,
    required String reason,
  });
  Future<Ticket> reopen(String ticketId, {required String note});
  Future<List<TicketThreadEntry>> readThread(String ticketId);
  Future<Ticket> askQuestion(String ticketId, {required String question});
  Future<Ticket> answerQuestion(
    String ticketId,
    String questionId, {
    required String answer,
  });
  Future<Ticket> requestDiagnostic(String ticketId);
  Future<Ticket> attachDiagnostic(
    String ticketId,
    String requestId,
    TicketDiagnosticSnapshot diagnostic,
  );
  Future<Ticket> declineDiagnostic(String ticketId, String requestId);
}
