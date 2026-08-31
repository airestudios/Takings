import 'package:drift/drift.dart';
import 'package:profit_track/database/app_database.dart';
import 'package:profit_track/features/sales/domain/sale.dart';

class SalesRepository {
  SalesRepository(this.database);

  final AppDatabase database;

  Future<List<Sale>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT * FROM sales ORDER BY sold_at DESC',
          readsFrom: const {},
        )
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> save(Sale sale) async {
    await database.customStatement(
      '''
      INSERT OR REPLACE INTO sales (
        id, title, marketplace, sold_at, selling_price_minor,
        purchase_cost_minor, fee_minor, postage_minor, packaging_minor,
        other_cost_minor, category, notes, import_source, status,
        external_account_id, external_listing_id, external_order_id,
        external_transaction_id, imported_at, last_synced_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        sale.id,
        sale.title,
        sale.marketplace,
        sale.soldAt.millisecondsSinceEpoch,
        sale.sellingPriceMinor,
        sale.purchaseCostMinor,
        sale.feeMinor,
        sale.postageMinor,
        sale.packagingMinor,
        sale.otherCostMinor,
        sale.category,
        sale.notes,
        sale.importSource.name,
        sale.status.name,
        sale.externalAccountId,
        sale.externalListingId,
        sale.externalOrderId,
        sale.externalTransactionId,
        sale.importedAt?.millisecondsSinceEpoch,
        sale.lastSyncedAt?.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> delete(String id) async {
    await database.customStatement('DELETE FROM sales WHERE id = ?', [id]);
  }

  Sale _fromRow(QueryRow row) {
    final importedAt = row.readNullable<int>('imported_at');
    final lastSyncedAt = row.readNullable<int>('last_synced_at');
    return Sale(
      id: row.read<String>('id'),
      title: row.read<String>('title'),
      marketplace: row.read<String>('marketplace'),
      soldAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('sold_at')),
      sellingPriceMinor: row.read<int>('selling_price_minor'),
      purchaseCostMinor: row.read<int>('purchase_cost_minor'),
      feeMinor: row.read<int>('fee_minor'),
      postageMinor: row.read<int>('postage_minor'),
      packagingMinor: row.read<int>('packaging_minor'),
      otherCostMinor: row.read<int>('other_cost_minor'),
      category: row.read<String>('category'),
      notes: row.read<String>('notes'),
      importSource: ImportSource.values.byName(
        row.read<String>('import_source'),
      ),
      status: SaleStatus.values.byName(row.read<String>('status')),
      externalAccountId: row.readNullable<String>('external_account_id'),
      externalListingId: row.readNullable<String>('external_listing_id'),
      externalOrderId: row.readNullable<String>('external_order_id'),
      externalTransactionId: row.readNullable<String>(
        'external_transaction_id',
      ),
      importedAt: importedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(importedAt),
      lastSyncedAt: lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastSyncedAt),
    );
  }
}
