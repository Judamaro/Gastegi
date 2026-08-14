import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/app_screen.dart';
import 'package:gastegi/app/router/app_tab_bar.dart';
import 'package:gastegi/app/router/nav_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/features/accounts/presentation/pages/accounts_page.dart';
import 'package:gastegi/features/budgets/presentation/pages/budgets_page.dart';
import 'package:gastegi/features/categories/presentation/pages/category_detail_page.dart';
import 'package:gastegi/features/dashboard/presentation/pages/home_page.dart';
import 'package:gastegi/features/expenses/presentation/pages/add_expense_page.dart';
import 'package:gastegi/features/expenses/presentation/pages/history_page.dart';

/// Scaffold raíz: muestra la pantalla activa y la barra de pestañas inferior
/// (oculta en "Nuevo gasto").
class Shell extends ConsumerWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(navProvider);
    final body = switch (screen) {
      Screen.home => const HomePage(),
      Screen.history => const HistoryPage(),
      Screen.catDetail => const CategoryDetailPage(),
      Screen.accounts => const AccountsPage(),
      Screen.budgets => const BudgetsPage(),
      Screen.add => const AddExpensePage(),
    };
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            if (screen != Screen.add) const AppTabBar(),
          ],
        ),
      ),
    );
  }
}
