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

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// `Agosto 2026`.
String monthTitle(DateTime m) => _capitalize(_monthYearFormat.format(m));

/// `Agosto`.
String monthName(DateTime m) => _capitalize(_monthFormat.format(m));

/// `Ago` — para las etiquetas de las barras de 6 meses.
///
/// No usa `DateFormat('MMM')`: en español CLDR devuelve `ago.` y `sept.`, con
/// punto y hasta 4 letras, que desbordan las etiquetas estrechas del diseño.
String monthAbbr(DateTime m) => _abbrs[m.month - 1];

/// Cabecera de grupo del historial: `Hoy`, `Ayer` o `12 de agosto`.
String dayLabel(DateTime d, DateTime today) {
  if (sameDay(d, today)) return 'Hoy';
  if (sameDay(d, daysBefore(today, 1))) return 'Ayer';
  return '${d.day} de ${_monthFormat.format(d)}';
}

/// Versión corta para las listas de detalle: `Hoy`, `Ayer` o `12 ago`.
String dayLabelShort(DateTime d, DateTime today) {
  if (sameDay(d, today)) return 'Hoy';
  if (sameDay(d, daysBefore(today, 1))) return 'Ayer';
  return '${d.day} ${monthAbbr(d).toLowerCase()}';
}

const List<String> _abbrs = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic', //
];

// `intl` devuelve los meses en minúscula en español; se capitaliza solo donde
// la etiqueta va suelta, y las pantallas usan .toLowerCase() en mitad de frase.
final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
final DateFormat _monthYearFormat = DateFormat('MMMM y', 'es');
final DateFormat _monthFormat = DateFormat('MMMM', 'es');

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
