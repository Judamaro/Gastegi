import 'package:flutter/material.dart';
import 'package:gastegi/app/theme/app_colors.dart';
import 'package:gastegi/app/theme/app_spacing.dart';

/// Teclado numérico del nuevo gasto.
///
/// La app tiene su propio teclado en vez de un campo de texto: así el importe
/// se teclea sin que suba el teclado del sistema y tape la pantalla, y las
/// reglas de entrada (una sola coma, máximo 7 dígitos) las decide el estado y
/// no el sistema operativo.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});

  /// Recibe el dígito, la coma decimal o `⌫`.
  final ValueChanged<String> onKey;

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    ',',
    '0',
    '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        for (var row = 0; row < 4; row++)
          Row(
            spacing: 8,
            children: [
              for (final key in _keys.sublist(row * 3, row * 3 + 3))
                Expanded(
                  child: _Key(label: key, onTap: () => onKey(key)),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
