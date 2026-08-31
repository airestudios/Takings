import 'package:drift/drift.dart';
import 'package:profit_track/database/app_database.dart';
import 'package:profit_track/features/inventory/domain/inventory_item.dart';

class InventoryRepository {
  InventoryRepository(this.database);

  final AppDatabase database;

  Future<List<InventoryItem>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT * FROM inventory ORDER BY purchase_date DESC',
          readsFrom: const {},
        )
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> save(InventoryItem item) async {
    await database.customStatement(
      '''
      INSERT OR REPLACE INTO inventory (
        id, item, purchase_cost_minor, purchase_date, marketplace,
        listing_price_minor, category, status, external_listing_id, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        item.id,
        item.item,
        item.purchaseCostMinor,
        item.purchaseDate.millisecondsSinceEpoch,
        item.marketplace,
        item.listingPriceMinor,
        item.category,
        item.status.name,
        item.externalListingId,
        item.notes,
      ],
    );
  }

  Future<void> delete(String id) =>
      database.customStatement('DELETE FROM inventory WHERE id = ?', [id]);

  InventoryItem _fromRow(QueryRow row) => InventoryItem(
    id: row.read<String>('id'),
    item: row.read<String>('item'),
    purchaseCostMinor: row.read<int>('purchase_cost_minor'),
    purchaseDate: DateTime.fromMillisecondsSinceEpoch(
      row.read<int>('purchase_date'),
    ),
    marketplace: row.read<String>('marketplace'),
    listingPriceMinor: row.read<int>('listing_price_minor'),
    category: row.read<String>('category'),
    status: InventoryStatus.values.byName(row.read<String>('status')),
    externalListingId: row.readNullable<String>('external_listing_id'),
    notes: row.read<String>('notes'),
  );
}
