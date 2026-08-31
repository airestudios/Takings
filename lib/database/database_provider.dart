import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_track/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
