import '../domain_validation.dart';

/// A reusable class or course selected by Academic Assignments.
final class ClassCatalogEntry {
  factory ClassCatalogEntry({
    required String id,
    required String name,
    bool isArchived = false,
  }) => ClassCatalogEntry._(
    id: requireIdentifier(id, 'Class catalog entry id'),
    name: _requiredName(name),
    isArchived: isArchived,
  );

  const ClassCatalogEntry._({
    required this.id,
    required this.name,
    required this.isArchived,
  });

  final String id;
  final String name;
  final bool isArchived;

  ClassCatalogEntry rename(String name) =>
      ClassCatalogEntry(id: id, name: name, isArchived: isArchived);

  ClassCatalogEntry archive() =>
      ClassCatalogEntry(id: id, name: name, isArchived: true);

  ClassCatalogEntry restore() =>
      ClassCatalogEntry(id: id, name: name, isArchived: false);
}

String _requiredName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > 120) {
    throw const DomainValidationException(
      'Class or course must contain between 1 and 120 characters.',
    );
  }
  if (normalized.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw const DomainValidationException(
      'Class or course contains control characters.',
    );
  }
  return normalized;
}
