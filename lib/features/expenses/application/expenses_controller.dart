import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/ads/interstitial_manager.dart';
import 'package:profit_track/database/database_provider.dart';
import 'package:profit_track/features/expenses/data/expenses_repository.dart';
import 'package:profit_track/features/expenses/domain/expense.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(databaseProvider)),
);

final expensesControllerProvider =
    AsyncNotifierProvider<ExpensesController, List<Expense>>(
      ExpensesController.new,
    );

class ExpensesController extends AsyncNotifier<List<Expense>> {
  late ExpensesRepository repository;

  @override
  Future<List<Expense>> build() {
    repository = ref.watch(expensesRepositoryProvider);
    return repository.getAll();
  }

  Future<void> save(Expense expense) async {
    await repository.save(expense);
    state = AsyncData(await repository.getAll());
    await InterstitialManager.instance.recordMeaningfulAction();
  }

  Future<void> remove(String id) async {
    await repository.delete(id);
    state = AsyncData(await repository.getAll());
  }
}
