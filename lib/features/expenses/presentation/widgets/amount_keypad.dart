import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';
import 'package:gastegi/app/theme/app_typography.dart';
import 'package:gastegi/core/utils/formatters.dart';
import 'package:gastegi/core/utils/l10n_context.dart';

/// Teclado numérico del nuevo gasto.
///
/// La app tiene su propio teclado en vez de un campo de texto: así el importe
/// se teclea sin que suba el teclado del sistema y tape la pantalla, y las
/// reglas de entrada (un solo separador decimal, siete enteros y dos
/// decimales) las decide el estado y no el sistema operativo.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});

  /// Recibe el **token**: un dígito, [canonicalDecimalPoint] o [backspaceKey].
  ///
  /// La coma que se ve en español es solo la etiqueta. El estado no puede
  /// depender del idioma porque el notifier no tiene contexto con el que
  /// resolverlo, así que la traducción se queda aquí.
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final keys = <(String label, String token)>[
      for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        (digit, digit),
      (context.money.decimalSeparator, canonicalDecimalPoint),
      ('0', '0'),
      (backspaceKey, backspaceKey),
    ];

    return Column(
      spacing: 8.r,
      children: [
        for (var row = 0; row < 4; row++)
          Row(
            spacing: 8.r,
            children: [
              for (final (label, token) in keys.sublist(row * 3, row * 3 + 3))
                Expanded(
                  child: _Key(label: label, onTap: () => onKey(token)),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: AppFontSize.title)),
      ),
    );
  }
}
