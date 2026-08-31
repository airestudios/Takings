import 'package:drift/drift.dart';
import 'package:profit_track/database/app_database.dart';
import 'package:profit_track/features/expenses/domain/expense.dart';

class ExpensesRepository {
  ExpensesRepository(this.database);

  final AppDatabase database;

  Future<List<Expense>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT * FROM expenses ORDER BY spent_at DESC',
          readsFrom: const {},
        )
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> save(Expense expense) async {
    await database.customStatement(
      '''
      INSERT OR REPLACE INTO expenses (
        id, description, amount_minor, spent_at, category, notes,
        recurring_monthly
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        expense.id,
        expense.description,
        expense.amountMinor,
        expense.spentAt.millisecondsSinceEpoch,
        expense.category,
        expense.notes,
        expense.recurringMonthly ? 1 : 0,
      ],
    );
  }

  Future<void> delete(String id) =>
      database.customStatement('DELETE FROM expenses WHERE id = ?', [id]);

  Expense _fromRow(QueryRow row) => Expense(
    id: row.read<String>('id'),
    description: row.read<String>('description'),
    amountMinor: row.read<int>('amount_minor'),
    spentAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('spent_at')),
    category: row.read<String>('category'),
    notes: row.read<String>('notes'),
    recurringMonthly: row.read<int>('recurring_monthly') == 1,
  );
}
