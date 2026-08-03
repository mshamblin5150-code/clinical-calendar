import '../domain_validation.dart';
import '../time/local_date.dart';

/// An all-day reservation for rest and preparation.
final class ProtectedDay {
  ProtectedDay({required String id, required this.date})
    : id = requireIdentifier(id, 'Protected Day id');

  final String id;
  final LocalDate date;
}
