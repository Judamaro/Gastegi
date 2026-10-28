/// Errores **técnicos**: algo ha fallado por debajo del dominio (el esquema, el
/// disco, la red futura). No son mensajes para el usuario.
///
/// Lo que el dominio sí entiende —"ese nombre de cuenta ya existe"— vive en
/// `failures.dart` y no hereda de aquí.
library;

/// El esquema de la BD pide subir a una versión para la que no hay migración
/// registrada. Solo puede pasar por un error de programación: alguien subió
/// `AppDatabase.schemaVersion` sin añadir el paso correspondiente.
class MissingMigrationException implements Exception {
  const MissingMigrationException(this.version);

  final int version;

  @override
  String toString() =>
      'MissingMigrationException: falta la migración a la versión $version '
      'del esquema';
}
