import 'package:drift/drift.dart';
import 'package:profit_track/database/app_database.dart';
import 'package:profit_track/features/goals/domain/earnings_goal.dart';

class GoalsRepository {
  GoalsRepository(this.database);

  final AppDatabase database;

  Future<List<EarningsGoal>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT * FROM goals ORDER BY active DESC, created_at ASC',
          readsFrom: const {},
        )
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<void> save(EarningsGoal goal) async {
    await database.customStatement(
      '''
      INSERT OR REPLACE INTO goals (
        id, name, measure, period, target, active, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        goal.id,
        goal.name,
        goal.measure.name,
        goal.period.name,
        goal.target,
        goal.active ? 1 : 0,
        goal.createdAt.millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> delete(String id) =>
      database.customStatement('DELETE FROM goals WHERE id = ?', [id]);

  EarningsGoal _fromRow(QueryRow row) => EarningsGoal(
    id: row.read<String>('id'),
    name: row.read<String>('name'),
    measure: GoalMeasure.values.byName(row.read<String>('measure')),
    period: GoalPeriod.values.byName(row.read<String>('period')),
    target: row.read<int>('target'),
    active: row.read<int>('active') == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
  );
}
