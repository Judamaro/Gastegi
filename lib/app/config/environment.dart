/// Entorno en el que corre la app.
///
/// Se fija en tiempo de compilación con `--dart-define=APP_ENV=…`, no desde un
/// fichero leído en runtime: así el valor no viaja dentro del bundle como un
/// asset que cualquiera puede abrir, y una compilación de producción no puede
/// arrancar creyéndose de desarrollo.
enum Environment {
  development,
  staging,
  production;

  static const String _key = 'APP_ENV';

  /// El entorno de esta compilación. Sin `--dart-define`, desarrollo.
  static final Environment current = _parse(
    const String.fromEnvironment(_key, defaultValue: 'development'),
  );

  static Environment _parse(String value) => switch (value) {
    'production' => Environment.production,
    'staging' => Environment.staging,
    _ => Environment.development,
  };
}
