import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_db.dart';

/// La escala de pantalla, medida sobre la configuración real de [GastegiApp].
///
/// Monta la app entera a propósito, en vez de un `ScreenUtilPlusInit` de
/// mentira: lo que se comprueba aquí es lo que hay escrito en `app.dart`, y una
/// copia de la configuración en el test no detectaría que alguien la cambia.
void main() {
  setUpAll(() async {
    await initTestLocale();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late Database db;

  setUp(() async => db = await openTestDb());
  tearDown(() async => db.close());

  /// Factores esperados para el lienzo de 390×844, con `splitScreenMode`
  /// (la escala de alto usa `max(alto, 700)`) y `FontSizeResolvers.radius`
  /// (min de las dos escalas).
  const cases = <(String, Size, double)>[
    // 320/390 = 0.8205 frente a 700/844 = 0.8294.
    ('móvil pequeño', Size(320, 568), 0.8205),
    ('marco del diseño', Size(390, 844), 1),
    // 430/390 = 1.1026 frente a 932/844 = 1.1043.
    ('móvil grande', Size(430, 932), 1.1026),
    // El ancho daría 2.1641: en apaisado manda el alto acotado a 700.
    ('apaisado', Size(844, 390), 0.8294),
    // 768/390 = 1.9692 frente a 1024/844 = 1.2133.
    ('tableta', Size(768, 1024), 1.2133),
  ];

  for (final (nombre, size, factor) in cases) {
    testWidgets('la escala en $nombre es $factor', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final container = await buildLoadedContainer(db);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GastegiApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(10.r, closeTo(10 * factor, 0.01), reason: 'componentes');
      expect(10.sp, closeTo(10 * factor, 0.01), reason: 'fuentes');
    });
  }

  testWidgets('las fuentes escalan igual que los componentes', (tester) async {
    // La aserción que sostiene toda la política: sin
    // `fontSizeResolver: FontSizeResolvers.radius`, `.sp` escala solo por ancho
    // y en apaisado devuelve 21.6 donde `.r` devuelve 8.3 — tipografía gigante
    // sobre componentes encogidos, sin que falle nada más.
    tester.view.physicalSize = const Size(844 * 3, 390 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = await buildLoadedContainer(db);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const GastegiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(44.sp, closeTo(44.r, 0.001));
    expect(10.sp, closeTo(10.r, 0.001));
  });
}
