import 'package:sqflite/sqflite.dart';

/// Almacén clave-valor local, sobre la tabla `sync_state`.
///
/// Es donde van los ajustes sueltos que no merecen tabla propia: hoy solo el
/// `device_id` que siembra `seed.dart`, y mañana los marcadores de la
/// sincronización (último pull, cursor del servidor).
///
/// Va en `core/` y no en una feature porque no pertenece a ninguna: cualquiera
/// puede guardar aquí su ajuste sin arrastrar una dependencia hacia otra.
class LocalStorage {
  const LocalStorage(this._db);

  static const String table = 'sync_state';

  final DatabaseExecutor _db;

  /// Valor de [key], o `null` si nunca se ha escrito.
  Future<String?> read(String key) async {
    final rows = await _db.query(
      table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  /// Escribe [value] en [key], sobrescribiendo lo que hubiera.
  Future<void> write(String key, String value) => _db.insert(
    table,
    {'key': key, 'value': value},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> delete(String key) =>
      _db.delete(table, where: 'key = ?', whereArgs: [key]);
}
