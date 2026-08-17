import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/money_input_formatter.dart';
import 'package:gastegi/features/expenses/presentation/providers/add_expense_notifier.dart';

/// La cifra grande de «Nuevo gasto», que además es donde se teclea.
///
/// No reutiliza `MoneyInput` —ese es un campo de formulario, con borde, fondo y
/// cuerpo de texto base— pero sí sus dos piezas: [MoneyInputFormatter] y
/// `MoneyLabels`. Así las reglas de entrada (un solo separador decimal, el tope
/// de enteros y el de decimales) son las mismas que en el saldo de una cuenta y
/// en una transferencia, escritas una sola vez.
class AmountField extends ConsumerStatefulWidget {
  const AmountField({super.key, required this.maxWidth});

  /// Ancho disponible, en dp ya medidos.
  ///
  /// Viaja como parámetro en vez de medirse aquí con un `LayoutBuilder` porque
  /// este widget cuelga del `IntrinsicHeight` que pega el botón de guardar al
  /// fondo, y un `LayoutBuilder` lanza en cuanto le preguntan una dimensión
  /// intrínseca.
  final double maxWidth;

  @override
  ConsumerState<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends ConsumerState<AmountField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final money = context.money;
    final amount = ref.watch(addExpenseProvider.select((s) => s.amount));

    // El estado puede cambiar el importe sin pasar por el campo: `save()` deja
    // el formulario vacío y el controlador no se entera solo —al volver a la
    // pantalla seguiría escrita la cifra del gasto anterior—. La guarda es lo
    // que corta el bucle: mientras se teclea, el estado ya viene de este mismo
    // texto y aquí no queda nada que hacer.
    ref.listen(addExpenseProvider.select((s) => s.amount), (_, next) {
      if (money.canonical(_controller.text) == next) return;
      final text = money.typedNumber(next);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });

    // Las medidas salen del estado y no de `_controller.text`: así no dependen
    // del orden entre el aviso de arriba y el repintado del campo.
    final zero = money.typedNumber('0');
    final typed = money.typedNumber(amount);
    // Con el campo vacío se mide el cero de la pista, que es lo que se ve.
    final shown = typed.isEmpty ? zero : typed;
    final color = amount.isEmpty ? AppColors.neutral700 : AppColors.text;

    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final symbols = '${money.symbolPrefix}${money.symbolSuffix}';
    final size = _fittedSize(
      '${money.symbolPrefix}$shown${money.symbolSuffix}',
      widget.maxWidth - _caret,
      scaler,
      direction,
    );

    // Lo que mide la cifra, pero sin pasar del hueco que dejan los símbolos.
    //
    // El tope hace falta porque el cuerpo tiene suelo: en el peor caso del
    // catálogo —un móvil de 320 dp con el texto al 1.3× y la cifra más larga—
    // la medición se queda en el suelo y el texto sigue sin caber. Sin acotar,
    // el `Row` desborda con las rayas amarillas; acotado, el campo se desplaza
    // por dentro, que es lo que hace cualquier campo de texto.
    final width = math.min(
      _widthOf(shown, size, scaler, direction) + _caret,
      widget.maxWidth - _widthOf(symbols, size, scaler, direction),
    );

    return GestureDetector(
      // Con la cifra corta el campo mide poco más que un dígito: el toque se
      // recoge en toda la franja del visor y no solo encima de la cifra.
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // El símbolo va en un `Text` al lado y no en el `prefixText` del
          // campo por dos razones: el `InputDecorator` reparte el ancho
          // sobrante al editable, y con la cifra centrada el símbolo quedaría
          // despegado en el borde; y solo lo pinta cuando el campo tiene foco o
          // contenido, así que parpadearía al vaciar la cifra.
          if (money.symbolPrefix.isNotEmpty)
            Text(
              money.symbolPrefix,
              style: AppTextStyles.heroInput(size, color: color),
            ),
          SizedBox(
            width: width,
            child: TextField(
              key: amountFieldKey,
              controller: _controller,
              focusNode: _focus,
              // El teclado sube al abrir la pantalla: teclear el importe es lo
              // primero y lo único obligatorio que se hace aquí.
              autofocus: true,
              textAlign: TextAlign.center,
              cursorColor: AppColors.accent,
              style: AppTextStyles.heroInput(size, color: AppColors.text),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [MoneyInputFormatter(money)],
              decoration: InputDecoration(
                // Es un visor, no un campo de formulario: sin borde, sin
                // relleno y sin el hueco vertical que `InputDecorator` reserva
                // para el rótulo.
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: zero,
                hintStyle: AppTextStyles.heroInput(
                  size,
                  color: AppColors.neutral700,
                ),
              ),
              onChanged: (value) => ref
                  .read(addExpenseProvider.notifier)
                  .setAmount(money.canonical(value)),
            ),
          ),
          if (money.symbolSuffix.isNotEmpty)
            Text(
              money.symbolSuffix,
              style: AppTextStyles.heroInput(size, color: color),
            ),
        ],
      ),
    );
  }
}

/// Para encontrar el campo en los tests sin depender de lo que hay escrito.
const Key amountFieldKey = ValueKey('expense-amount');

/// Hueco para el cursor: el campo mide justo lo que la cifra, y sin este margen
/// el cursor del final se pinta medio fuera del recorte.
double get _caret => 3.r;

double _widthOf(
  String text,
  double size,
  TextScaler scaler,
  TextDirection direction,
) => (TextPainter(
  // El mismo estilo con el que se pinta: el alto de línea no cambia el ancho,
  // pero medir con otro invita a que se separen.
  text: TextSpan(text: text, style: AppTextStyles.heroInput(size)),
  textDirection: direction,
  textScaler: scaler,
  maxLines: 1,
)..layout()).width;

/// Cuerpo con el que [text] cabe en [maxWidth], sin pasar de
/// [AppFontSize.displayXl].
///
/// Sustituye al `FittedBox` que envolvía el visor cuando era un `Text`: un
/// campo de texto dentro de un `FittedBox` hereda la escala en el cursor y en
/// el área de toque, y además necesita un ancho acotado que el `FittedBox` no
/// da. Midiendo, lo que se pinta ya cabe a escala 1.
///
/// El suelo es [AppFontSize.title] porque por debajo del cuerpo de un título la
/// cifra deja de ser un visor. En la práctica no se alcanza: el peor caso del
/// catálogo —320 dp con el texto al 1.3×— se queda muy por encima.
double _fittedSize(
  String text,
  double maxWidth,
  TextScaler scaler,
  TextDirection direction,
) {
  var size = AppFontSize.displayXl;
  // Dos pasadas: el ancho crece proporcional al cuerpo —el interletrado de
  // `hero` es el −2 % de él, también proporcional—, así que la primera acierta
  // y la segunda solo absorbe el redondeo de la tipografía.
  for (var i = 0; i < 2; i++) {
    final width = _widthOf(text, size, scaler, direction);
    if (width <= maxWidth) break;
    size = math.max(AppFontSize.title, size * maxWidth / width);
  }
  return size;
}
