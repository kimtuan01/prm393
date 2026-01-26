/// Budget time progress calculator
///
/// Provides logic to compute the position of the "Hôm nay" marker
/// relative to a budget's start/end dates. Logic is decoupled from UI
/// and easy to test.
class BudgetProgress {
  /// Computes the time progress percent for the "Hôm nay" marker.
  ///
  /// Definitions:
  /// - totalDays = endDate - startDate + 1
  /// - elapsedDays = today - startDate + 1
  /// - timeProgressPercent = elapsedDays / totalDays
  ///
  /// Constraints:
  /// - If today < startDate => 0
  /// - If today > endDate => 1
  /// - Clamp result to [0, 1]
  static double computeTimeProgressPercent(
    DateTime startDate,
    DateTime endDate,
    DateTime today,
  ) {
    // Normalize to remove time-of-day effects
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final now = DateTime(today.year, today.month, today.day);

    // Guard invalid ranges
    if (!start.isBefore(end) && start != end) {
      // If start > end, treat as 0 progress
      return 0.0;
    }

    // Inclusive day count
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) return 0.0;

    // Today before start => 0, after end => 1
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;

    final elapsedDays = now.difference(start).inDays + 1;
    final percent = elapsedDays / totalDays;
    if (percent.isNaN) return 0.0;
    return percent.clamp(0.0, 1.0);
  }
}
