import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/storage/app_database.dart';
import 'package:gastegi/core/storage/database_provider.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/widgets/amount_field.dart';
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

  setUpAll(() async {
    await initializeDateFormatting('es');
    // `openAt` se salta `AppDatabase.open`, que es quien registra el motor de
    // escritorio: sin esto, la prueba solo arranca en móvil.
    AppDatabase.ensureFactory();
  });
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

    await tester.enterText(find.byKey(amountFieldKey), '40');
    await tester.pumpAndSettle();
    // Hay que repintar entre pulsaciones para que los chips reaccionen.
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
    // Con la secuencia de escape a propósito: el espacio antes del símbolo
    // es duro (U+00A0), y escrito a mano no coincidiría.
    expect(find.text('460,00\u00A0€'), findsWidgets);

    // ── Presupuestos ───────────────────────────────────────────────────────
    await tester.tap(find.text('Presupuesto'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuestos'), findsOneWidget);

    // Se vuelve a Inicio porque `appRouter` es una instancia global y conserva
    // la ruta entre tests: el siguiente arrancaría donde acabó este.
    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'un importe del máximo de cifras no desborda con la tipografía real',
    (tester) async {
      // El mismo caso está cubierto en `test/widget_test.dart`, pero allí el
      // entorno de pruebas usa una tipografía de ancho fijo que mide muy distinto
      // de la real. Esta es la única comprobación del ancho de verdad.
      //
      // Y con el viewport de teléfono (390×844): la ventana del escritorio es
      // mucho más ancha, y ahí no cabría nada mal.
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      tester.platformDispatcher.localesTestValue = const [Locale('es')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      final accountId = await AccountRepositoryImpl(db).create(
        name: 'Cuenta corriente',
        kind: 'Banco',
        iconKey: 'bank',
        initialBalance: 999999999.99,
      );
      final categoryId =
          (await db.query('categories', limit: 1)).single['id']! as String;
      await ExpenseRepositoryImpl(db).create(
        date: DateTime.now(),
        description: 'Coche',
        categoryId: categoryId,
        accountId: accountId,
        amount: 1234567.89,
      );

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

      // Inicio: total del mes, centro de la dona y leyenda por categoría.
      expect(find.text('1.234.567,89\u00A0€'), findsWidgets);
      expect(tester.takeException(), isNull);

      for (final tab in ['Historial', 'Presupuesto', 'Cuentas']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      // El saldo de la cuenta: 999.999.999,99 menos el gasto de 1.234.567,89.
      // La aserción llevaba tres dígitos de menos y no casaba nunca, porque
      // `find.text` compara la cadena entera.
      expect(find.text('998.765.432,10\u00A0€'), findsWidgets);

      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(amountFieldKey), '9999999,99');
      await tester.pumpAndSettle();
      // La cifra y el símbolo son widgets distintos: el símbolo va en un `Text`
      // al lado del campo.
      expect(find.text('9.999.999,99'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Lo que de verdad se prueba aquí: que la medición con la tipografía real
      // deje la cifra dentro del ancho de la pantalla.
      expect(
        tester.getRect(find.byType(AmountField)).width,
        lessThanOrEqualTo(390),
      );

      appRouter.go(RouteNames.home);
      await tester.pumpAndSettle();
    },
  );
}
