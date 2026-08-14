import 'package:flutter/material.dart';
import 'package:gastegi/app/router/app_tab_bar.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/features/accounts/presentation/pages/accounts_page.dart';
import 'package:gastegi/features/budgets/presentation/pages/budgets_page.dart';
import 'package:gastegi/features/categories/presentation/pages/category_detail_page.dart';
import 'package:gastegi/features/dashboard/presentation/pages/home_page.dart';
import 'package:gastegi/features/expenses/presentation/pages/add_expense_page.dart';
import 'package:gastegi/features/expenses/presentation/pages/history_page.dart';
import 'package:gastegi/state/app_state.dart';

/// Scaffold raíz: muestra la pantalla activa según el enum del estado y la
/// barra de pestañas inferior (oculta en "Nuevo gasto").
class Shell extends StatelessWidget {
  const Shell({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final body = switch (state.screen) {
          Screen.home => HomePage(state: state),
          Screen.history => HistoryPage(state: state),
          Screen.catDetail => CategoryDetailPage(state: state),
          Screen.accounts => AccountsPage(state: state),
          Screen.budgets => BudgetsPage(state: state),
          Screen.add => AddExpensePage(state: state),
        };
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: body),
                if (state.screen != Screen.add) AppTabBar(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}
