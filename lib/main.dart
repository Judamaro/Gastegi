import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'data/account_repository.dart';
import 'data/app_database.dart';
import 'data/category_repository.dart';
import 'data/expense_repository.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/nocturne.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Publica el árbol de semántica desde el arranque (accesibilidad en web).
  binding.ensureSemantics();

  // `DateFormat` con un locale distinto de en_US lanza LocaleDataException si
  // no se inicializan antes los datos del idioma.
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';

  final db = await AppDatabase.open();
  final state = AppState(
    categoryRepo: CategoryRepository(db),
    accountRepo: AccountRepository(db),
    expenseRepo: ExpenseRepository(db),
  );
  await state.load();

  runApp(GastegiApp(state: state));
}

class GastegiApp extends StatelessWidget {
  const GastegiApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Nocturne.bg,
      colorScheme: const ColorScheme.dark(
        primary: Nocturne.accent,
        surface: Nocturne.surface,
        onSurface: Nocturne.text,
      ),
      splashFactory: NoSplash.splashFactory,
    );
    return MaterialApp(
      title: 'Gastegi',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
          bodyColor: Nocturne.text,
          displayColor: Nocturne.text,
        ),
      ),
      home: Shell(state: state),
    );
  }
}
