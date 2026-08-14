import 'package:gastegi/features/categories/data/models/category_model.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:sqflite/sqflite.dart';

/// Lectura y escritura de categorías.
class CategoryRepository {
  const CategoryRepository(this._db);

  final Database _db;

  Future<List<Category>> all() async {
    final rows = await _db.query(
      'categories',
      where: 'deleted_at IS NULL',
      orderBy: 'sort_order, name',
    );
    return rows.map(CategoryModel.fromRow).toList();
  }

  Future<void> updateBudget(String id, double budget) => _db.update(
    'categories',
    {'budget': budget, 'updated_at': DateTime.now().millisecondsSinceEpoch},
    where: 'id = ?',
    whereArgs: [id],
  );
}
