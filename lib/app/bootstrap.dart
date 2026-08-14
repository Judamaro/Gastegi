import 'package:flutter/widgets.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/data/account_repository.dart';
import 'package:gastegi/data/app_database.dart';
import 'package:gastegi/data/category_repository.dart';
import 'package:gastegi/data/expense_repository.dart';
import 'package:gastegi/state/app_state.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Punto de composición: aquí —y solo aquí— se construyen las dependencias
/// concretas de la aplicación y se cablean entre sí.
Future<AppState> bootstrap() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Publica el árbol de semántica desde el arranque (accesibilidad en web).
  binding.ensureSemantics();

  // `DateFormat` con un locale distinto de en_US lanza LocaleDataException si
  // no se inicializan antes los datos del idioma.
  final locale = AppConfig.defaultLocale.languageCode;
  await initializeDateFormatting(locale);
  Intl.defaultLocale = locale;

  final db = await AppDatabase.open();
  final state = AppState(
    categoryRepo: CategoryRepository(db),
    accountRepo: AccountRepository(db),
    expenseRepo: ExpenseRepository(db),
  );
  await state.load();

  return state;
}
