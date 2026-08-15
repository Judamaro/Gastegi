import 'package:gastegi/core/utils/date_utils.dart';

/// Ventana temporal que muestra el historial.
///
/// Sin etiqueta: el texto es cosa de la pantalla, para que traducirlo no
/// obligue a tocar la lógica del filtro.
enum HistoryRange {
  month,
  last15,
  last7;

  /// Si [d] cae dentro del rango. [monthAnchor] es el primer día del mes en
  /// curso; los rangos por días pueden alcanzar el mes anterior a principios
  /// de mes, y por eso no basta con mirar el mes.
  bool includes(DateTime d, DateTime today, DateTime monthAnchor) =>
      switch (this) {
        month => sameMonth(d, monthAnchor),
        last15 => !d.isBefore(daysBefore(today, 14)),
        last7 => !d.isBefore(daysBefore(today, 6)),
      };
}
