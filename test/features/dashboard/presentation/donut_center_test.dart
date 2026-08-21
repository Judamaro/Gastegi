import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_db.dart';

/// Geometría del centro de la dona.
///
/// El anillo lo pinta `fl_chart` sobre un lienzo propio, así que un texto que
/// se le monte encima no lanza nada: no hay `RenderFlex` que desborde ni
/// excepción que recoger. Se comprueba con la circunferencia en la mano.
///
/// Ya no se puede montar la dona suelta a un diámetro cualquiera: lo decide el
/// `LayoutBuilder` de Inicio con `min(128.r, anchoDeLaFila · 0.4)`. Lo que
/// hace variar el diámetro es la resolución, así que se recorre el mismo
/// catálogo de pantallas que `responsive_test.dart`.
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

  /// Siembra un gasto —sin él Inicio saca la pantalla vacía— y monta la app.
  Future<void> pumpHome(
    WidgetTester tester, {
    required Size size,
    required double textScale,
  }) async {
    final accountId = await AccountRepositoryImpl(db).create(
      name: 'Efectivo',
      kind: 'Dinero en mano',
      iconKey: 'money',
      initialBalance: 1000000,
    );
    final categoryId =
        (await db.query('categories', limit: 1)).single['id']! as String;
    await ExpenseRepositoryImpl(db).create(
      date: testNow,
      description: 'Compra',
      categoryId: categoryId,
      accountId: accountId,
      // La cifra larga es la que aprieta el hueco: con seis dígitos y
      // decimales, el importe llega al anillo si el ancho está mal medido.
      amount: 250000,
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
  }

  for (final (nombre, size) in sizes) {
    // El centro va con `TextScaler.noScaling` a propósito —el hueco es
    // geométrico—, así que el ajuste del sistema no debe moverlo ni al máximo
    // que la app permite.
    for (final textScale in <double>[1, 1.3]) {
      testWidgets('en $nombre a $textScale× el texto cabe en el hueco', (
        tester,
      ) async {
        await pumpHome(tester, size: size, textScale: textScale);

        final donut = tester.getRect(find.byType(PieChart));
        final center = donut.center;
        // Radio interior del anillo: medio diámetro menos el grosor del trazo.
        // El literal va a mano a propósito: si se leyera de `_CategoryDonut`,
        // el día que el trazo cambie el test se movería con él y no
        // comprobaría nada.
        final holeRadius = donut.width * (0.5 - 0.0625);

        // El importe sale tres veces en Inicio —titular, centro y leyenda—,
        // así que hay que acotarlo al `Stack` que envuelve al anillo.
        final centro = find
            .ancestor(of: find.byType(PieChart), matching: find.byType(Stack))
            .first;

        for (final texto in ['250.000,00 €', 'este mes']) {
          final rect = tester.getRect(
            find.descendant(of: centro, matching: find.text(texto)),
          );
          for (final corner in [
            rect.topLeft,
            rect.topRight,
            rect.bottomLeft,
            rect.bottomRight,
          ]) {
            expect(
              (corner - center).distance,
              lessThanOrEqualTo(holeRadius),
              reason:
                  'la esquina $corner de «$texto» se sale del hueco '
                  '(radio $holeRadius, centro $center)',
            );
          }
        }
      });
    }
  }

  testWidgets('el anillo llena su caja', (tester) async {
    await pumpHome(tester, size: const Size(390, 844), textScale: 1);
    // El SVG del diseño traía 15 % de margen dentro del propio dibujo, que
    // dejaba la dona flotando en una caja más grande que ella. En el marco del
    // diseño la escala vale 1 y la fila deja sitio de sobra, así que la dona
    // sale a su tope.
    expect(tester.getRect(find.byType(PieChart)).width, 128);
  });
}
