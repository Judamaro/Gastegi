import 'package:flutter/widgets.dart';

/// Ancho que ocupa [text] pintado en una línea con [style].
///
/// [style] tiene que ser **el que acaba pintando el widget, con su familia
/// tipográfica dentro**, no uno suelto. Los estilos de la app se escriben sin
/// familia —la pone el tema y el widget la hereda—, así que medir con uno a
/// secas mide con la del sistema: en Android es Roboto, más estrecha que Inter,
/// y la medida se queda corta sin que nada falle. `DefaultTextStyle.of(context)
/// .style.merge(elTuyo)` da el bueno.
///
/// [scaler] es el ajuste de tamaño de letra del sistema, normalmente
/// `MediaQuery.textScalerOf(context)`: sin él la medida ignora la accesibilidad
/// y se queda corta justo en los dispositivos donde el texto es más grande.
double textWidth(
  String text, {
  required TextStyle style,
  required TextScaler scaler,
  required TextDirection direction,
}) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: direction,
  textScaler: scaler,
  maxLines: 1,
)..layout()).width;

/// Alto que ocupa [text] pintado en una línea con [style].
///
/// Mismas advertencias que en [textWidth]: [style] tiene que llevar la familia
/// tipográfica dentro y [scaler] tiene que ser el del contexto.
///
/// Existe porque `SideTitles.reservedSize` de `fl_chart` fuerza el alto del
/// hijo con un `tightFor`: si el texto escalado mide más, se recorta **sin
/// lanzar nada**, así que la matriz de `responsive_test.dart` saldría verde con
/// la etiqueta comida.
double textHeight(
  String text, {
  required TextStyle style,
  required TextScaler scaler,
  required TextDirection direction,
}) => (TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: direction,
  textScaler: scaler,
  maxLines: 1,
)..layout()).height;
