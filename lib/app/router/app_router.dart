import 'package:gastegi/app/router/app_shell.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/features/accounts/presentation/pages/accounts_page.dart';
import 'package:gastegi/features/budgets/presentation/pages/budgets_page.dart';
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
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
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
                    categoryName: Uri.decodeComponent(
                      state.pathParameters['name']!,
                    ),
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
      builder: (context, state) => const AddExpensePage(),
    ),
  ],
);
