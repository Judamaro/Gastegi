import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/config/app_config.dart';
import 'package:gastegi/app/state/app_data_notifier.dart';
import 'package:gastegi/core/storage/app_database.dart';
import 'package:gastegi/core/storage/database_provider.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Punto de composición: abre la base de datos, monta el ámbito de providers
/// con ella dentro y carga los datos antes del primer frame.
///
/// Cargar aquí —y no en el primer `build`— es lo que permite que las pantallas
/// lean datos de forma síncrona, sin `FutureBuilder` ni estados de carga.
Future<ProviderContainer> bootstrap() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Publica el árbol de semántica desde el arranque (accesibilidad en web).
  binding.ensureSemantics();

  // `DateFormat` con un locale distinto de en_US lanza LocaleDataException si
  // no se inicializan antes los datos del idioma. Se cargan todos los
  // soportados porque el usuario puede cambiar el del sistema con la app viva.
  for (final locale in AppLocalizations.supportedLocales) {
    await initializeDateFormatting(locale.languageCode);
  }
  Intl.defaultLocale = AppConfig.fallbackLocale.languageCode;

  final db = await AppDatabase.open();
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  await container.read(appDataProvider.notifier).load();

  return container;
}
