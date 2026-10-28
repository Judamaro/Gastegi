import 'package:flutter/widgets.dart';
import 'package:gastegi/core/utils/screen.dart';

/// Limita el ancho del contenido y lo centra.
///
/// En una tableta, una columna de 700 dp no se lee: la vista salta de un
/// extremo al otro de cada línea. El diseño está pensado para el ancho de un
/// teléfono, así que se conserva y se centra en vez de estirarlo.
///
/// El tope va en dp reales y **sin `.r`**, por lo mismo que
/// [kTabletBreakpoint]: es un límite de legibilidad, no una medida del diseño,
/// y escalarlo lo movería justo en las pantallas donde decide algo.
///
/// `Align` y no `Center` para que el contenido siga pegado arriba y ocupe todo
/// el alto disponible: centrado en vertical, las pantallas cortas quedarían
/// flotando en mitad de la nada.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kTabletBreakpoint,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
