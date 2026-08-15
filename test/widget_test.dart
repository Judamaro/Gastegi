import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/dashboard/presentation/pages/home_page.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db.dart';

void main() {
  setUpAll(() async {
    await initTestLocale();
    // Sin esto, google_fonts intenta descargar la tipografía por red en cada
    // test: peticiones que nunca resuelven y `pumpAndSettle` que no termina.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  /// Monta la app en un viewport concreto.
  ///
  /// Por defecto, el teléfono de 390×844 del marco iOS del diseño, donde la
  /// escala vale 1 y las medidas coinciden con las escritas en el código.
  /// [textScale] es el ajuste de tamaño de letra del sistema, que la app acota
  /// a 1.3× por su cuenta.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // Sin esto la app arrancaría en inglés: el dispositivo de prueba dice
    // en_US y ya no hay un `locale` fijo en MaterialApp.
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final container = await buildLoadedContainer(db);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GastegiApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('la app arranca vacía y sin excepciones', (tester) async {
    await pumpApp(tester);

    expect(find.text('Agosto 2026'.toUpperCase()), findsOneWidget);
    expect(find.text('gastado este mes'), findsOneWidget);
    expect(
      find.text('Todavía no has registrado ningún gasto.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la navegación por pestañas cambia de pantalla', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Buscar gasto…'), findsOneWidget);
    expect(find.text('Todavía no hay gastos registrados'), findsOneWidget);

    await tester.tap(find.text('Presupuesto'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuestos'), findsOneWidget);

    await tester.tap(find.text('Cuentas').last);
    await tester.pumpAndSettle();
    expect(find.text('Saldo total'.toUpperCase()), findsOneWidget);
  });

  testWidgets('un importe de siete cifras no desborda ninguna pantalla', (
    tester,
  ) async {
    // Con moneda y dos decimales, la cifra más larga pasa de nueve caracteres
    // a dieciocho. Las pantallas que la enseñan en grande la ponen al lado de
    // otro texto, y sin encogerla el `Row` desborda con las rayas amarillas.
    final accountId = await AccountRepositoryImpl(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 9999999.99,
    );
    final categoryId =
        (await db.query('categories', limit: 1)).single['id']! as String;
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Coche',
      categoryId: categoryId,
      accountId: accountId,
      amount: 1234567.89,
    );

    await pumpApp(tester);
    // Inicio: total del mes, dona y leyenda por categoría.
    expect(tester.takeException(), isNull);

    for (final tab in ['Historial', 'Presupuesto', 'Cuentas']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    for (final key in ['9', '9', '9', '9', '9', '9', '9', ',', '9', '9']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    expect(find.text('9.999.999,99\u00A0€'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // `appRouter` es una instancia global y conserva la ruta entre tests: sin
    // volver a una pestaña, el siguiente arranca en /add y no encuentra la
    // barra de navegación.
    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });

  testWidgets('girar la pantalla reescala la interfaz', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Presupuesto'));
    await tester.pumpAndSettle();

    double titleSize() =>
        tester.widget<Text>(find.text('Presupuestos')).style!.fontSize!;
    expect(titleSize(), closeTo(20, 0.01));

    tester.view.physicalSize = const Size(844 * 3, 390 * 3);
    await tester.pumpAndSettle();

    // 20 × min(844/390, 700/844) = 16.59. Si sale 20, la pantalla no se ha
    // reconstruido y arrastra la escala del retrato: es lo que pasa sin la
    // llamada a `watchScreen`, porque go_router cachea el Navigator de cada
    // rama del shell y solo lo rehace si cambia la ruta.
    expect(titleSize(), closeTo(16.59, 0.05));

    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });

  testWidgets('en tableta el contenido se acota y se centra', (tester) async {
    await pumpApp(tester, size: const Size(768, 1024));

    // Sin tope, Inicio ocuparía los 768 dp de ancho y las líneas de texto
    // saldrían ilegibles de tan largas.
    final home = tester.getRect(find.byType(HomePage));
    expect(home.width, 600);
    expect(home.center.dx, closeTo(384, 0.01), reason: 'centrado');
  });

  testWidgets('crear una cuenta la refleja en el saldo total', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Cuentas').last);
    await tester.pumpAndSettle();
    expect(find.text('Sin cuentas'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('acct-name-new')),
      'Efectivo',
    );
    await tester.enterText(
      find.byKey(const ValueKey('acct-balance-new')),
      '480',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // Con la secuencia de escape a propósito: el espacio antes del símbolo es
    // duro (U+00A0), y escrito a mano no coincidiría.
    expect(find.text('480,00\u00A0€'), findsWidgets);
    expect(find.text('Efectivo'), findsOneWidget);
  });

  testWidgets('el gasto se guarda, aparece bajo HOY y baja el saldo', (
    tester,
  ) async {
    await AccountRepositoryImpl(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 200,
    );
    final container = await pumpApp(tester);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);

    // Hay que repintar entre pulsaciones para que los chips reaccionen. El
    // display ya no colisiona con la tecla "0": lleva el símbolo puesto.
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar gasto'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar gasto…'), findsOneWidget);
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('Comida · Efectivo'), findsOneWidget);
    expect(container.read(appDataProvider).patrimonio, 150);
  });
}
