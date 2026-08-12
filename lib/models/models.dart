import 'package:flutter/widgets.dart';

/// Categoría de gasto con su color, icono y presupuesto mensual.
class Category {
  const Category(this.name, this.color, this.icon, this.budget);

  final String name;
  final Color color;
  final IconData icon;
  final double budget;
}

/// Cuenta de dinero; el saldo es mutable (transferencias y gastos).
class Account {
  Account(this.name, this.kind, this.icon, this.balance);

  final String name;
  final String kind;
  final IconData icon;
  double balance;
}

/// Gasto individual dentro del mes en curso (julio).
class Expense {
  const Expense(this.day, this.desc, this.cat, this.acct, this.val);

  final int day;
  final String desc;
  final String cat;
  final String acct;
  final double val;
}
