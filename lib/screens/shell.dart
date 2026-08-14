import 'package:flutter/material.dart';
import 'package:gastegi/screens/accounts_screen.dart';
import 'package:gastegi/screens/add_expense_screen.dart';
import 'package:gastegi/screens/budgets_screen.dart';
import 'package:gastegi/screens/category_detail_screen.dart';
import 'package:gastegi/screens/history_screen.dart';
import 'package:gastegi/screens/home_screen.dart';
import 'package:gastegi/state/app_state.dart';
import 'package:gastegi/theme/nocturne.dart';
import 'package:gastegi/theme/phosphor_icons.dart';

/// Scaffold raíz: muestra la pantalla activa según el enum del estado y la
/// barra de pestañas inferior (oculta en "Nuevo gasto").
class Shell extends StatelessWidget {
  const Shell({super.key, required this.state});

  final AppState state;

  static const _tabs = [
    (Screen.home, PhIcons.house, PhIcons.houseFill, 'Inicio'),
    (Screen.history, PhIcons.receipt, PhIcons.receiptFill, 'Historial'),
    (Screen.add, PhIcons.plusCircle, PhIcons.plusCircleFill, 'Agregar'),
    (Screen.accounts, PhIcons.wallet, PhIcons.walletFill, 'Cuentas'),
    (Screen.budgets, PhIcons.target, PhIcons.targetFill, 'Presupuesto'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final body = switch (state.screen) {
          Screen.home => HomeScreen(state: state),
          Screen.history => HistoryScreen(state: state),
          Screen.catDetail => CategoryDetailScreen(state: state),
          Screen.accounts => AccountsScreen(state: state),
          Screen.budgets => BudgetsScreen(state: state),
          Screen.add => AddExpenseScreen(state: state),
        };
        return Scaffold(
          backgroundColor: Nocturne.bg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: body),
                if (state.screen != Screen.add) _TabBar(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(
        color: Nocturne.bg,
        border: Border(top: BorderSide(color: Nocturne.divider)),
      ),
      child: Row(
        children: [
          for (final (screen, icon, fillIcon, label) in Shell._tabs)
            Expanded(
              child: _TabItem(
                icon: icon,
                fillIcon: fillIcon,
                label: label,
                active: state.screen == screen ||
                    (screen == Screen.home && state.screen == Screen.catDetail),
                onTap: () => state.goTo(screen),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.fillIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData fillIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Nocturne.accent : Nocturne.neutral600;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          spacing: 2,
          children: [
            Icon(active ? fillIcon : icon, size: 21, color: color),
            Text(label, style: TextStyle(fontSize: 9.5, color: color)),
          ],
        ),
      ),
    );
  }
}
