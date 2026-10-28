/// Utilidades de fecha de la app.
///
/// Dos reglas que se respetan en todo el archivo:
///
/// * Las fechas de gasto son **días naturales locales**, sin hora. Se guardan
///   como texto `YYYY-MM-DD`, que es ordenable, agrupable con `substr()` y no
///   se desplaza de día al cambiar de zona horaria.
/// * La aritmética de "hace N días" usa el constructor `DateTime(y, m, d - n)`
///   y nunca `Duration(days: n)`: con horario de verano, un `Duration` de 7
///   días puede caer a las 23:00 del día anterior.
library;

import 'package:intl/intl.dart';

/// Clave de día para la BD: `2026-08-12`.
String dayKey(DateTime d) => _dayFormat.format(d);

/// Clave de mes para agrupar totales: `2026-08`.
String monthKey(DateTime d) => _monthKeyFormat.format(d);

/// Medianoche local del día de [d].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Primer día del mes de [d], a medianoche.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

/// Desplaza [m] en [n] meses. `DateTime` normaliza el desbordamiento, así que
/// mes 13 pasa a enero del año siguiente y mes 0 a diciembre del anterior.
DateTime addMonths(DateTime m, int n) => DateTime(m.year, m.month + n);

/// Días que tiene el mes de [m]: el día 0 del mes siguiente es el último de este.
int daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

/// Fecha [days] días antes de [d], a medianoche.
DateTime daysBefore(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day - days);

/// La menor de las dos fechas.
DateTime earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

// Los formatos de clave son fijos y no dependen del idioma: `2026-08-12` es
// ordenable, agrupable con `substr()` y lo que espera la base de datos. Las
// etiquetas que sí ve el usuario viven en `date_labels.dart`.
final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
