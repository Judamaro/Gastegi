import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/data/account_repository.dart';
import 'package:gastegi/state/app_state.dart';
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

  // Viewport de teléfono (390×844), como el marco iOS del diseño.
  Future<AppState> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = await buildState(db);
    await tester.pumpWidget(GastegiApp(state: state));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('la app arranca vacía y sin excepciones', (tester) async {
    await pumpApp(tester);

    expect(find.text('Agosto 2026'.toUpperCase()), findsOneWidget);
    expect(find.text('gastado este mes'), findsOneWidget);
    expect(find.text('Todavía no has registrado ningún gasto.'), findsOneWidget);
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

  testWidgets('crear una cuenta la refleja en el saldo total', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Cuentas').last);
    await tester.pumpAndSettle();
    expect(find.text('Sin cuentas'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('acct-name-new')), 'Efectivo');
    await tester.enterText(find.byKey(const ValueKey('acct-balance-new')), '480');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('480'), findsWidgets);
    expect(find.text('Efectivo'), findsOneWidget);
  });

  testWidgets('el gasto se guarda, aparece bajo HOY y baja el saldo',
      (tester) async {
    await AccountRepository(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 200,
    );
    final state = await pumpApp(tester);

    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo gasto'), findsOneWidget);

    // Hay que repintar entre pulsaciones: hasta que el importe no cambia, el
    // display sigue mostrando "0" y colisionaría con la tecla "0".
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
    expect(state.patrimonio, 150);
  });
}
