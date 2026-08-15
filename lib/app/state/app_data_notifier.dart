import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/state/app_data.dart';
import 'package:gastegi/core/utils/clock.dart';
import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';

/// Los datos de la app y el **único** punto de escritura.
///
/// Toda escritura recarga la foto entera. Con estos volúmenes cuesta
/// microsegundos y elimina una clase completa de bugs: `Account.balance` es
/// una columna derivada que cambia al crear un gasto, así que refrescar solo
/// "lo que has tocado" dejaría saldos viejos en pantalla **sin lanzar ningún
/// error**.
class AppDataNotifier extends Notifier<AppData> {
  bool _busy = false;

  @override
  AppData build() => AppData.empty(ref.read(clockProvider)());

  /// Repuebla desde la BD. Es también lo que habrá que llamar al terminar un
  /// pull cuando exista sincronización con la nube.
  Future<void> load() async {
    final now = ref.read(clockProvider)();
    final today = dateOnly(now);
    final monthAnchor = monthStart(now);
    final windowStart = earliest(
      monthAnchor,
      daysBefore(today, AppData.windowPadDays),
    );

    final categoryRepo = ref.read(categoryRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final expenseRepo = ref.read(expenseRepositoryProvider);

    state = AppData(
      categories: await categoryRepo.all(),
      accounts: await accountRepo.all(),
      window: await expenseRepo.since(windowStart),
      monthlySums: await expenseRepo.monthlyTotals(
        from: addMonths(monthAnchor, -AppData.monthsBack),
      ),
      expenseCount: await expenseRepo.count(),
      today: today,
      monthAnchor: monthAnchor,
    );
  }

  /// Ejecuta [op] y recarga.
  ///
  /// El cerrojo es de toda la aplicación y tiene que seguir siéndolo: es lo
  /// que evita que un doble toque en "Guardar" cree dos filas. Si cada
  /// funcionalidad tuviera el suyo, el bug volvería.
  Future<void> write(Future<void> Function() op) async {
    if (_busy) return;
    _busy = true;
    try {
      await op();
      await load();
    } finally {
      _busy = false;
    }
  }
}

final appDataProvider = NotifierProvider<AppDataNotifier, AppData>(
  AppDataNotifier.new,
);
