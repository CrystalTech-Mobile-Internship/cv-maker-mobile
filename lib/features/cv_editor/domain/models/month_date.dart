/// Reads a stored CV date (month precision) as UTC.
///
/// Dates typed as "MM/YYYY" in Vietnam (UTC+7) used to be saved as local
/// midnight converted to UTC, i.e. 17:00 UTC on the last day of the month
/// before. Those values are moved back to the first of the intended month.
DateTime normalizeMonthDate(DateTime value) {
  final utc = value.toUtc();
  if (utc.hour == 17 &&
      utc.minute == 0 &&
      utc.second == 0 &&
      utc.millisecond == 0 &&
      utc.microsecond == 0) {
    final next = DateTime.utc(utc.year, utc.month, utc.day + 1);
    if (next.day == 1) return next;
  }
  return utc;
}

DateTime parseMonthDate(String value) =>
    normalizeMonthDate(DateTime.parse(value));
