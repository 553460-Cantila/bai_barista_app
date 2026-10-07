/// Rolling "last N days" windows shared by the staff Sales Summary and the
/// admin Earnings Report. The window includes today, so "Last 7 days" is
/// exactly 7 calendar days (this matters for the prorated subscription cost).
enum PeriodRange {
  days7(7, 'Last 7 days'),
  days30(30, 'Last 30 days'),
  days90(90, 'Last 90 days');

  final int days;
  final String label;
  const PeriodRange(this.days, this.label);

  /// Midnight at the start of the window.
  DateTime start() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: days - 1));
  }
}