import 'dart:io' show Platform;

import 'package:gastegi/core/errors/exceptions.dart';
import 'package:gastegi/core/storage/seed.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
// Con prefijo: ambos paquetes exportan `databaseFactory`, `Database` y
// compañía, y sin él la referencia sería ambigua.
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// Apertura, esquema y migraciones de la base de datos local.
///
/// El esquema lleva desde la v1 las columnas que necesitará la sincronización
/// en la nube (`created_at`, `updated_at`, `deleted_at`). Añadirlas después
/// obligaría a migrar bases de datos de usuarios reales, y los tombstones de
/// borrado no se pueden reconstruir a posteriori: sin ellos, un borrado hecho
/// en un teléfono sería invisible para el servidor y el otro dispositivo
/// resucitaría la fila al sincronizar.
abstract final class AppDatabase {
  static const String fileName = 'gastegi.db';
  static const int schemaVersion = 1;

  /// Abre la BD del dispositivo.
  static Future<Database> open() async {
    ensureFactory();
    return openAt(p.join(await getDatabasesPath(), fileName));
  }

  /// Registra el motor SQLite para escritorio.
  ///
  /// En Android, iOS y macOS lo pone el plugin nativo de `sqflite`; en Linux y
  /// Windows no hay implementación nativa y sin esto la app falla al arrancar
  /// con "databaseFactory not initialized". En web no sirve ninguno de los
  /// dos: haría falta `sqflite_common_ffi_web`.
  static void ensureFactory() {
    if (Platform.isLinux || Platform.isWindows) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }
  }

  /// Ruta explícita: los tests pasan `inMemoryDatabasePath`.
  static Future<Database> openAt(String path) => openDatabase(
    path,
    version: schemaVersion,
    onConfigure: _onConfigure,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  static Future<void> _onConfigure(Database db) =>
      db.execute('PRAGMA foreign_keys = ON');

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in _ddlV1) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
    await seedNewDatabase(db);
  }

  /// Cada versión futura del esquema añade su entrada aquí. La v1 nunca
  /// aparece: es lo que crea [_onCreate].
  static final Map<int, Future<void> Function(Database)> _migrations = {};

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      final step = _migrations[v];
      if (step == null) {
        throw MissingMigrationException(v);
      }
      await step(db);
    }
  }
}

const List<String> _ddlV1 = [
  '''
  CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    color INTEGER NOT NULL,
    icon_key TEXT NOT NULL,
    budget REAL NOT NULL DEFAULT 0 CHECK (budget >= 0),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
  )
  ''',
  // UNIQUE parcial: con borrado lógico, un UNIQUE a secas impediría reutilizar
  // el nombre de una fila ya borrada.
  '''
  CREATE UNIQUE INDEX idx_categories_name
    ON categories(name) WHERE deleted_at IS NULL
  ''',
  '''
  CREATE TABLE accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    kind TEXT NOT NULL DEFAULT '',
    icon_key TEXT NOT NULL,
    initial_balance REAL NOT NULL DEFAULT 0,
    balance REAL NOT NULL DEFAULT 0,
    archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
  )
  ''',
  '''
  CREATE UNIQUE INDEX idx_accounts_name
    ON accounts(name) WHERE deleted_at IS NULL
  ''',
  '''
  CREATE TABLE expenses (
    id TEXT PRIMARY KEY,
    spent_on TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
  )
  ''',
  // Los movimientos entre cuentas son filas, no mutaciones del saldo: un
  // contador mutado (`balance = balance - x`) no es fusionable, y dos
  // dispositivos offline restando cada uno acabarían con un saldo erróneo.
  '''
  CREATE TABLE transfers (
    id TEXT PRIMARY KEY,
    made_on TEXT NOT NULL,
    from_account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
    to_account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
    amount REAL NOT NULL CHECK (amount > 0),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER
  )
  ''',
  // Clave-valor para el estado de sincronización. La v1 solo guarda device_id.
  '''
  CREATE TABLE sync_state (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
  ''',
  'CREATE INDEX idx_expenses_spent_on ON expenses(spent_on)',
  'CREATE INDEX idx_expenses_category_id ON expenses(category_id)',
  'CREATE INDEX idx_expenses_account_id ON expenses(account_id)',
  'CREATE INDEX idx_expenses_updated_at ON expenses(updated_at)',
  'CREATE INDEX idx_transfers_accounts ON transfers(from_account_id, to_account_id)',
];
