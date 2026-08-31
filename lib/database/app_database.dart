import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(driftDatabase(name: 'profit_track'));

  @override
  int get schemaVersion => 3;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await customStatement('''
            CREATE TABLE sales (
              id TEXT PRIMARY KEY NOT NULL,
              title TEXT NOT NULL,
              marketplace TEXT NOT NULL,
              sold_at INTEGER NOT NULL,
              selling_price_minor INTEGER NOT NULL,
              purchase_cost_minor INTEGER NOT NULL,
              fee_minor INTEGER NOT NULL DEFAULT 0,
              postage_minor INTEGER NOT NULL DEFAULT 0,
              packaging_minor INTEGER NOT NULL DEFAULT 0,
              other_cost_minor INTEGER NOT NULL DEFAULT 0,
              category TEXT NOT NULL,
              notes TEXT NOT NULL,
              import_source TEXT NOT NULL,
              status TEXT NOT NULL,
              external_account_id TEXT,
              external_listing_id TEXT,
              external_order_id TEXT,
              external_transaction_id TEXT,
              imported_at INTEGER,
              last_synced_at INTEGER
            )
          ''');
      await customStatement('''
            CREATE UNIQUE INDEX sales_external_transaction
            ON sales(marketplace, external_transaction_id)
            WHERE external_transaction_id IS NOT NULL
          ''');
      await customStatement('''
            CREATE TABLE preferences (
              key TEXT PRIMARY KEY NOT NULL,
              value TEXT NOT NULL
            )
          ''');
      await _createExpenseAndInventoryTables();
      await _createGoalsTable();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await _createExpenseAndInventoryTables();
      if (from < 3) await _createGoalsTable();
    },
  );

  Future<void> _createExpenseAndInventoryTables() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY NOT NULL,
        description TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        spent_at INTEGER NOT NULL,
        category TEXT NOT NULL,
        notes TEXT NOT NULL,
        recurring_monthly INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS inventory (
        id TEXT PRIMARY KEY NOT NULL,
        item TEXT NOT NULL,
        purchase_cost_minor INTEGER NOT NULL,
        purchase_date INTEGER NOT NULL,
        marketplace TEXT NOT NULL,
        listing_price_minor INTEGER NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        external_listing_id TEXT,
        notes TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createGoalsTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS goals (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        measure TEXT NOT NULL,
        period TEXT NOT NULL,
        target INTEGER NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
