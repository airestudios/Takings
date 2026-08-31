import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/database/database_provider.dart';
import 'package:profit_track/features/inventory/data/inventory_repository.dart';
import 'package:profit_track/features/inventory/domain/inventory_item.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(databaseProvider)),
);

final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, List<InventoryItem>>(
      InventoryController.new,
    );

class InventoryController extends AsyncNotifier<List<InventoryItem>> {
  late InventoryRepository repository;

  @override
  Future<List<InventoryItem>> build() {
    repository = ref.watch(inventoryRepositoryProvider);
    return repository.getAll();
  }

  Future<void> save(InventoryItem item) async {
    await repository.save(item);
    state = AsyncData(await repository.getAll());
  }

  Future<void> remove(String id) async {
    await repository.delete(id);
    state = AsyncData(await repository.getAll());
  }
}
