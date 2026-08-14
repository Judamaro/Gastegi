import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/app/router/app_shell.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/app/theme/app_theme.dart';

/// Widget raíz de la aplicación.
class GastegiApp extends StatelessWidget {
  const GastegiApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.title,
      debugShowCheckedModeBanner: false,
      locale: AppConfig.defaultLocale,
      supportedLocales: AppConfig.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.dark,
      home: Shell(state: state),
    );
  }
}
