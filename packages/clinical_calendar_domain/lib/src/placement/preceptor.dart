import '../domain_validation.dart';

/// A reusable person who supervises Clinical Sessions.
///
/// [schedulingNotes] are operational notes only and must never contain patient
/// information. Privacy enforcement at input and persistence boundaries is
/// completed by ticket 84.
final class Preceptor {
  factory Preceptor({
    required String id,
    required String name,
    String? organizationOrSite,
    String? phone,
    String? email,
    String? schedulingNotes,
  }) => Preceptor._(
    id: requireIdentifier(id, 'Preceptor id'),
    name: _requiredText(name, 'Preceptor name', 120),
    organizationOrSite: _optionalText(
      organizationOrSite,
      'Organization or site',
      200,
    ),
    phone: _optionalText(phone, 'Phone', 80),
    email: _optionalEmail(email),
    schedulingNotes: _optionalText(
      schedulingNotes,
      'Scheduling notes',
      2000,
      allowNewlines: true,
    ),
  );

  const Preceptor._({
    required this.id,
    required this.name,
    required this.organizationOrSite,
    required this.phone,
    required this.email,
    required this.schedulingNotes,
  });

  final String id;
  final String name;
  final String? organizationOrSite;
  final String? phone;
  final String? email;
  final String? schedulingNotes;
}

String _requiredText(String value, String fieldName, int maximumLength) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maximumLength) {
    throw DomainValidationException(
      '$fieldName must contain between 1 and $maximumLength characters.',
    );
  }
  _rejectControlCharacters(normalized, fieldName);
  return normalized;
}

String? _optionalText(
  String? value,
  String fieldName,
  int maximumLength, {
  bool allowNewlines = false,
}) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final normalized = value.trim();
  if (normalized.length > maximumLength) {
    throw DomainValidationException(
      '$fieldName cannot exceed $maximumLength characters.',
    );
  }
  _rejectControlCharacters(normalized, fieldName, allowNewlines: allowNewlines);
  return normalized;
}

String? _optionalEmail(String? value) {
  final normalized = _optionalText(value, 'Email', 254);
  if (normalized == null) {
    return null;
  }
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
    throw const DomainValidationException('Email is not valid.');
  }
  return normalized;
}

void _rejectControlCharacters(
  String value,
  String fieldName, {
  bool allowNewlines = false,
}) {
  final hasInvalidControl = value.codeUnits.any(
    (unit) =>
        unit == 0x7f ||
        (unit < 0x20 && !(allowNewlines && (unit == 0x0a || unit == 0x0d))),
  );
  if (hasInvalidControl) {
    throw DomainValidationException('$fieldName contains control characters.');
  }
}
