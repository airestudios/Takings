class GoalProgress {
  const GoalProgress({
    required this.current,
    required this.target,
    required this.elapsedDays,
    required this.totalDays,
  });

  final int current;
  final int target;
  final int elapsedDays;
  final int totalDays;

  double get percentage => target <= 0 ? 0 : current / target * 100;
  int get remaining => (target - current).clamp(0, target);
  int get remainingDays => (totalDays - elapsedDays).clamp(0, totalDays);
  double get requiredPerRemainingDay =>
      remainingDays == 0 ? remaining.toDouble() : remaining / remainingDays;
  double get expectedAtCurrentPoint =>
      totalDays == 0 ? target.toDouble() : target * elapsedDays / totalDays;
  double get aheadBehind => current - expectedAtCurrentPoint;
  double get projectedFinal =>
      elapsedDays == 0 ? 0 : current / elapsedDays * totalDays;
}

abstract final class GoalCalculator {
  static GoalProgress calculate({
    required int current,
    required int target,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime now,
  }) {
    final totalDays = periodEnd.difference(periodStart).inDays + 1;
    final effectiveNow = now.isBefore(periodStart)
        ? periodStart
        : now.isAfter(periodEnd)
        ? periodEnd
        : now;
    final elapsedDays = effectiveNow.difference(periodStart).inDays + 1;
    return GoalProgress(
      current: current,
      target: target,
      elapsedDays: elapsedDays,
      totalDays: totalDays,
    );
  }
}
