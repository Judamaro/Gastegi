import 'package:flutter/material.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:go_router/go_router.dart';

/// Barra de pestañas inferior.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Las cinco entradas visibles. `branch` es el índice de la rama del shell, o
  /// nulo para "Agregar", que no es una pestaña sino una pantalla que se abre
  /// encima y oculta esta barra.
  static const _tabs = [
    (0, AppIcons.house, AppIcons.houseFill, 'Inicio'),
    (1, AppIcons.receipt, AppIcons.receiptFill, 'Historial'),
    (null, AppIcons.plusCircle, AppIcons.plusCircleFill, 'Agregar'),
    (2, AppIcons.wallet, AppIcons.walletFill, 'Cuentas'),
    (3, AppIcons.target, AppIcons.targetFill, 'Presupuesto'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          for (final (branch, icon, fillIcon, label) in _tabs)
            Expanded(
              child: _TabItem(
                icon: icon,
                fillIcon: fillIcon,
                label: label,
                active:
                    branch != null && navigationShell.currentIndex == branch,
                onTap: () => branch == null
                    ? context.push(RouteNames.addExpense)
                    // `initialLocation` en la pestaña ya activa vuelve a su
                    // raíz: tocar Inicio desde el detalle de una categoría
                    // sale del detalle, como espera cualquiera.
                    : navigationShell.goBranch(
                        branch,
                        initialLocation: branch == navigationShell.currentIndex,
                      ),
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
    final color = active ? AppColors.accent : AppColors.neutral600;
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
