import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';

import '../state/app_state.dart';
import '../theme/nocturne.dart';
import '../widgets/common.dart';

/// Nuevo gasto: monto con teclado propio, categoría, cuenta y descripción.
class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, required this.state});

  final AppState state;

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
    final hasAmount = state.addAmountValue > 0;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nuevo gasto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      NIconButton(
                        icon: PhIcons.x,
                        onTap: () => state.goTo(Screen.home),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      state.addAmount.isEmpty ? '0' : state.addAmount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.88,
                        height: 1,
                        color: hasAmount ? Nocturne.text : Nocturne.neutral700,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      const FieldLabel('Categoría'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in state.categories)
                            NChip(
                              label: c.name,
                              icon: c.icon,
                              color: c.color,
                              active: state.addCat == c.name,
                              onTap: () => state.pickAddCat(c.name),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      const FieldLabel('Cuenta'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final a in state.accounts)
                            NChip(
                              label: a.name,
                              active: state.addAcct == a.name,
                              onTap: () => state.pickAddAcct(a.name),
                            ),
                        ],
                      ),
                    ],
                  ),
                  NInput(
                    hint: 'Descripción (opcional)',
                    onChanged: state.setAddDesc,
                  ),
                  const Spacer(),
                  Column(
                    spacing: 8,
                    children: [
                      for (var row = 0; row < 4; row++)
                        Row(
                          spacing: 8,
                          children: [
                            for (final key in _keys.sublist(row * 3, row * 3 + 3))
                              Expanded(
                                child: InkWell(
                                  onTap: () => state.keypadTap(key),
                                  borderRadius: BorderRadius.circular(
                                    Nocturne.radiusMd,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Nocturne.surface,
                                      border: Border.all(
                                        color: Nocturne.divider,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Nocturne.radiusMd,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      key,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  PrimaryButton(
                    label: 'Guardar gasto',
                    disabled: state.saveDisabled,
                    onTap: state.saveExpense,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
