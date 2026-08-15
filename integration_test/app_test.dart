import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/storage/app_database.dart';
import 'package:gastegi/core/storage/database_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';

/// Recorrido completo de la app sobre un dispositivo real.
///
/// Usa una base de datos en memoria y no la del dispositivo, a propósito: una
/// prueba no debe pisar los datos de quien tenga la app instalada. Lo que
/// aporta frente a los tests de widget es el resto —motor real, tipografías
/// reales, gestos reales, teclado real—, no la persistencia en disco, que ya
/// cubren los tests de repositorio.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() => initializeDateFormatting('es'));
  setUp(() async => db = await AppDatabase.openAt(inMemoryDatabasePath));
  tearDown(() async => db.close());

  testWidgets('crear cuenta, registrar gasto y verlo reflejado', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(appDataProvider.notifier).load();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GastegiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // ── Inicio: app vacía ──────────────────────────────────────────────────
    expect(
      find.text('Todavía no has registrado ningún gasto.'),
      findsOneWidget,
    );

    // ── Crear una cuenta ───────────────────────────────────────────────────
    await tester.tap(find.text('Cuentas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('acct-name-new')),
      'Efectivo',
    );
    await tester.enterText(
      find.byKey(const ValueKey('acct-balance-new')),
      '500',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Efectivo'), findsOneWidget);

    // ── Registrar un gasto ─────────────────────────────────────────────────
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    // Hay que repintar entre pulsaciones: hasta que el importe no cambia, el
    // display sigue mostrando "0" y colisionaría con la tecla "0".
    for (final key in ['4', '0']) {
      await tester.tap(find.text(key));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    // ── Historial ──────────────────────────────────────────────────────────
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('Comida · Efectivo'), findsOneWidget);

    // ── El saldo ha bajado ─────────────────────────────────────────────────
    await tester.tap(find.text('Cuentas').last);
    await tester.pumpAndSettle();
    expect(find.text('460'), findsWidgets);

    // ── Presupuestos ───────────────────────────────────────────────────────
    await tester.tap(find.text('Presupuesto'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuestos'), findsOneWidget);
  });
}
