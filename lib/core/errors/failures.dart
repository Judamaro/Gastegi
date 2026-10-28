/// Fallos que el **dominio** entiende: "ese nombre ya está cogido", no "la
/// conexión se cayó".
///
/// Son valores, no excepciones: se devuelven, no se lanzan. Así el compilador
/// obliga a tratarlos y la presentación decide qué texto mostrar —lo que hace
/// posible traducirlos sin tocar el dominio.
///
/// Los errores técnicos viven en `exceptions.dart` y sí se lanzan.
abstract class Failure {
  const Failure();
}
