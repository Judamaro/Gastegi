import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/core/utils/text_measure.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/categories/presentation/pages/category_detail_page.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

/// Lo que las gráficas de `fl_chart` no avisan por su cuenta.
///
/// Las tres cosas que aquí se comprueban las garantizaba antes la aritmética de
/// un `CustomPainter`, y ninguna de las tres lanza nada al romperse:
/// `reservedSize` recorta la etiqueta en silencio, una barra de valor cero
/// sencillamente no se dibuja, y un callback táctil que se salga de rango solo
/// falla cuando alguien toca.
void main() {
  setUpAll(() async {
    await initTestLocale();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async {
    // `appRouter` es global y conserva la ruta entre tests.
    appRouter.go(RouteNames.home);
    await db.close();
  });

  /// Siembra un gasto en el mes en curso y monta la app en Inicio.
  ///
  /// Devuelve el nombre de la categoría del gasto, que es la única con importe
  /// y por tanto el único sector de la dona.
  Future<String> pumpHome(WidgetTester tester, {double textScale = 1}) async {
    final accountId = await AccountRepositoryImpl(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 1000,
    );
    final categoria = (await db.query('categories', limit: 1)).single;
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Compra',
      categoryId: categoria['id']! as String,
      accountId: accountId,
      amount: 250,
    );

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
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
    return categoria['name']! as String;
  }

  /// La gráfica de los últimos seis meses. `MeterBar` también es un `BarChart`,
  /// así que se distingue por el número de grupos.
  Finder findMonthBars() => find.byWidgetPredicate(
    (w) => w is BarChart && w.data.barGroups.length == 6,
  );

  for (final textScale in <double>[1, 1.3]) {
    testWidgets('a $textScale× la etiqueta del mes cabe en su banda', (
      tester,
    ) async {
      await pumpHome(tester, textScale: textScale);

      final barras = findMonthBars();
      final chart = tester.widget<BarChart>(barras);
      final reservado =
          chart.data.titlesData.bottomTitles.sideTitles.reservedSize;

      // `SideTitles` mide al hijo con un `tightFor(height: reservedSize)`: si
      // el texto escalado pide más, se recorta sin lanzar nada que
      // `takeException()` pueda ver.
      final etiqueta = find.descendant(of: barras, matching: find.text('Ago'));
      final texto = tester.widget<Text>(etiqueta);
      final elemento = tester.element(etiqueta);
      final alto = textHeight(
        'Ago',
        style: DefaultTextStyle.of(elemento).style.merge(texto.style),
        scaler: MediaQuery.textScalerOf(elemento),
        direction: TextDirection.ltr,
      );

      expect(
        reservado,
        greaterThanOrEqualTo(alto),
        reason: 'la banda de la etiqueta se queda corta a $textScale×',
      );
    });
  }

  testWidgets('un mes sin gastos conserva su barra', (tester) async {
    await pumpHome(tester);

    // Solo hay gasto en el mes en curso: los cinco anteriores están a cero.
    // `fl_chart` no dibuja una barra con `toY == fromY`, así que sin el suelo
    // la gráfica saldría con una sola barra y ningún test lo notaría.
    final chart = tester.widget<BarChart>(findMonthBars());
    final alturas = [
      for (final grupo in chart.data.barGroups) grupo.barRods.single.toY,
    ];

    expect(alturas, hasLength(6));
    expect(
      alturas.every((y) => y > 0),
      isTrue,
      reason: 'una barra a cero desaparece: $alturas',
    );
  });

  testWidgets('tocar un sector de la dona abre el detalle', (tester) async {
    final categoria = await pumpHome(tester);

    final dona = tester.getRect(find.byType(PieChart));
    // A las doce en punto, sobre la línea media del anillo. Con una sola
    // categoría con gasto, el anillo entero es su sector.
    final centro = dona.center;
    final punto = Offset(centro.dx, centro.dy - dona.width * 0.46875);

    await tester.tapAt(punto);
    await tester.pumpAndSettle();

    expect(find.byType(CategoryDetailPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CategoryDetailPage),
        matching: find.text(categoria),
      ),
      findsWidgets,
    );
  });

  testWidgets('tocar una barra no revienta el globo', (tester) async {
    await pumpHome(tester);

    // `getTooltipItem` indexa la lista de barras por el índice del grupo, y se
    // ejecuta al pintar el globo: un desfase solo falla cuando alguien toca.
    final barras = tester.getRect(findMonthBars());
    final ancho = barras.width / 6;
    for (var i = 0; i < 6; i++) {
      await tester.tapAt(
        Offset(
          barras.left + ancho * (i + 0.5),
          barras.bottom - barras.height * 0.2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'barra $i');
    }
  });
}
