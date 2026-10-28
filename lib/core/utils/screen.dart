import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Umbral de tableta, en dp reales.
///
/// **No se escala.** Es un punto de ruptura del dispositivo, no una medida del
/// diseño: escalarlo lo movería justo en las pantallas donde decide algo.
const double kTabletBreakpoint = 600;

/// Suscribe este `build` a los cambios de tamaño de pantalla.
///
/// Llámalo en la **primera línea del `build` de cada pantalla**. No devuelve
/// nada: se llama por el efecto, no por el valor.
///
/// Por qué: `.r` y `.sp` se resuelven durante `build` y quedan congelados
/// dentro del widget, y al girar el dispositivo nadie reconstruye las páginas.
/// `StatefulNavigationShellState` guarda el `Navigator` de cada rama y solo lo
/// rehace si cambia la ruta, así que un cambio de métricas cortocircuita el
/// subárbol entero por widget idéntico: **la pantalla se queda con la escala
/// del retrato sin fallar nada**. Lo vigila el test de rotación.
///
/// La dependencia se declara contra el ámbito del paquete y no contra
/// `MediaQuery` porque ese ámbito se reconstruye *después* de recalcular la
/// escala, así que el `build` lee ya los valores nuevos y no los del giro
/// anterior. Cualquiera de las dos basta para que la pantalla se reconstruya
/// —comprobado quitándolas por separado, y el test de rotación solo cae con
/// las dos fuera—, pero solo esta garantiza *qué* se lee al reconstruir.
void watchScreen(BuildContext context) => ScreenUtilPlus.of(context);
