import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/theme/app_theme.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';

/// Widget raíz de la aplicación.
class GastegiApp extends StatelessWidget {
  const GastegiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
    );
  }
}
