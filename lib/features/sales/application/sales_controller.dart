import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/database/database_provider.dart';
import 'package:profit_track/features/sales/data/sales_repository.dart';
import 'package:profit_track/features/sales/domain/sale.dart';

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(ref.watch(databaseProvider)),
);

final salesControllerProvider =
    AsyncNotifierProvider<SalesController, List<Sale>>(SalesController.new);

class SalesController extends AsyncNotifier<List<Sale>> {
  late SalesRepository repository;

  @override
  Future<List<Sale>> build() {
    repository = ref.watch(salesRepositoryProvider);
    return _load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> add(Sale sale) async {
    await repository.save(sale);
    await load();
  }

  Future<void> remove(String id) async {
    await repository.delete(id);
    await load();
  }

  Future<List<Sale>> _load() async {
    return repository.getAll();
  }
}
