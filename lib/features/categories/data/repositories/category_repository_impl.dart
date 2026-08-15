import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/core/storage/database_provider.dart';
import 'package:gastegi/features/categories/data/models/category_model.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/categories/domain/repositories/category_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Lectura y escritura de categorías.
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._db);

  final Database _db;

  @override
  Future<List<Category>> all() async {
    final rows = await _db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order, name',
    );
    return rows.map(CategoryModel.fromRow).toList();
  }

  @override
  Future<void> updateBudget(String id, double budget) => _db.update(
    'categories',
    {'budget': budget, 'updated_at': DateTime.now().millisecondsSinceEpoch},
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// El repositorio de categories, atado a la base de datos del ámbito.
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(databaseProvider)),
);
