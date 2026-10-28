import 'package:flutter/material.dart';
import 'package:gastegi/app/router/app_shell.dart';
import 'package:gastegi/app/router/branch_transition.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/features/accounts/presentation/pages/accounts_page.dart';
import 'package:gastegi/features/categories/presentation/pages/budgets_page.dart';
import 'package:gastegi/features/categories/presentation/pages/category_detail_page.dart';
import 'package:gastegi/features/dashboard/presentation/pages/home_page.dart';
import 'package:gastegi/features/expenses/presentation/pages/add_expense_page.dart';
import 'package:gastegi/features/expenses/presentation/pages/history_page.dart';
import 'package:go_router/go_router.dart';

/// Navegación de la aplicación.
///
/// Cuatro ramas con estado propio para las pestañas, y "Nuevo gasto" fuera del
/// shell: es la única pantalla que oculta la barra, así que no es una pestaña
/// sino una pantalla que se abre encima.
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.home,
  routes: [
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          BranchTransition(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.home,
              builder: (context, state) => const HomePage(),
              routes: [
                // Anidado bajo Inicio, que es de donde se abre: así la pestaña
                // de Inicio se queda encendida mientras se mira el detalle.
                GoRoute(
                  path: RouteNames.categoryDetail,
                  builder: (context, state) => CategoryDetailPage(
                    categoryId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.history,
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.accounts,
              builder: (context, state) => const AccountsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RouteNames.budgets,
              builder: (context, state) => const BudgetsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.addExpense,
      // Entra desde abajo y no con la transición de la plataforma, que es la
      // de «he ido a otro sitio». Esto no es otro sitio: es una hoja que se
      // levanta sobre las pestañas y las tapa, y la dirección lo dice sin
      // necesidad de explicarlo. Sale por donde entró.
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const AddExpensePage(),
        transitionDuration: BranchTransition.duration,
        reverseTransitionDuration: BranchTransition.duration,
        transitionsBuilder: (context, animation, secondary, child) {
          // Con el ajuste de accesibilidad puesto, aparece y ya está.
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curva = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curva),
            child: FadeTransition(opacity: curva, child: child),
          );
        },
      ),
    ),
  ],
);
