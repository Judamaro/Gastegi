import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db.dart';

/// Recorrido completo de la app en cada resolución y escala de texto.
///
/// Ojo con lo que prueba y lo que no: `takeException()` detecta un
/// `RenderFlex` desbordado, pero **no** que un texto se haya elidido, lo haya
/// encogido un `FittedBox` o lo haya recortado un `Stack`. Esta app está llena
/// de las tres cosas a propósito, así que la matriz sola puede salir verde con
/// la interfaz estropeada; las aserciones de tamaño concretas viven en
/// `widget_test.dart` (rotación, tableta, apaisado) y en `screen_scale_test.dart`.
void main() {
  setUpAll(() async {
    await initTestLocale();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  const sizes = <(String, Size)>[
    ('móvil pequeño', Size(320, 568)),
    ('marco del diseño', Size(390, 844)),
    ('móvil grande', Size(430, 932)),
    ('apaisado', Size(844, 390)),
    ('tableta', Size(768, 1024)),
  ];

  // 1.0 y el tope que aplica la app. El par más exigente no es la tableta sino
  // el móvil pequeño a 1.3: los componentes van al 0.82 y el texto al 1.07, o
  // sea que la proporción entre texto y caja crece un 30 % sobre el diseño.
  const textScales = <double>[1, 1.3];

  for (final (nombre, size) in sizes) {
    for (final textScale in textScales) {
      testWidgets('$nombre con texto al $textScale× no desborda', (
        tester,
      ) async {
        // Datos de verdad en todas las pantallas, y con la cifra más larga
        // que admite la app: sin ellos, media interfaz no llega a pintarse.
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

        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

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
        expect(tester.takeException(), isNull, reason: 'Inicio');

        for (final tab in ['Historial', 'Presupuesto', 'Cuentas']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }

        await tester.tap(find.text('Agregar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Nuevo gasto');

        // El detalle de una categoría solo se alcanza desde la leyenda de la
        // dona, así que se entra por la ruta.
        appRouter.go(RouteNames.categoryDetailOf('Transporte'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Detalle de categoría');

        // `appRouter` es global y conserva la ruta entre tests: sin volver a
        // una pestaña, el siguiente arrancaría fuera del shell.
        appRouter.go(RouteNames.home);
        await tester.pumpAndSettle();
      });
    }
  }
}
