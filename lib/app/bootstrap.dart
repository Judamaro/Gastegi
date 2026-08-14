import 'package:flutter/widgets.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/app/state/app_state.dart';
import 'package:gastegi/core/storage/app_database.dart';
import 'package:gastegi/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:gastegi/features/categories/data/repositories/category_repository_impl.dart';
import 'package:gastegi/features/expenses/data/repositories/expense_repository_impl.dart';
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
    categoryRepo: CategoryRepositoryImpl(db),
    accountRepo: AccountRepositoryImpl(db),
    expenseRepo: ExpenseRepositoryImpl(db),
  );
  await state.load();

  return state;
}
