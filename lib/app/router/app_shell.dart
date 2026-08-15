import 'package:flutter/material.dart';
import 'package:gastegi/app/router/app_tab_bar.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/core/widgets/content_width.dart';
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
    // Con el teclado del sistema abierto, el `Scaffold` encoge el cuerpo por
    // arriba del teclado. Si la barra de pestañas se quedara, se comería la
    // franja que le queda al formulario —y con ella el botón de guardar— para
    // ofrecer una navegación que nadie va a usar mientras escribe.
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ContentWidth(child: navigationShell)),
            if (!tecladoAbierto) AppTabBar(navigationShell: navigationShell),
          ],
        ),
      ),
    );
  }
}
