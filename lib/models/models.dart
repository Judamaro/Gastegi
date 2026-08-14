import 'package:flutter/widgets.dart';

import 'package:gastegi/theme/phosphor_icons.dart';

/// Modelos de dominio. Los ids son UUID de texto, no enteros autoincrementales:
/// cuando la app sincronice con la nube, dos teléfonos generarían el mismo
/// `id = 1` para filas distintas y habría que remapear todas las claves ajenas.

/// Categoría de gasto con su color, icono y presupuesto mensual.
class Category {

  factory Category.fromRow(Map<String, Object?> r) => Category(
        id: r['id'] as String,
        name: r['name'] as String,
        color: Color(r['color'] as int),
        icon: PhIcons.resolve(r['icon_key'] as String),
        budget: (r['budget'] as num).toDouble(),
      );
  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.budget,
  });

  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final double budget;
}

/// Cuenta de dinero.
///
/// [balance] es un valor **derivado** (saldo inicial menos gastos, más y menos
/// transferencias): nadie lo muta desde Dart, lo recalcula la BD. Ver
/// `AccountRepository.recomputeBalances`.
class Account {

  factory Account.fromRow(Map<String, Object?> r) => Account(
        id: r['id'] as String,
        name: r['name'] as String,
        kind: r['kind'] as String,
        icon: PhIcons.resolve(r['icon_key'] as String),
        balance: (r['balance'] as num).toDouble(),
        initialBalance: (r['initial_balance'] as num).toDouble(),
        archived: (r['archived'] as int) == 1,
      );
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.balance,
    required this.initialBalance,
    required this.archived,
  });

  final String id;
  final String name;
  final String kind;
  final IconData icon;
  final double balance;
  final double initialBalance;
  final bool archived;
}

/// Gasto individual. [cat] y [acct] son los nombres resueltos por el JOIN de la
/// consulta, para que las pantallas sigan mostrando texto sin más búsquedas.
class Expense {

  factory Expense.fromRow(Map<String, Object?> r) => Expense(
        id: r['id'] as String,
        date: DateTime.parse(r['spent_on'] as String),
        desc: r['description'] as String,
        categoryId: r['category_id'] as String,
        cat: r['category_name'] as String,
        accountId: r['account_id'] as String?,
        acct: (r['account_name'] as String?) ?? 'Sin cuenta',
        val: (r['amount'] as num).toDouble(),
      );
  const Expense({
    required this.id,
    required this.date,
    required this.desc,
    required this.categoryId,
    required this.cat,
    required this.accountId,
    required this.acct,
    required this.val,
  });

  final String id;

  /// Medianoche local del día del gasto.
  final DateTime date;
  final String desc;
  final String categoryId;
  final String cat;
  final String? accountId;

  /// Nombre de la cuenta, o `Sin cuenta` si el gasto no tiene ninguna.
  final String acct;
  final double val;

  /// Día del mes; lo usan los cortes semanales del detalle de categoría.
  int get day => date.day;
}
