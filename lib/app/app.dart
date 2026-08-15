import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/theme/app_theme.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Widget raíz de la aplicación.
class GastegiApp extends StatelessWidget {
  const GastegiApp({super.key});

  /// Lienzo del diseño. Todas las medidas escritas en el código son dp de este
  /// marco; el paquete las reescala al dispositivo real.
  static const Size _designSize = Size(390, 844);

  /// Tope de la escala de texto del sistema.
  ///
  /// La preferencia de accesibilidad se respeta, pero por encima de 1.3 las
  /// cifras grandes de Inicio y las teclas del importe dejan de caber aunque
  /// encojan: el `FittedBox` las reduciría hasta lo ilegible.
  static const double _maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    // `builder` y no `child`: pasar el `MaterialApp` por `child` devolvería
    // siempre la misma instancia y el árbol no se rehace al cambiar la escala.
    return ScreenUtilPlusInit(
      designSize: _designSize,
      // Acota la escala de alto a un mínimo de 700 dp. Sin esto, en apaisado
      // (844×390) la escala caería a 390/844 = 0.46 y la app saldría en
      // miniatura. Parece decorativo y es estructural.
      splitScreenMode: true,
      // `minTextAdapt` no sirve aquí: `setSp` es
      // `fontSizeResolver?.call(…) ?? fontSize * scaleText`, y el paquete pasa
      // siempre un resolver, así que la rama que consulta `minTextAdapt` no se
      // alcanza jamás. El resolver por defecto escala solo por ancho —2.16× en
      // apaisado, la cifra de 44 a 95 pt sobre componentes al 0.83—; `radius`
      // es el que usa min(ancho, alto), el mismo factor que `.r`, de modo que
      // texto y componentes crecen a la vez. Lo vigila
      // `test/app/screen_scale_test.dart`.
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp.router(
        title: AppConfig.title,
        debugShowCheckedModeBanner: false,
        // Sin `locale` fijo: manda el idioma del sistema, y si no está entre los
        // soportados, Flutter cae al primero de la lista.
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: AppTheme.dark,
        routerConfig: appRouter,
        // Por encima del `Navigator`, para que el tope alcance también a lo que
        // se abre sobre él: el selector de fecha de «Nuevo gasto».
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: _maxTextScale,
          child: child!,
        ),
      ),
    );
  }
}
