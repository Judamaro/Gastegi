import 'package:flutter/foundation.dart';
import 'package:gastegi/features/expenses/domain/entities/expense.dart';

/// Una fila del historial: la cabecera de un día o uno de sus gastos.
///
/// Los gastos llegan agrupados por día, pero una lista perezosa necesita
/// indexar por posición, no recorrer grupos anidados. Aplanar los grupos a
/// esto es lo que permite que `SliverList.builder` construya solo las filas
/// que entran en pantalla.
///
/// Guarda el día, no su etiqueta: escribir aquí "Hoy" obligaría a este archivo
/// a conocer el idioma del usuario.
@immutable
sealed class HistoryItem {
  const HistoryItem();
}

/// Cabecera de un día.
final class HistoryDay extends HistoryItem {
  const HistoryDay(this.day);

  final DateTime day;
}

/// Un gasto dentro del día que lo precede.
final class HistoryEntry extends HistoryItem {
  const HistoryEntry(this.expense);

  final Expense expense;
}
