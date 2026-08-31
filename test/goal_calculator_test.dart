import 'package:flutter_test/flutter_test.dart';
import 'package:profit_track/features/goals/domain/goal_calculator.dart';

void main() {
  test('calculates monthly goal pace', () {
    final progress = GoalCalculator.calculate(
      current: 74200,
      target: 100000,
      periodStart: DateTime(2026, 8),
      periodEnd: DateTime(2026, 8, 31),
      now: DateTime(2026, 8, 22),
    );
    expect(progress.percentage, 74.2);
    expect(progress.remaining, 25800);
    expect(progress.remainingDays, 9);
    expect(progress.requiredPerRemainingDay, closeTo(2866.666, .01));
    expect(progress.aheadBehind, greaterThan(0));
  });
}
