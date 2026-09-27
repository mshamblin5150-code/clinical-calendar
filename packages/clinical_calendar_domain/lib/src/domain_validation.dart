/// Thrown when input cannot form a valid Clinical Calendar domain value.
final class DomainValidationException implements Exception {
  const DomainValidationException(this.message);

  final String message;

  @override
  String toString() => 'DomainValidationException: $message';
}

String requireIdentifier(
  String value,
  String fieldName, {
  int maximumLength = 128,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > maximumLength) {
    throw DomainValidationException(
      '$fieldName must contain between 1 and $maximumLength characters.',
    );
  }
  if (normalized.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    throw DomainValidationException('$fieldName contains control characters.');
  }
  return normalized;
}
