import 'package:flutter/material.dart';
import 'package:gastegi/app/router/app_tab_bar.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

/// Scaffold de las pantallas con pestañas.
///
/// `StatefulShellRoute` mantiene vivo el estado de cada rama, así que volver a
/// una pestaña la deja como estaba: el desplazamiento del historial, el
/// formulario de cuenta a medio rellenar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: navigationShell),
            AppTabBar(navigationShell: navigationShell),
          ],
        ),
      ),
    );
  }
}
