import 'package:flutter/widgets.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/entity_visuals.dart';
import 'package:gastegi/features/categories/domain/entities/category.dart';

/// Fila derivada de la pantalla de presupuestos: cuánto lleva gastado una
/// categoría respecto de lo que tenía asignado.
class BudgetRow {
  const BudgetRow({
    required this.category,
    required this.spent,
    required this.ratio,
    required this.alert,
    required this.over,
  });

  final Category category;
  final double spent;

  /// Gastado sobre presupuestado. 0 si la categoría no tiene presupuesto.
  final double ratio;

  /// Se ha superado el umbral de aviso.
  final bool alert;

  /// Se ha pasado del presupuesto.
  final bool over;

  Color get barColor => over
      ? AppColors.accent300
      : alert
      ? AppColors.accent
      : category.color;
}
