import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('es');

/// Redondea a entero y aplica separador de miles es-ES.
String formatAmount(double n) => _decimal.format(n.round());

/// Porcentaje entero de [part] sobre [whole]; 0 si [whole] no es positivo.
///
/// Sin esta guarda, una app recién instalada calcula `0 / 0` y el
/// `double.nan.round()` resultante lanza `UnsupportedError`.
int percentOf(double part, double whole) =>
    whole > 0 ? (part / whole * 100).round() : 0;

/// Lee un importe tecleado por el usuario. La coma es el separador decimal en
/// español; `double.tryParse` solo entiende el punto.
double parseAmount(String raw) =>
    double.tryParse(raw.replaceAll(',', '.')) ?? 0;

/// Importe sin separadores de miles, para prellenar un campo editable: lo que
/// se escribe en un campo tiene que poder volver a leerse con [parseAmount].
String plainAmount(double n) =>
    n == n.roundToDouble() ? n.round().toString() : n.toString();
