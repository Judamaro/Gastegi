import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/core/storage/app_database.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
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

Future<AppState> buildState(Database db, {DateTime? now}) async {
  final state = AppState(
    categoryRepo: CategoryRepositoryImpl(db),
    accountRepo: AccountRepositoryImpl(db),
    expenseRepo: ExpenseRepositoryImpl(db),
    clock: () => now ?? testNow,
  );
  await state.load();
  return state;
}
