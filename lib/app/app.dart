import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/app/router/app_router.dart';
import 'package:gastegi/app/theme/app_theme.dart';

/// Widget raíz de la aplicación.
class GastegiApp extends StatelessWidget {
  const GastegiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.title,
      debugShowCheckedModeBanner: false,
      locale: AppConfig.defaultLocale,
      supportedLocales: AppConfig.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
