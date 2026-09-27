String formatUsDateFromDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}-'
      '${local.year.toString().padLeft(4, '0')}';
}

String formatUsDateTime(DateTime value) {
  final local = value.toLocal();
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final hour = switch (local.hour % 12) {
    0 => 12,
    final value => value,
  };
  return '${formatUsDateFromDateTime(local)} $hour:'
      '${local.minute.toString().padLeft(2, '0')} $period';
}
