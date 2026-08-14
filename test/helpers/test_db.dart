import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/core/storage/app_database.dart';
import 'package:gastegi/core/storage/database_provider.dart';
import 'package:gastegi/core/utils/clock.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reloj congelado: sin él, los rangos "últimos 7/15 días" y la longitud de
/// `dailyTotals` dependerían del día real y los tests fallarían a ratos.
final DateTime testNow = DateTime(2026, 8, 12);

bool _factoryReady = false;

/// Registra la fábrica **sin isolate**, una sola vez por proceso de test.
///
/// `databaseFactoryFfi` habla con SQLite en un isolate aparte y responde por el
/// event loop real. Dentro de `testWidgets`, que corre en una zona `FakeAsync`,
/// ese event loop no avanza y el primer `await` contra la BD se cuelga para
/// siempre. La variante sin isolate resuelve por microtareas, que `FakeAsync`
/// sí procesa.
///
/// Reasignarla una única vez evita además el aviso de sqflite en cada `setUp`.
void _ensureTestFactory() {
  if (_factoryReady) return;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  _factoryReady = true;
}

/// SQLite real en memoria: cada test tiene su BD, sin ficheros ni interferencias.
Future<Database> openTestDb() async {
  _ensureTestFactory();
  return AppDatabase.openAt(inMemoryDatabasePath);
}

/// Carga los datos de locale que necesita `DateFormat('…', 'es')`.
Future<void> initTestLocale() => initializeDateFormatting('es');

/// Ámbito de providers contra [db] y con el reloj congelado.
ProviderContainer buildContainer(Database db, {DateTime? now}) =>
    ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now ?? testNow),
      ],
    );

/// Ámbito ya cargado, como lo deja `bootstrap()` antes del primer frame.
Future<ProviderContainer> buildLoadedContainer(
  Database db, {
  DateTime? now,
}) async {
  final container = buildContainer(db, now: now);
  await container.read(appDataProvider.notifier).load();
  return container;
}

Future<AppState> buildState(Database db, {DateTime? now}) async {
  final container = await buildLoadedContainer(db, now: now);
  return container.read(appStateProvider);
}
