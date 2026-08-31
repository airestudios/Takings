import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/database/database_provider.dart';
import 'package:profit_track/features/goals/data/goals_repository.dart';
import 'package:profit_track/features/goals/domain/earnings_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(ref.watch(databaseProvider)),
);

final goalsControllerProvider =
    AsyncNotifierProvider<GoalsController, List<EarningsGoal>>(
      GoalsController.new,
    );

class GoalsController extends AsyncNotifier<List<EarningsGoal>> {
  late GoalsRepository repository;

  @override
  Future<List<EarningsGoal>> build() async {
    repository = ref.watch(goalsRepositoryProvider);
    final goals = await repository.getAll();
    if (goals.isNotEmpty) return goals;
    final preferences = await SharedPreferences.getInstance();
    final selectedType = preferences.getString('goal_type') ?? 'Monthly profit';
    final words = selectedType.toLowerCase();
    final measure = words.contains('revenue')
        ? GoalMeasure.revenue
        : words.contains('sales')
        ? GoalMeasure.sales
        : GoalMeasure.profit;
    final period = words.contains('year')
        ? GoalPeriod.annual
        : words.contains('week')
        ? GoalPeriod.weekly
        : words.contains('day')
        ? GoalPeriod.daily
        : GoalPeriod.monthly;
    final storedTarget = preferences.getInt('goal_target_minor') ?? 100000;
    final defaultGoal = EarningsGoal(
      id: 'default-monthly-profit',
      name: selectedType,
      measure: measure,
      period: period,
      target: measure == GoalMeasure.sales ? storedTarget ~/ 100 : storedTarget,
      createdAt: DateTime.now(),
    );
    await repository.save(defaultGoal);
    return [defaultGoal];
  }

  Future<void> save(EarningsGoal goal) async {
    await repository.save(goal);
    state = AsyncData(await repository.getAll());
  }

  Future<void> remove(String id) async {
    await repository.delete(id);
    state = AsyncData(await repository.getAll());
  }
}
