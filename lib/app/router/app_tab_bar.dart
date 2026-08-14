import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/app_screen.dart';
import 'package:gastegi/app/router/nav_notifier.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_icons.dart';

/// Barra de pestañas inferior.
class AppTabBar extends ConsumerWidget {
  const AppTabBar({super.key});

  static const _tabs = [
    (Screen.home, AppIcons.house, AppIcons.houseFill, 'Inicio'),
    (Screen.history, AppIcons.receipt, AppIcons.receiptFill, 'Historial'),
    (Screen.add, AppIcons.plusCircle, AppIcons.plusCircleFill, 'Agregar'),
    (Screen.accounts, AppIcons.wallet, AppIcons.walletFill, 'Cuentas'),
    (Screen.budgets, AppIcons.target, AppIcons.targetFill, 'Presupuesto'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(navProvider);
    final nav = ref.read(navProvider.notifier);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          for (final (screen, icon, fillIcon, label) in _tabs)
            Expanded(
              child: _TabItem(
                icon: icon,
                fillIcon: fillIcon,
                label: label,
                // El detalle de categoría se abre desde Inicio, así que esa
                // pestaña se queda encendida mientras se está dentro.
                active:
                    current == screen ||
                    (screen == Screen.home && current == Screen.catDetail),
                onTap: () => nav.goTo(screen),
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
