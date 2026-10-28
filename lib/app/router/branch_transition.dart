import 'package:flutter/widgets.dart';

/// Contenedor de las ramas del shell, con transición al cambiar de pestaña.
///
/// Sustituye al `IndexedStack` que monta `StatefulShellRoute.indexedStack`,
/// que cambia de rama de golpe. Conserva sus dos garantías —las ramas siguen
/// vivas, y solo la activa consume tiempo de animación— y añade una tercera:
/// **una rama que no se está usando vuelve a `Offstage` en cuanto termina la
/// transición**.
///
/// Esa tercera no es cosmética. `Offstage` es lo que hace que los buscadores de
/// `flutter_test` no vean las pestañas inactivas (`skipOffstage` viene a `true`
/// por defecto), y en esta app hay textos que salen en dos pestañas a la vez
/// —el nombre de una categoría está en la leyenda de la dona de Inicio y en su
/// tarjeta de Presupuesto—. Dejarlas visibles siempre, como hace el ejemplo
/// oficial de `go_router`, convierte un `find.text` en ambiguo sin que el
/// cambio tenga nada que ver con lo que se está probando.
class BranchTransition extends StatefulWidget {
  const BranchTransition({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  /// Cuánto dura el cruce. Del mismo orden que las gráficas (220 ms), para que
  /// la app se mueva toda al mismo ritmo.
  static const Duration duration = Duration(milliseconds: 200);

  /// De dónde entra la pestaña nueva. Un empujón corto: es un cambio entre
  /// iguales, no una jerarquía, así que no se desliza de lado.
  static const double _scaleFrom = 0.97;

  final int currentIndex;
  final List<Widget> children;

  @override
  State<BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<BranchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BranchTransition.duration,
    value: 1,
  );

  /// La pestaña que se está yendo, o `null` cuando no hay transición en curso.
  /// Es lo único que mantiene una rama inactiva fuera de `Offstage`.
  int? _saliente;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((estado) {
      if (estado == AnimationStatus.completed && _saliente != null) {
        setState(() => _saliente = null);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BranchTransition old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;

    // Con el ajuste de accesibilidad puesto, el cambio es instantáneo: nada de
    // recorrer la animación a toda prisa, que es peor que no tenerla.
    if (MediaQuery.disableAnimationsOf(context)) {
      _saliente = null;
      _controller.value = 1;
      return;
    }
    _saliente = old.currentIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cruce lineal y solapado, no un relevo. Encadenar la salida con la
    // entrada —lo que hace el «fade through» de Material— deja el cuerpo casi
    // vacío a mitad de camino: medido fotograma a fotograma, el brillo medio
    // caía de 47 a 28 sobre un fondo que ya vale 25, o sea unos 40 ms de
    // pantalla en blanco. Cruzándolas, las dos —tarjetas oscuras sobre el
    // mismo fondo— se compensan y el brillo se queda plano entre 45 y 55.
    final entra = _controller.view;
    final sale = Tween<double>(begin: 1, end: 0).animate(_controller);

    return Stack(
      children: [
        for (final (i, child) in widget.children.indexed)
          _rama(i, child, entra, sale),
      ],
    );
  }

  Widget _rama(
    int i,
    Widget child,
    Animation<double> entra,
    Animation<double> sale,
  ) {
    final activa = i == widget.currentIndex;
    // Solo la activa y la que se está yendo siguen dibujándose.
    final visible = activa || i == _saliente;

    return Offstage(
      offstage: !visible,
      child: IgnorePointer(
        ignoring: !activa,
        // Sin esto, la pestaña que se va sigue animando sus gráficas mientras
        // se desvanece, y las tres ocultas nunca dejan de hacerlo.
        child: TickerMode(
          enabled: activa,
          child: activa
              ? FadeTransition(
                  opacity: entra,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: BranchTransition._scaleFrom,
                      end: 1,
                    ).animate(entra),
                    child: child,
                  ),
                )
              : FadeTransition(opacity: sale, child: child),
        ),
      ),
    );
  }
}
