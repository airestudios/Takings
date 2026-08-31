enum GoalMeasure { profit, revenue, sales }

enum GoalPeriod { daily, weekly, monthly, annual }

class EarningsGoal {
  const EarningsGoal({
    required this.id,
    required this.name,
    required this.measure,
    required this.period,
    required this.target,
    required this.createdAt,
    this.active = true,
  });

  final String id;
  final String name;
  final GoalMeasure measure;
  final GoalPeriod period;
  final int target;
  final DateTime createdAt;
  final bool active;

  DateTime periodStart(DateTime now) => switch (period) {
    GoalPeriod.daily => DateTime(now.year, now.month, now.day),
    GoalPeriod.weekly => DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday)),
    GoalPeriod.monthly => DateTime(now.year, now.month),
    GoalPeriod.annual => DateTime(now.year),
  };

  DateTime periodEnd(DateTime now) => switch (period) {
    GoalPeriod.daily => DateTime(now.year, now.month, now.day, 23, 59, 59),
    GoalPeriod.weekly => periodStart(now).add(const Duration(days: 6)),
    GoalPeriod.monthly => DateTime(
      now.year,
      now.month + 1,
    ).subtract(const Duration(days: 1)),
    GoalPeriod.annual => DateTime(now.year, 12, 31),
  };
}
