import 'package:flutter_riverpod/flutter_riverpod.dart';

/// De dónde sale "ahora".
///
/// Existe para que los tests puedan congelar el día: sin esto, los rangos
/// "últimos 7/15 días" y la longitud de `dailyCatTotals` dependerían de la fecha
/// real y las pruebas fallarían a ratos.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
