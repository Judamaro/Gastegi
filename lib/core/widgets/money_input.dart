import 'package:flutter/material.dart';
import 'package:gastegi/core/utils/l10n_context.dart';
import 'package:gastegi/core/utils/money_input_formatter.dart';
import 'package:gastegi/core/widgets/app_input.dart';

/// Campo para teclear un importe, formateado mientras se escribe.
///
/// Habla en **canónico** con quien lo usa —lo que recibe en [initialValue] y lo
/// que devuelve en [onChanged]—, no en lo que se ve. Así el estado sigue
/// guardando texto sin idioma y esta traducción vive en un solo sitio.
class MoneyInput extends StatelessWidget {
  const MoneyInput({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue,
    this.allowNegative = false,
  });

  final String hint;

  /// Recibe el importe canónico, no el texto del campo.
  final ValueChanged<String> onChanged;

  /// Importe canónico de partida. Como [AppInput] no lleva controlador propio,
  /// solo se lee al crear el campo: para repoblarlo hay que cambiar la `key`.
  final String? initialValue;

  /// Los saldos de una tarjeta de crédito son negativos; un gasto, nunca.
  final bool allowNegative;

  @override
  Widget build(BuildContext context) {
    final money = context.money;
    return AppInput(
      hint: hint,
      initialValue: initialValue == null
          ? null
          : money.typedNumber(initialValue!),
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: allowNegative,
      ),
      inputFormatters: [
        MoneyInputFormatter(money, allowNegative: allowNegative),
      ],
      prefixText: money.symbolPrefix.isEmpty ? null : money.symbolPrefix,
      suffixText: money.symbolSuffix.isEmpty ? null : money.symbolSuffix,
      onChanged: (value) =>
          onChanged(money.canonical(value, allowNegative: allowNegative)),
    );
  }
}
