import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/router/route_names.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/widgets/content_width.dart';
import 'package:go_router/go_router.dart';

/// Barra de pestañas inferior.
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // `branch` es el índice de la rama del shell, o nulo para "Agregar", que no
    // es una pestaña sino una pantalla que se abre encima y oculta esta barra.
    final tabs = [
      (0, AppIcons.house, AppIcons.houseFill, l10n.tabHome),
      (1, AppIcons.receipt, AppIcons.receiptFill, l10n.tabHistory),
      (null, AppIcons.plusCircle, AppIcons.plusCircleFill, l10n.tabAdd),
      (2, AppIcons.wallet, AppIcons.walletFill, l10n.tabAccounts),
      (3, AppIcons.target, AppIcons.targetFill, l10n.tabBudgets),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(8.r, 6.r, 8.r, 8.r),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      // El tope va por dentro, rodeando solo las pestañas: envolver el
      // `Container` entero cortaría el fondo y la línea superior a los 600 dp
      // y dejaría dos franjas sin borde a los lados en una tableta.
      child: ContentWidth(
        child: Row(
          children: [
            for (final (branch, icon, fillIcon, label) in tabs)
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
                          initialLocation:
                              branch == navigationShell.currentIndex,
                        ),
                ),
              ),
          ],
        ),
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
        padding: EdgeInsets.symmetric(vertical: 6.r),
        child: Column(
          spacing: 2.r,
          children: [
            Icon(active ? fillIcon : icon, size: 21.r, color: color),
            // Encoge en vez de truncarse: con cinco pestañas repartiéndose el
            // ancho y el tamaño de letra del sistema al máximo, «Presupuesto»
            // no cabe de ninguna manera, y media palabra en una barra de
            // navegación se lee peor que una palabra pequeña.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(fontSize: AppFontSize.tab, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
