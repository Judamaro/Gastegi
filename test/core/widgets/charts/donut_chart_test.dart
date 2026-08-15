import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/core/widgets/charts/donut_chart.dart';

/// Geometría del centro de la dona.
///
/// El anillo se pinta en un `CustomPaint`, así que un texto que se le monte
/// encima no lanza nada: no hay `RenderFlex` que desborde ni excepción que
/// recoger. Se comprueba con la circunferencia en la mano.
void main() {
  const title = '250.000,00 €';
  const subtitle = 'este mes';

  Future<void> pumpDonut(WidgetTester tester, {required double size}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: DonutChart(
              segments: const [(1, Color(0xFF8B7CF6))],
              centerTitle: title,
              centerSubtitle: subtitle,
              size: size,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in <double>[96, 128, 200]) {
    testWidgets('con diámetro $size el texto cabe en el hueco', (tester) async {
      await pumpDonut(tester, size: size);

      final donut = tester.getRect(find.byType(DonutChart));
      final center = donut.center;
      // Radio interior del anillo: medio diámetro menos el grosor del trazo.
      final holeRadius = donut.width * (0.5 - 0.125);

      for (final texto in [title, subtitle]) {
        final rect = tester.getRect(find.text(texto));
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

  testWidgets('el anillo llena su caja', (tester) async {
    await pumpDonut(tester, size: 128);
    // El SVG del diseño traía 15 % de margen dentro del propio dibujo, que
    // dejaba la dona flotando en una caja más grande que ella.
    expect(tester.getRect(find.byType(DonutChart)).width, 128);
  });
}
