import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/router/app_tab_bar.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/dashboard/presentation/pages/home_page.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:gastegi/features/expenses/presentation/widgets/amount_field.dart';
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

  testWidgets('un importe del máximo de cifras no desborda ninguna pantalla', (
    tester,
  ) async {
    // La cifra más larga que admite la app —`maxIntegerDigits` enteros y dos
    // decimales— con su moneda puesta. Las pantallas que la enseñan en grande
    // la ponen al lado de otro texto, y sin encogerla el `Row` desborda con
    // las rayas amarillas.
    final accountId = await AccountRepositoryImpl(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 999999999.99,
    );
    final categoryId =
        (await db.query('categories', limit: 1)).single['id']! as String;
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Coche',
      categoryId: categoryId,
      accountId: accountId,
      amount: 123456789.89,
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
    await tester.enterText(
      find.byKey(amountFieldKey),
      '${'9' * maxIntegerDigits},99',
    );
    await tester.pumpAndSettle();
    // La cifra y el símbolo ya no son el mismo widget: el símbolo va en un
    // `Text` al lado del campo, con el espacio duro que trae el idioma.
    expect(find.text('999.999.999,99'), findsOneWidget);
    expect(find.text('\u00A0€'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // `takeException` no ve un texto encogido, así que la cifra se comprueba
    // aparte: en 390×844 la escala vale 1 y `displayXl` son 44 exactos. Que
    // haya bajado es lo que prueba la medición que sustituyó al `FittedBox`.
    final size = tester
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(amountFieldKey),
            matching: find.byType(EditableText),
          ),
        )
        .style
        .fontSize!;
    expect(size, lessThan(44), reason: 'la cifra se ha encogido');
    expect(size, greaterThanOrEqualTo(20), reason: 'sin llegar al suelo');

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

  testWidgets('el importe máximo cabe en el móvil pequeño al 1.3× de texto', (
    tester,
  ) async {
    // El peor caso del catálogo, y el que `responsive_test.dart` no ve: allí
    // nadie teclea la cifra más larga. El cuerpo del visor tiene suelo, así que
    // llega un punto en el que encoger ya no basta y lo único que evita las
    // rayas amarillas es que el campo se acote y se desplace por dentro.
    await pumpApp(tester, size: const Size(320, 568), textScale: 1.3);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(amountFieldKey),
      '${'9' * maxIntegerDigits},99',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // La tipografía de las pruebas mide cada glifo como un cuadrado, mucho más
    // ancha que la real: este es el caso en el que el suelo se toca de verdad.
    final field = tester.getRect(find.byType(AmountField));
    final editable = tester.getRect(
      find.descendant(
        of: find.byKey(amountFieldKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.left, greaterThanOrEqualTo(field.left));
    expect(editable.right, lessThanOrEqualTo(field.right));

    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });

  testWidgets('en apaisado, «Nuevo gasto» va en una sola columna', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(844, 390));

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    // Antes los campos vivían en una columna y el teclado propio en otra, a su
    // derecha. Sin teclado, todo baja en una sola columna que se desplaza.
    final amount = tester.getRect(find.byType(AmountField));
    final category = tester.getRect(find.text('Categoría'));
    expect(category.top, greaterThan(amount.bottom), reason: 'bajo el importe');
    expect(category.left, lessThan(amount.right), reason: 'misma columna');
    expect(tester.takeException(), isNull);

    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });

  // El teclado del sistema come alto, y esta pantalla está fuera del shell de
  // pestañas, así que no le vale el ajuste que esconde la barra: lo único que
  // la salva es que la columna se desplace.
  for (final (nombre, size) in const <(String, Size)>[
    ('en vertical', Size(390, 844)),
    ('en apaisado', Size(844, 390)),
  ]) {
    testWidgets(
      'con el teclado del sistema puesto se llega a Guardar, $nombre',
      (tester) async {
        await pumpApp(tester, size: size);

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();

        const teclado = 200.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: teclado * 3);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Guardar gasto'));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.text('Guardar gasto')).bottom,
          lessThanOrEqualTo(size.height - teclado),
          reason: 'por encima del teclado',
        );
        expect(tester.takeException(), isNull);

        tester.view.viewInsets = FakeViewPadding.zero;
        appRouter.go(RouteNames.home);
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('el campo del importe arranca enfocado', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    // El teclado del sistema sube al abrir: teclear el importe es lo primero
    // que se hace aquí, y esperar un toque más sería un gesto de más.
    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(amountFieldKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.focusNode.hasFocus, isTrue);

    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });

  testWidgets('el teclado del sistema oculta la barra de pestañas', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(AppTabBar), findsOneWidget);

    // Lo que hace el sistema al abrir su teclado. El `Scaffold` encoge el
    // cuerpo hasta el borde del teclado, y con la barra puesta al formulario
    // de la cuenta no le quedaba sitio ni para el botón de guardar.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    await tester.pumpAndSettle();
    expect(find.byType(AppTabBar), findsNothing);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(find.byType(AppTabBar), findsOneWidget);
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

    await tester.enterText(find.byKey(amountFieldKey), '50');
    await tester.pumpAndSettle();
    // Hay que repintar entre pulsaciones para que los chips reaccionen.
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

    // Y el formulario vuelve limpio. El controlador del campo no se entera solo
    // de que `save()` ha vaciado el estado: sin la sincronización, al volver
    // aquí seguiría escrito el importe del gasto anterior.
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('50'), findsNothing);
    expect(find.text('0'), findsOneWidget, reason: 'el cero de la pista');

    appRouter.go(RouteNames.home);
    await tester.pumpAndSettle();
  });
}
