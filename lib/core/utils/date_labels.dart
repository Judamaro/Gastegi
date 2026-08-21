import 'package:gastegi/core/utils/date_utils.dart';
import 'package:gastegi/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Fechas escritas para el usuario.
///
/// Separado de `date_utils.dart`, que es aritmética pura y no depende del
/// idioma: aquí sí, y por eso hace falta un [AppLocalizations].
class DateLabels {
  const DateLabels(this._l10n);

  final AppLocalizations _l10n;

  /// El idioma va **siempre explícito** en cada `DateFormat`.
  ///
  /// A propósito no hay un `Intl.defaultLocale` en el que apoyarse: uno fijo
  /// pinta el mes en español en un dispositivo en inglés **sin fallar nada**,
  /// y el idioma del sistema puede cambiar con la app viva.
  String get _locale => _l10n.localeName;

  /// `Agosto 2026`.
  String monthTitle(DateTime m) =>
      _l10n.monthAndYear(_capitalize(monthName(m)), m.year);

  /// `Agosto`.
  String monthName(DateTime m) =>
      _capitalize(DateFormat('MMMM', _locale).format(m));

  /// `Ago`, de tres letras.
  ///
  /// Sale del catálogo de traducciones y no de `DateFormat('MMM')` porque el
  /// CLDR español devuelve `ago.` y `sept.`, con punto y hasta cuatro letras,
  /// que desbordan las etiquetas estrechas de las gráficas.
  String monthAbbr(DateTime m) => switch (m.month) {
    1 => _l10n.monthAbbr1,
    2 => _l10n.monthAbbr2,
    3 => _l10n.monthAbbr3,
    4 => _l10n.monthAbbr4,
    5 => _l10n.monthAbbr5,
    6 => _l10n.monthAbbr6,
    7 => _l10n.monthAbbr7,
    8 => _l10n.monthAbbr8,
    9 => _l10n.monthAbbr9,
    10 => _l10n.monthAbbr10,
    11 => _l10n.monthAbbr11,
    _ => _l10n.monthAbbr12,
  };

  /// Cabecera de grupo del historial: `Hoy`, `Ayer` o `12 de agosto`.
  String dayLabel(DateTime d, DateTime today) {
    if (sameDay(d, today)) return _l10n.commonToday;
    if (sameDay(d, daysBefore(today, 1))) return _l10n.commonYesterday;
    return _l10n.dayAndMonth(d.day, monthName(d).toLowerCase());
  }

  /// Versión corta para listas de detalle: `Hoy`, `Ayer` o `12 ago`.
  String dayLabelShort(DateTime d, DateTime today) {
    if (sameDay(d, today)) return _l10n.commonToday;
    if (sameDay(d, daysBefore(today, 1))) return _l10n.commonYesterday;
    return _l10n.dayAndMonthShort(d.day, monthAbbr(d).toLowerCase());
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
