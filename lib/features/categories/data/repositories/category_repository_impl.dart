import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/core/storage/database_provider.dart';
import 'package:gastegi/features/categories/data/models/category_model.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';
import 'package:gastegi/features/categories/domain/repositories/category_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Lectura y escritura de categorías.
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._db);

  final Database _db;
  static const _uuid = Uuid();

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
  Future<String> create({
    required String name,
    required int colorValue,
    required String iconKey,
    required double budget,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    // Al final de la lista: el orden de la siembra es el del diseño, y una
    // categoría nueva no tiene por qué colarse entre medias.
    final nextOrder =
        Sqflite.firstIntValue(
          await _db.rawQuery(
            'SELECT COALESCE(MAX(sort_order) + 1, 0) FROM categories',
          ),
        ) ??
        0;
    await _db.insert('categories', {
      'id': id,
      'name': name,
      'color': colorValue,
      'icon_key': iconKey,
      'budget': budget,
      'sort_order': nextOrder,
      'created_at': now,
      'updated_at': now,
    });
    return id;
  }

  /// Sin transacción ni recálculo de saldos: al revés que las cuentas, ninguna
  /// columna derivada depende de una categoría.
  @override
  Future<void> update(
    String id, {
    required String name,
    required int colorValue,
    required String iconKey,
    required double budget,
  }) => _db.update(
    'categories',
    {
      'name': name,
      'color': colorValue,
      'icon_key': iconKey,
      'budget': budget,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    },
    where: 'id = ?',
    whereArgs: [id],
  );

  @override
  Future<void> softDelete(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.update(
      'categories',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  @override
  Future<int> expenseCount(String id) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM expenses WHERE category_id = ? AND deleted_at IS NULL',
          [id],
        ),
      ) ??
      0;

  @override
  Future<bool> nameExists(String name, {String? exceptId}) async {
    final rows = await _db.query(
      'categories',
      columns: ['id'],
      where:
          'deleted_at IS NULL AND name = ? COLLATE NOCASE'
          '${exceptId == null ? '' : ' AND id != ?'}',
      whereArgs: [name, ?exceptId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}

/// El repositorio de categories, atado a la base de datos del ámbito.
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(databaseProvider)),
);
